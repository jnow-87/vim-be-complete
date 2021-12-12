""""
"" global functions
""""

"{{{
" \brief	ctags document symbol wrapper
"
" \param	file	file name to gather symbols for
" \param	kinds	list of symbol kinds to look for, according to
"					g:becomplete_kindsym_*
"
" \return	list of symbols
function becomplete#ctags#symbol#file(file, kinds)
	call becomplete#log#msg("list symbols for " . a:file)

	return becomplete#ctags#symtab#filesymbols(a:file, a:kinds)
endfunction
"}}}
