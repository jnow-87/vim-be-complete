""""
"" global functions
""""

"{{{
" \brief	ctags document open wrapper
"
" \param	file	file to open
function becomplete#ctags#document#open(file)
	call becomplete#ctags#symtab#update(a:file, getbufvar(a:file, "&filetype"))
endfunction
"}}}

"{{{
" \brief	ctags document update wrapper
"
" \param	file	file to update
function becomplete#ctags#document#update(file)
	call becomplete#ctags#symtab#update(a:file, getbufvar(a:file, "&filetype"))
endfunction
"}}}
