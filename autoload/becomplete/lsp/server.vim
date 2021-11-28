""""
"" global variables
""""

"{{{
let s:server_types = {}
let s:server_jobs = {}
"}}}


""""
"" local functions
""""

"{{{
function s:server(cmd=[], filetypes=[], timeout_ms=0)
	return {
	\	"initialised": 0,
	\
	\	"command": a:cmd,
	\	"job": "",
	\	"filetypes": a:filetypes,
	\	"timeout-ms": a:timeout_ms,
	\	"request-id": 0,
	\	"requests": {},
	\	"data": "",
	\
	\	"complete": function("becomplete#lsp#response#unavail_list"),
	\	"goto_decl": function("becomplete#lsp#response#unavail_list"),
	\	"goto_def": function("becomplete#lsp#response#unavail_list"),
	\	"symbols": function("becomplete#lsp#response#unavail_list"),
	\ }
endfunction
"}}}

"{{{
function s:server_capabilities(server, capabilities)
	if has_key(a:capabilities, "completionProvider") |		let a:server["complete"] = function("becomplete#lsp#complete#async") | endif
	if has_key(a:capabilities, "declarationProvider") |		let a:server["goto_decl"] = function("becomplete#lsp#goto#declaration") | endif
	if has_key(a:capabilities, "definitionProvider") |		let a:server["goto_def"] = function("becomplete#lsp#goto#definition") | endif
	if has_key(a:capabilities, "documentSymbolProvider") |	let a:server["symbols"] = function("becomplete#lsp#symbol#file") | endif
endfunction
"}}}

"{{{
function s:server_start(filetype)
	let l:server = get(s:server_types, a:filetype, {})

	if l:server == {}
		call becomplete#log#error("no server registerd for filetype " . a:filetype)
		return
	endif

	if l:server["initialised"] == 1
		return
	endif

	call becomplete#log#msg("starting " . a:filetype . " language server: " . l:server["command"][0])

	" start language server as vim job
	let l:opts = {}
	let l:opts["close_cb"] = function("s:close_hdlr")
	let l:opts["in_mode"] = "raw"
	let l:opts["out_mode"] = "raw"
	let l:opts["out_cb"] = "becomplete#lsp#base#rx_hdlr"
	let l:opts["err_cb"] = function("s:error_hdlr")

	" TODO handle errors
	let l:job = job_start(l:server["command"], l:opts)
	call becomplete#log#msg("server job id: " . l:job)

	let l:server["job"] = l:job
	let s:server_jobs[l:job] = l:server

	" initialise language server protocol
	let l:p = {}
	let l:p["rootUri"] = "file://" . getcwd()
	let l:p["clientInfo"] = { "name": "vim-be-complete" }
	let l:p["processId"] = getpid()
	let l:p["locale"] = $LANG
	let l:p["trace"] = "verbose"
	let l:p["capabilities"] = {
	\	"textDocument": {
	\		"publishDiagnostics": {
	\			"relatedInformation": v:false,
	\			"versionSupport": v:false,
	\			"codeDescriptionSupport": v:false,
	\			"dataSupport": v:false,
	\			"tagSupport": { "valueSet": "" },
	\		},
	\		"documentSymbol": {
	\			"hierarchicalDocumentSymbolSupport": v:false,
	\		},
	\	}
	\ }

	let l:res = becomplete#lsp#base#request(l:server, "initialize", l:p)

	if l:res != {}
		call s:server_capabilities(l:server, l:res["capabilities"])

		call becomplete#log#msg("server initialised")
		call becomplete#lsp#base#notification(l:server, "initialized", {})
		let l:server["initialised"] = 1

		for l:ftype in l:server["filetypes"]
			exec "autocmd! BeComplete FileType " . l:ftype
		endfor

	else
		call becomplete#log#error("server initialisation failed")
		let l:server["initialised"] = -1
	endif
endfunction
"}}}

"{{{
function s:close_hdlr(channel)
	" TODO check if s:close_hdlr is triggered if the server is killed/closes
	"      on its own
	let l:job = ch_getjob(a:channel)
	let l:server = get(s:server_jobs, l:job, {})

	if l:server != {}
		call becomplete#log#error("server closed for filetypes " . string(l:server["filetypes"]))

		unlet s:server_jobs[l:job]
		let l:server["initialised"] = -1
	endif
endfunction
"}}}

"{{{
function s:error_hdlr(channel, msg)
	call becomplete#log#msg("stderr: " . a:msg)
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#lsp#server#register(cmd, filetypes, timeout_ms)
	let l:server = s:server(a:cmd, [], a:timeout_ms)

	for l:ftype in a:filetypes
		if !has_key(s:server_types, l:ftype)
			call becomplete#log#msg("register server for " . l:ftype)

			let l:server["filetypes"] += [ l:ftype ]
			let s:server_types[l:ftype] = l:server

			exec "autocmd BeComplete FileType " . l:ftype . " call s:server_start(\"" . l:ftype . "\")"
		else
			call becomplete#log#error("server for filetype " . l:ftype . " already registered")
		endif
	endfor
endfunction
"}}}

"{{{
function becomplete#lsp#server#stop_all()
	for l:server in values(s:server_jobs)
		call becomplete#log#msg("trigger server shutdown: " . l:server["command"][0])
		let l:res = becomplete#lsp#base#request(l:server, "shutdown", {})

		if l:res == v:null
			let l:job = l:server["job"]

			call becomplete#log#msg("server shutdown")
			call becomplete#lsp#base#notification(l:server, "exit", {})

			call job_stop(l:job)
			unlet s:server_jobs[l:job]
			let l:server["initialised"] = 0

		else
			call becomplete#log#error("server shutdown failed: " . l:server["command"])
		endif
	endfor
endfunction
"}}}

"{{{
function becomplete#lsp#server#get(arg)
	if has_key(s:server_jobs, a:arg)
		return s:server_jobs[a:arg]
	endif

	return get(s:server_types, getbufvar(a:arg, "&filetype"), s:server())
endfunction
"}}}
