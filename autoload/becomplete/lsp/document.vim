""""
"" local variables
""""

"{{{
" mapping of file names to integers indicating the language server file
" version
let s:file_versions = {}
"}}}


""""
"" global functions
""""

"{{{
" \brief	lsp document open wrapper
"
" \param	file	file to open
function becomplete#lsp#document#open(file)
	if !has_key(s:file_versions, a:file)
		let s:file_versions[a:file] = 0
	endif

	call becomplete#lsp#base#notification(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/didOpen",
	\	becomplete#lsp#param#doc_item(a:file, s:file_versions[a:file])
	\ )
endfunction
"}}}

"{{{
" \brief	lsp document close wrapper
"
" \param	file	file to close
function becomplete#lsp#document#close(file)
	call becomplete#lsp#base#notification(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/didClose",
	\	becomplete#lsp#param#doc(a:file)
	\ )
endfunction
"}}}
