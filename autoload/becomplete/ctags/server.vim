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
	if index(becomplete#ctags#symtab#filetypes(), a:filetype) == -1
		return
	endif

	let a:server["doc_open"] = function("becomplete#ctags#document#open")
	let a:server["doc_close"] = function("becomplete#server#nop")
	let a:server["doc_update"] = function("becomplete#ctags#document#update")
	let a:server["doc_modified"] = function("becomplete#ctags#document#modified")

	let a:server["complete"] = function("becomplete#server#nop")
	let a:server["goto_decl"] = function("becomplete#ctags#goto#declaration")
	let a:server["goto_def"] = function("becomplete#ctags#goto#definition")
	let a:server["symbols"] = function("becomplete#ctags#symbol#file")

	let a:server["shutdown"] = function("s:shutdown")

	call becomplete#ctags#symtab#init(fnamemodify(bufname(), ":h"), a:filetype)

	let a:server["initialised"] = 1
endfunction
"}}}
