""""
"" local variables
""""

"{{{
" mapping between lsp notifications and callback functions
let s:notification_hdlrs = {
\	"textDocument/publishDiagnostics": "s:diag_hdlr",
\	"default": "s:default_notification_hdlr",
\ }
"}}}


""""
"" local functions
""""

"{{{
" \brief	create an lsp message
"
" \param	method	lsp method, e.g. textDocument/completion
" \param	params	a:method parameters
" \param	id		lsp message id
"
" \return	dictionary containing the resulting lsp message
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
" \brief	send the given lsp message to the language server associated with
"			job, adding an lsp message header
"
" \param	job		vim job handle connected to the target language server
" \param	data	lsp message dictionary, cf. s:format()
function s:send(job, data)
	let l:data_j = json_encode(a:data)
	call ch_sendraw(a:job, "Content-Length: " . len(l:data_j) . "\r\n\r\n" . l:data_j)
endfunction
"}}}

"{{{
" \brief	timed-out wait for the given request's response
"
" \param	request		request object to listen on
" \param	timeout_ms	milliseconds to wait upon signaling a timeout
"
" \return	Dictionary containing the lsp result. In case of a timeout an
"			empty dictionary is returned.
function s:await_response(request, timeout_ms)
	let l:max_retries = a:timeout_ms / 10
	let l:retry = 0

	while !has_key(a:request, "result")
		if l:retry >= l:max_retries
			call becomplete#log#msg("timeout on request " . a:request["method"])
			return {}
		endif

		sleep 10m
		let l:retry += 1
	endwhile

	return a:request["result"]
endfunction
"}}}

"{{{
" \brief	lsp notification handler for notifications that do not have an
"			entry in s:notification_hdlrs. The handler indicates that a
"			notification was dropped.
"
" \param	server		lsp server object
" \param	content		dictionary with the notification
function s:default_notification_hdlr(server, content)
	call becomplete#log#msg("drop server message: " . string(a:content))
endfunction
"}}}

"{{{
" \brief	lsp notification handler for diagnostics. The handler logs the
"			messages to the plugin log also indicating unknown formats.
"
" \param	server		lsp server object
" \param	content		dictionary with the notification
function s:diag_hdlr(server, content)
	try
		let l:file = becomplete#lsp#response#uri(a:content["params"])

		for l:diag in a:content["params"]["diagnostics"]
			let [l:line, l:col, _, _] = becomplete#lsp#response#range(l:diag)
			let l:msg = l:diag["message"]

			call becomplete#log#msg(
			\	"diagnostic message: " . l:file . ":"
			\	. l:line . ":" . l:col
			\	. " " . l:msg
			\ )
		endfor

	catch
		call becomplete#log#msg("unknown diag message format: " . string(a:content))
	endtry
endfunction
"}}}

"{{{
" \brief	wrapper to call a notification handler based on
"			s:notification_hdlrs and the lsp method contained in a:content
"
" \param	server		lsp server object
" \param	content		dictionary with the lsp response
function s:handle_notification(server, content)
	let l:method = get(a:content, "method", "default")

	if !has_key(s:notification_hdlrs, l:method)
		let l:method = "default"
	endif

	call function(s:notification_hdlrs[l:method])(a:server, a:content)
endfunction
"}}}

"{{{
" \brief	wrapper to parse an lsp message, responses as well as
"			notifications, calling the respective handler functions or
"			indicating an error
"
" \param	server		lsp server object
" \param	content		dictionary with the lsp message
function s:handle_message(server, content)
	try
		let l:id = a:content["id"]
		let l:request = a:server["requests"][l:id]
		let l:result = a:content["result"]

		call becomplete#log#msg("response for " . l:request["method"] . ": " . string(l:result))
		let l:request["result"] = l:result

	catch /^Vim(let):E716.*: .*id.*/
		call s:handle_notification(a:server, a:content)

	catch /^Vim(let):E716.*: .*result.*/
		call becomplete#log#error("request \"" . l:request["method"] . "\": " . a:content["error"]["message"])

	catch /^Vim(let):E716.*: .*\d\+.*/
		call becomplete#log#error("missing request data for id " . l:id)

	catch /.*/
		call becomplete#log#error("unexpected exception, check if the format has changed: \"" . v:exception . "\"")

	finally
		if exists("l:id")
			unlet a:server["requests"][l:id]
		endif
	endtry
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	vim job input handler
"
" \param	channel		vim channel string
" \param	msg			string with the received message
function becomplete#lsp#base#rx_hdlr(channel, msg)
	let l:server = becomplete#lsp#server#get(ch_getjob(a:channel))

	if l:server == {}
		call becomplete#log#error("received data for non-existing server")
		return
	endif

	let l:server["data"] .= a:msg

	while len(l:server["data"])
		" try to split data into header and content
		" considering
		"	- data containing an incomplete message
		"	- data containing a complete, followed by an incomplete message
		let l:parts = split(l:server["data"], "\r\n\r\n")
		let l:hdr = len(l:parts) > 0 ? l:parts[0] : "incomplete:-1"
		let l:content_len = str2nr(split(l:hdr, ":")[1])
		let l:content = len(l:parts) > 1 ? l:parts[1][:l:content_len - 1] : ""

		" return on incomplete message
		if len(l:content) != l:content_len
			break
		endif

		" handle message and remove it from the server
		call s:handle_message(l:server, json_decode(l:content))
		let l:server["data"] = l:server["data"][len(l:parts[0]) + 4 + l:content_len:]
	endwhile
endfunction
"}}}

"{{{
" \brief	issue an lsp request
"
" \param	server		lsp server object
" \param	method		lsp method to call
" \param	params		parameters for a:method
"
" \return	if the server is not running while not currently performing the
"			server initialisation, an empty dictionary is returned
"			otherwise the lsp result is returned as a dictionary
function becomplete#lsp#base#request(server, method, params)
	if job_status(a:server["job"]) != "run" || (a:server["initialised"] != 1 && a:method != "initialize")
		call becomplete#log#error("request \"" . a:method . "\": server not initialised")
		return {}
	endif

	let l:id = a:server["request-id"]
	let l:req = { "method": a:method }

	let a:server["requests"][l:id] = l:req
	let a:server["request-id"] += 1

	call s:send(a:server["job"], s:format(a:method, a:params, l:id))

	return s:await_response(l:req, a:server["timeout-ms"])
endfunction
"}}}

"{{{
" \brief	issue an lsp notification
"
" \param	server	lsp server object
" \param	method	lsp method to call
" \param	params	parameters for a:method
function becomplete#lsp#base#notification(server, method, params)
	if a:server["initialised"] != 1 && a:method != "initialized"
		call becomplete#log#error("notification \"" . a:method . "\": server not initialised")
		return
	endif

	call s:send(a:server["job"], s:format(a:method, a:params))
endfunction
"}}}
