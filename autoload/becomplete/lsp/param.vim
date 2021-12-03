""""
"" local functions
""""

"{{{
" \brief	create an lsp uri for the given file name
"
" \param	file	file name
"
" \return	uri string
function s:uri(file)
	return "file://" . a:file
endfunction
"}}}

"{{{
" \brief	create an lsp position dictionary
"
" \param	line	line number
" \param	column	column number
"
" \return	lsp position dictionary
function s:position(line, column)
	return { "line": a:line - 1, "character": a:column - 1 }
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	create an lsp document id
"
" \param	file	file name
"
" \return	dictionary
function becomplete#lsp#param#doc_id(file)
	return { "uri": s:uri(a:file) }
endfunction
"}}}

"{{{
" \brief	create an lsp text document dictionary
"
" \param	file	file name
"
" \return	dictionary
function becomplete#lsp#param#doc(file)
	return {
	\	"textDocument": becomplete#lsp#param#doc_id(a:file),
	\ }
endfunction
"}}}

"{{{
" \brief	create an lsp text document item
"
" \param	file	file name
" \param	version	file version number
"
" \return	dictionary
function becomplete#lsp#param#doc_item(file, version)
	return {
	\	"textDocument": {
	\		"uri": s:uri(a:file),
	\		"languageId": getbufvar(bufnr(a:file), "&filetype"),
	\		"version": a:version,
	\		"text": join(getbufline(a:file, 1, '$'), "\n")."\n",
	\	}
	\ }
endfunction
"}}}

"{{{
" \brief	create an lsp document position
"
" \param	file	file name
" \param	line	line number
" \param	column	column number
"
" \return	dictionary
function becomplete#lsp#param#doc_pos(file, line, column)
	return {
	\	"textDocument": becomplete#lsp#param#doc_id(a:file),
	\	"position": s:position(a:line, a:column),
	\ }
endfunction
"}}}
