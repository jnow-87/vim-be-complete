""""
"" local functions
""""

"{{{
" \brief	convert lsp goto declaration/definition items to a list of
"			dictionaries
"
" \param	response	result of the lsp goto declaration/definition request
" \param	type		type of the goto request, the given string will be
"						used as the "type" key of the returned dictionaries
"
" \return	list of dictionaries with each entry having the following keys
"				file:	file name of the declaration/definition
"				line:	line within the target file
"				type:	type string according to a:type
function s:item_filter(response, type)
	let l:lst = []

	for l:item in becomplete#lsp#response#ensure_list(a:response)
		let l:file = becomplete#lsp#response#uri(l:item)
		let l:line = becomplete#lsp#response#range(l:item)[0]

		if l:file == "" || l:line == -1
			continue
		endif

		let l:lst += [{ "file": l:file, "line": l:line, "type": a:type }]
	endfor

	return l:lst
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	lsp goto definition wrapper
"
" \param	file	file name to resolve for
" \param	line	line within a:file
" \param	column	column within a:line
"
" \return	list of locations according to s:item_filter()
function becomplete#lsp#goto#definition(file, line, column)
	call becomplete#log#msg("goto definition for " . a:file . ":" . a:line . ":" . a:column)

	return s:item_filter(
	\	becomplete#lsp#base#request(
	\		becomplete#server#get(a:file),
	\		"textDocument/definition",
	\		becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\	),
	\	g:becomplete_type_definition
	\ )
endfunction
"}}}

"{{{
" \brief	lsp goto declaration wrapper
"
" \param	file	file name to resolve for
" \param	line	line within a:file
" \param	column	column within a:line
"
" \return	list of locations according to s:item_filter()
function becomplete#lsp#goto#declaration(file, line, column)
	call becomplete#log#msg("goto declaration for " . a:file . ":" . a:line . ":" . a:column)

	return s:item_filter(
	\	becomplete#lsp#base#request(
	\		becomplete#server#get(a:file),
	\		"textDocument/declaration",
	\		becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\	),
	\	g:becomplete_type_declaration
	\ )
endfunction
"}}}
