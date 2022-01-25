""""
"" local functions
""""

"{{{
" \brief	stop the given server
"
" \param	server	server object
function s:shutdown(server)
	let a:server["initialised"] = 0
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	start the given server
"
" \param	server	server object
function becomplete#ctags#server#start(server, filetype)
	let l:supported = index(becomplete#ctags#symtab#filetypes(), a:filetype) != -1
	let l:configured = has_key(g:becomplete_ctags_languages, a:filetype)

	if !l:supported || !l:configured
		call becomplete#log#msg("file type \"" . a:filetype . "\""
		\ . " supported (" . l:supported . "),"
		\ . " configured (" . l:configured . ")"
		\ )

		return
	endif

	let a:server["doc_open"] = function("becomplete#ctags#document#open")
	let a:server["doc_close"] = function("becomplete#server#nop")
	let a:server["doc_update"] = function("becomplete#ctags#document#update")
	let a:server["doc_write"] = function("becomplete#server#nop")

	let a:server["complete"] = function("becomplete#server#nop")
	let a:server["goto_decl"] = function("becomplete#ctags#goto#declaration")
	let a:server["goto_def"] = function("becomplete#ctags#goto#definition")
	let a:server["symbols"] = function("becomplete#ctags#symbol#file")

	let a:server["shutdown"] = function("s:shutdown")

	if get(g:becomplete_ctags_languages[a:filetype], "recursive", 0)
		call becomplete#ctags#symtab#init(fnamemodify(bufname(), ":h"), a:filetype)
	endif

	let a:server["initialised"] = 1
endfunction
"}}}
