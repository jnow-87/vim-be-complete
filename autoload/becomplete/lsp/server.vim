""""
"" local variables
""""

"{{{
" mapping from vim job string to lsp server object
let s:server_jobs = {}
"}}}


""""
"" local functions
""""

"{{{
" \brief	stop the given server
"
" \param	server	server object
function s:shutdown(server)
	if a:server["initialised"] != 1
		return
	endif

	call becomplete#log#msg("trigger server shutdown: " . a:server["command"][0])
	let l:res = becomplete#lsp#base#request(a:server, "shutdown", {})

	if l:res == v:null
		let l:job = a:server["job"]

		call becomplete#log#msg("server shutdown")
		call becomplete#lsp#base#notification(a:server, "exit", {})

		call job_stop(l:job)
		unlet s:server_jobs[l:job]

		let a:server["job"] = ""
		let a:server["initialised"] = 0

	else
		call becomplete#log#error("server shutdown failed: " . a:server["command"])
	endif
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
				let a:server["doc_open"] = function("becomplete#server#nop")
				let a:server["doc_close"] = function("becomplete#server#nop")
			endif

			if l:change == 0 || l:open_close == 0
				let a:server["doc_update"] = function("becomplete#server#nop")
			endif

			if has_key(l:sync_capa, "save")
				let a:server["doc_write"] = function("becomplete#lsp#document#write")
			endif

		elseif l:sync_capa == 0
			let a:server["doc_update"] = function("becomplete#server#nop")
		endif
	endif

	" language feature callbacks
	if has_key(a:capabilities, "completionProvider") |		let a:server["complete"] = function("becomplete#lsp#complete#completion") | endif
	if has_key(a:capabilities, "declarationProvider") |		let a:server["goto_decl"] = function("becomplete#lsp#goto#declaration") | endif
	if has_key(a:capabilities, "definitionProvider") |		let a:server["goto_def"] = function("becomplete#lsp#goto#definition") | endif
	if has_key(a:capabilities, "documentSymbolProvider") |	let a:server["symbols"] = function("becomplete#lsp#symbol#file") | endif

	" misc
	let a:server["shutdown"] = function("s:shutdown")
endfunction
"}}}

"{{{
" \brief	vim channel callback for close events
"
" \param	channel		vim channel object
function s:close_hdlr(channel)
	let l:job = ch_getjob(a:channel)
	let l:server = becomplete#lsp#server#get(l:job)

	if l:server != {}
		call becomplete#log#error("server closed for filetypes " . string(l:server["filetypes"]))

		unlet s:server_jobs[l:job]

		let a:server["job"] = ""
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
" \brief	start the given language server
"
" \param	server	server object
function becomplete#lsp#server#start(server)
	call becomplete#log#msg("starting language server: " . a:server["command"][0])

	" start language server as vim job
	let l:opts = {}
	let l:opts["close_cb"] = function("s:close_hdlr")
	let l:opts["in_mode"] = "raw"
	let l:opts["out_mode"] = "raw"
	let l:opts["out_cb"] = function("becomplete#lsp#base#rx_hdlr")
	let l:opts["err_cb"] = function("s:error_hdlr")

	let l:job = job_start(a:server["command"], l:opts)
	call becomplete#log#msg("server job id: " . l:job)

	let a:server["job"] = l:job
	let s:server_jobs[l:job] = a:server

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

	let l:res = becomplete#lsp#base#request(a:server, "initialize", l:p)

	if l:res != {}
		call s:server_capabilities(a:server, l:res["capabilities"])

		call becomplete#log#msg("server initialised")
		call becomplete#lsp#base#notification(a:server, "initialized", {})

		let a:server["initialised"] = 1

	else
		call becomplete#log#error("server initialisation failed")
		let a:server["initialised"] = -1
	endif
endfunction
"}}}

"{{{
" \brief	return a server object for the given job
"
" \param	job		vim job object
"
" \return	language server object
"			on error an empty dictionary is returned
function becomplete#lsp#server#get(job)
	return get(s:server_jobs, a:job, {})
endfunction
"}}}
