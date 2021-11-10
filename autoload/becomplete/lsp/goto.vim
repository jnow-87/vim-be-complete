""""
"" global functions
""""

"{{{
function becomplete#lsp#goto#definition(file, line, column)
	call becomplete#log#msg("goto definition for " . a:file . ":" . a:line . ":" . a:column)

	return becomplete#lsp#response#ensure_list(
	\	becomplete#lsp#base#request(
	\		becomplete#lsp#server#get(a:file),
	\		"textDocument/definition",
	\		becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\	)
	\ )
endfunction
"}}}

"{{{
function becomplete#lsp#goto#declaration(file, line, column)
	call becomplete#log#msg("goto declaration for " . a:file . ":" . a:line . ":" . a:column)

	return becomplete#lsp#response#ensure_list(
	\	becomplete#lsp#base#request(
	\		becomplete#lsp#server#get(a:file),
	\		"textDocument/declaration",
	\		becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\	)
	\ )
endfunction
"}}}
