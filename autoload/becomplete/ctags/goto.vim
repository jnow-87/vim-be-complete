""""
"" local functions
""""

"{{{
" \brief	filter the ctags symbol table for all occurrences of the symbol at
"			the given location matching a:type
"
" \param	file	file name
" \param	line	line number into a:file
" \param	column	column into a:file[a:line]
" \param	type	type according to g:becomplete_type_*
"
" \return	list of matching symbols
function s:filter(file, line, colum, type)
	let l:word = becomplete#util#word_at(a:file, a:line, a:colum)

	call becomplete#log#msg(" symbol lookup for: " . l:word)

	let l:items = []

	for l:sym in becomplete#ctags#symtab#lookup(l:word)
		if l:sym["type"] != a:type
			continue
		endif

		let l:items += [{
		\	"file": l:sym["file"],
		\	"line": l:sym["line"],
		\	"type": a:type
		\ }]
	endfor

	return l:items
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	ctags goto definition wrapper
"
" \param	file	file name to resolve for
" \param	line	line within a:file
" \param	column	column within a:line
"
" \return	list of locations according to s:filter()
function becomplete#ctags#goto#definition(file, line, column)
	call becomplete#log#msg("goto definition for " . a:file . ":" . a:line . ":" . a:column)

	return s:filter(a:file, a:line, a:column, g:becomplete_type_definition)
endfunction
"}}}

"{{{
" \brief	ctags goto declaration wrapper
"
" \param	file	file name to resolve for
" \param	line	line within a:file
" \param	column	column within a:line
"
" \return	list of locations according to s:filter()
function becomplete#ctags#goto#declaration(file, line, column)
	call becomplete#log#msg("goto declaration for " . a:file . ":" . a:line . ":" . a:column)

	return s:filter(a:file, a:line, a:column, g:becomplete_type_declaration)
endfunction
"}}}
