""""
"" local variables
""""

"{{{
" mapping from file names to language server file version
let s:versions = {}

" mapping from file names to modifcation state
let s:modified = {}
"}}}


""""
"" global functions
""""

"{{{
" \brief	lsp document open wrapper
"
" \param	file	file to open
function becomplete#lsp#document#open(file)
	if !has_key(s:versions, a:file)
		let s:versions[a:file] = 0
	endif

	let s:modified[a:file] = 0

	call becomplete#lsp#base#notification(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/didOpen",
	\	becomplete#lsp#param#doc_item(a:file, s:versions[a:file])
	\ )
endfunction
"}}}

"{{{
" \brief	lsp document close wrapper
"
" \param	file	file to close
function becomplete#lsp#document#close(file)
	if !has_key(s:versions, a:file)
		return
	endif

	call becomplete#lsp#base#notification(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/didClose",
	\	becomplete#lsp#param#doc(a:file)
	\ )
endfunction
"}}}

"{{{
" \brief	lsp document update wrapper
"
" \param	file	file to update
function becomplete#lsp#document#update(file)
	if getbufvar(a:file, "&modified") == 0 && s:modified[a:file] == 0
		return
	endif

	let s:versions[a:file] += 1
	let s:modified[a:file] = 0

	call becomplete#lsp#base#notification(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/didChange",
	\	becomplete#lsp#param#doc_changed(a:file, s:versions[a:file], becomplete#util#buftext(a:file))
	\ )
endfunction
"}}}

"{{{
" \brief	mark a file as modified
"
" \param	file	file to mark
function becomplete#lsp#document#modified(file)
	let s:modified[a:file] = 1
endfunction
"}}}
