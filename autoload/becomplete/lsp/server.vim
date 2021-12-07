""""
"" global variables
""""

"{{{
" mapping from vim file type to lsp server object
let s:server_types = {}

" mapping from vim job string to lsp server object
let s:server_jobs = {}
"}}}


""""
"" local functions
""""

"{{{
" \brief	create an lsp server object with default values
"
" \param	cmd			list representing the language server binary and its
"						command line arguments
" \param	filetypes	list of vim file types that the server supports
" \param	timeout_ms	timeout [ms] for synchronous lsp requests
"
" \return	server object as a dictionary
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
	\	"doc_open": function("becomplete#lsp#response#unavail_list"),
	\	"doc_close": function("becomplete#lsp#response#unavail_list"),
	\	"doc_update": function("becomplete#lsp#response#unavail_list"),
	\	"complete": function("becomplete#lsp#response#unavail_list"),
	\	"goto_decl": function("becomplete#lsp#response#unavail_list"),
	\	"goto_def": function("becomplete#lsp#response#unavail_list"),
	\	"symbols": function("becomplete#lsp#response#unavail_list"),
	\ }
endfunction
"}}}

"{{{
" \brief	set server callback functions based on the given capabilities
"
" \param	server			lsp server object
" \param	capabilities	dictionary containing the returned capabilities of
"							a language server
function s:server_capabilities(server, capabilities)
	" document synchronisation callbacks
	let a:server["doc_open"] = function("becomplete#lsp#document#open")
	let a:server["doc_close"] = function("becomplete#lsp#document#close")
	let a:server["doc_update"] = function("becomplete#lsp#document#update")

	if has_key(a:capabilities, "textDocumentSync")
		let l:sync_capa = get(a:capabilities, "textDocumentSync", {})

		if type(l:sync_capa) == type({})
			let l:open_close = get(l:sync_capa, "openClose", 1)
			let l:change = get(l:sync_capa, "change", 1)

			if l:open_close == 0
				let a:server["doc_open"] = function("becomplete#lsp#response#unavail_list")
				let a:server["doc_close"] = function("becomplete#lsp#response#unavail_list")
			endif

			if l:change == 0 || l:open_close == 0
				let a:server["doc_update"] = function("becomplete#lsp#response#unavail_list")
			endif

		elseif l:sync_capa == 0
			let a:server["doc_update"] = function("becomplete#lsp#response#unavail_list")
		endif
	endif

	" language feature callbacks
	if has_key(a:capabilities, "completionProvider") |		let a:server["complete"] = function("becomplete#lsp#complete#async") | endif
	if has_key(a:capabilities, "declarationProvider") |		let a:server["goto_decl"] = function("becomplete#lsp#goto#declaration") | endif
	if has_key(a:capabilities, "definitionProvider") |		let a:server["goto_def"] = function("becomplete#lsp#goto#definition") | endif
	if has_key(a:capabilities, "documentSymbolProvider") |	let a:server["symbols"] = function("becomplete#lsp#symbol#file") | endif
endfunction
"}}}

"{{{
" \brief	vim channel callback for close events
"
" \param	channel		vim channel object
function s:close_hdlr(channel)
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
" \brief	vim channel callback for error events
"
" \param	channel		vim channel object
" \param	msg			error message
function s:error_hdlr(channel, msg)
	call becomplete#log#msg("stderr: " . a:msg)
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	make a language server configuration known to the plugin
"
" \param	cmd			list representing the language server binary and its
"						command line arguments
" \param	filetypes	list of vim file types that the server supports
" \param	timeout_ms	timeout [ms] for synchronous lsp requests
"
function becomplete#lsp#server#register(cmd, filetypes, timeout_ms)
	let l:server = s:server(a:cmd, [], a:timeout_ms)

	for l:ftype in a:filetypes
		if !has_key(s:server_types, l:ftype)
			call becomplete#log#msg("register server for " . l:ftype)

			let l:server["filetypes"] += [ l:ftype ]
			let s:server_types[l:ftype] = l:server

		else
			call becomplete#log#error("server for filetype " . l:ftype . " already registered")
		endif
	endfor
endfunction
"}}}

"{{{
" \brief	start a language server for the given file type
"
" \param	filetype	vim file type
"
" \return	the language server
function becomplete#lsp#server#start(filetype)
	let l:server = get(s:server_types, a:filetype, {})

	if l:server == {}
		call becomplete#log#msg("no server registered for file type " . a:filetype)
		return s:server()
	endif

	if l:server["initialised"] == 1
		return l:server
	endif

	call becomplete#log#msg("starting " . a:filetype . " language server: " . l:server["command"][0])

	" start language server as vim job
	let l:opts = {}
	let l:opts["close_cb"] = function("s:close_hdlr")
	let l:opts["in_mode"] = "raw"
	let l:opts["out_mode"] = "raw"
	let l:opts["out_cb"] = "becomplete#lsp#base#rx_hdlr"
	let l:opts["err_cb"] = function("s:error_hdlr")

	let l:job = job_start(l:server["command"], l:opts)
	call becomplete#log#msg("server job id: " . l:job)

	let l:server["job"] = l:job
	let s:server_jobs[l:job] = l:server

	" initialise language server
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
	\		"completion": {
	\			"dynamicRegistration": v:false,
	\			"completionItem": {
	\				"snippetSupport": v:false,
	\				"commitCharactersSupport": v:false,
	\				"documentationFormat": [ "plaintext" ],
	\				"deprecatedSupport": v:false,
	\				"preselectSupport": v:false,
	\				"insertReplaceSupport": v:false,
	\				"resolveSupport": [],
	\				"insertTextModeSupport": {
	\					"valueSet": [ 1 ],
	\				},
	\				"labelDetailsSupport": v:true,
	\			},
	\			"contextSupport": v:false,
	\			"insertTextMode": 1,
	\		},
	\		"declaration": {
	\			"dynamicRegistration": v:false,
	\			"linkSupport": v:false,
	\		},
	\		"definition": {
	\			"dynamicRegistration": v:false,
	\			"linkSupport": v:false,
	\		},
	\		"documentSymbol": {
	\			"dynamicRegistration": v:false,
	\			"hierarchicalDocumentSymbolSupport": v:true,
	\			"tagSupport": v:false,
	\			"labelSupport": v:false,
	\		},
	\	}
	\ }

	let l:res = becomplete#lsp#base#request(l:server, "initialize", l:p)

	if l:res != {}
		call s:server_capabilities(l:server, l:res["capabilities"])

		call becomplete#log#msg("server initialised")
		call becomplete#lsp#base#notification(l:server, "initialized", {})
		let l:server["initialised"] = 1

	else
		call becomplete#log#error("server initialisation failed")
		let l:server["initialised"] = -1
	endif

	return l:server
endfunction
"}}}

"{{{
" \brief	terminate all running language servers
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
" \brief	return a language server object
"
" \param	arg		might either be a vim job object or a file name
"
" \return	language server object
function becomplete#lsp#server#get(arg)
	if has_key(s:server_jobs, a:arg)
		return s:server_jobs[a:arg]
	endif

	return get(s:server_types, getbufvar(a:arg, "&filetype"), s:server())
endfunction
"}}}
