""""
"" local variables
""""

"{{{
" mapping from vim file type to lsp server object
let s:server_types = {}
"}}}


""""
"" local functions
""""

"{{{
" \brief	create a server object with default values
"
" \param	cmd			list representing the server binary and its command
"						line arguments
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
	\	"doc_open": function("becomplete#server#nop"),
	\	"doc_close": function("becomplete#server#nop"),
	\	"doc_update": function("becomplete#server#nop"),
	\	"complete": function("becomplete#server#nop"),
	\	"goto_decl": function("becomplete#server#nop"),
	\	"goto_def": function("becomplete#server#nop"),
	\	"symbols": function("becomplete#server#nop"),
	\	"shutdown": function("becomplete#server#nop"),
	\ }
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	make a server configuration known to the plugin
"
" \param	cmd			list representing the server binary and its command
"						line arguments
" \param	filetypes	list of vim file types that the server supports
" \param	timeout_ms	timeout [ms] for synchronous lsp requests
"
function becomplete#server#register(cmd, filetypes, timeout_ms)
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
" \brief	start a server for the given file type
"
" \param	filetype	vim file type
"
" \return	server object
function becomplete#server#start(filetype)
	let l:server = get(s:server_types, a:filetype, s:server())

	if l:server["initialised"] == 1
		return l:server
	endif

	if l:server["command"] != []
		call becomplete#lsp#server#start(l:server)
	endif

	if l:server["initialised"] == 0
		call becomplete#log#msg("falling back to ctags implementation for file type: " . a:filetype)
		call becomplete#ctags#server#start(l:server, a:filetype)
	endif

	let s:server_types[a:filetype] = l:server

	return l:server
endfunction
"}}}

"{{{
" \brief	terminate all running servers
function becomplete#server#stop_all()
	for l:server in values(s:server_types)
		if l:server["initialised"] != 1
			continue
		endif

		call becomplete#log#msg("trigger server shutdown: " . get(l:server["command"], 0, "ctags"))

		call l:server["shutdown"](l:server)
		let l:server["initialised"] = 0
	endfor
endfunction
"}}}

"{{{
" \brief	return a server object for the given file
"
" \param	file	file name
"
" \return	server object
function becomplete#server#get(file)
	return get(s:server_types, getbufvar(a:file, "&filetype"), s:server())
endfunction
"}}}

"{{{
" \brief	check if the server supports a certain feature/callback
"
" \param	server		server object
" \param	callback	string identifying the callback to check, cf. the
"						functions set in s:server()
"
" \return	v:true if the callback is supported
"			v:false otherwise
function becomplete#server#supports(server, callback)
	if has_key(a:server, a:callback) && a:server[a:callback] != function("becomplete#server#nop")
		return v:true
	endif

	return v:false
endfunction
"}}}

"{{{
" \brief	no-op function, to be used for server callbacks that are not
"			supported
"
" \return	empty list
function becomplete#server#nop(...)
	return []
endfunction
"}}}
