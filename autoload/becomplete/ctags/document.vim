""""
"" local variables
""""

"{{{
" mapping from file names to modifcation state
let s:modified = {}
"}}}


""""
"" global functions
""""

"{{{
" \brief	ctags document open wrapper
"
" \param	file	file to open
function becomplete#ctags#document#open(file)
	let s:modified[a:file] = 0
	call becomplete#ctags#symtab#update(a:file)
endfunction
"}}}

"{{{
" \brief	ctags document update wrapper
"
" \param	file	file to update
function becomplete#ctags#document#update(file)
	if getbufvar(a:file, "&modified") == 0  && s:modified[a:file] == 0
		return
	endif

	let s:modified[a:file] = 0
	call becomplete#ctags#symtab#update(a:file)
endfunction
"}}}

"{{{
" \brief	mark a file as modified
"
" \param	file	file to mark
function becomplete#ctags#document#modified(file)
	let s:modified[a:file] = 1
endfunction
"}}}
