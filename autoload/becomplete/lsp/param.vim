""""
"" local functions
""""

"{{{
function s:uri(file)
	return "file://" . a:file
endfunction
"}}}

"{{{
function s:position(line, column)
	return { "line": a:line - 1, "character": a:column - 1 }
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#lsp#param#doc_id(file)
	return { "uri": s:uri(a:file) }
endfunction
"}}}

"{{{
function becomplete#lsp#param#doc(file)
	return {
	\	"textDocument": becomplete#lsp#param#doc_id(a:file),
	\ }
endfunction
"}}}

"{{{
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
function becomplete#lsp#param#doc_pos(file, line, column)
	return {
	\	"textDocument": becomplete#lsp#param#doc_id(a:file),
	\	"position": s:position(a:line, a:column),
	\ }
endfunction
"}}}
