""""
"" local functions
""""

"{{{
function s:format(method, params, id=-1)
	let l:req = {}
	let l:req["jsonrpc"] = "2.0"
	let l:req["method"] = a:method
	let l:req["params"] = a:params

	if a:id != -1
		let l:req["id"] = a:id
	endif

	return l:req
endfunction
"}}}

"{{{
function s:send(job, data)
	let l:data_j = json_encode(a:data)
	call ch_sendraw(a:job, "Content-Length: " . len(l:data_j) . "\r\n\r\n" . l:data_j)
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#lsp#base#rx_hdlr(channel, msg)
	let l:server = becomplete#lsp#server#get(ch_getjob(a:channel))
	let l:server["data"] .= a:msg

	while len(l:server["data"])
		" try to split data into header and content
		" considering
		" 	- data containing an incomplete message
		" 	- data containing a complete, followed by an incomplete message
		let l:parts = split(l:server["data"], "\r\n\r\n")
		let l:hdr = len(l:parts) > 0 ? l:parts[0] : "incomplete:-1"
		let l:content_len = str2nr(split(l:hdr, ":")[1])
		let l:content = len(l:parts) > 1 ? l:parts[1][:l:content_len - 1] : ""

		" handle complete messages and return if only an incomplete remains
		if len(l:content) != l:content_len
			break
		endif

		let l:server["data"] = l:server["data"][len(l:parts[0]) + 4 + l:content_len:]
		let l:content = json_decode(l:content)

		try
			let l:id = l:content["id"]
			let l:request = l:server["requests"][l:id]
			unlet l:server["requests"][l:id]
			
			let l:result = l:content["result"]

			call l:request["hdlr"](l:server, l:result)

		catch /^Vim(let):E716.*\"id\"/
			call becomplete#debug#print("drop server message: " . string(l:content))

		catch /^Vim(let):E716.*\"result\"/
			call becomplete#debug#error("request \"" . l:request["method"] . "\": " . l:content["error"]["message"])

		catch /^Vim(let):E716.*\"\d\+\"/
			call becomplete#debug#error("missing request data for id " . l:id)

		endtry
	endwhile
endfunction
"}}}

"{{{
function becomplete#lsp#base#request(server, method, params, hdlr)
	if job_status(a:server["job"]) != "run" || (a:server["initialised"] != 1 && a:method != "initialize")
		call becomplete#debug#error("request \"" . a:method . "\": server not initialised")
		return {}
	endif

	let l:req = s:format(a:method, a:params, a:server["request-id"])
	let a:server["requests"][a:server["request-id"]] = { "method": a:method, "hdlr": a:hdlr }
	let a:server["request-id"] += 1

	call s:send(a:server["job"], l:req)
endfunction
"}}}

"{{{
function becomplete#lsp#base#notification(server, method, params)
	if a:server["initialised"] != 1 && a:method != "initialized"
		call becomplete#debug#error("notification \"" . a:method . "\": server not initialised")
		return
	endif

	call s:send(a:server["job"], s:format(a:method, a:params))
endfunction
"}}}
