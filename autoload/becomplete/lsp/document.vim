""""
"" local variables
""""

"{{{
let s:file_versions = {}
"}}}


""""
"" global functions
""""

"{{{
function becomplete#lsp#document#open(file)
	let l:server = becomplete#lsp#server#get(a:file)

	if !has_key(s:file_versions, a:file)
		let s:file_versions[a:file] = 0
	endif

	let l:p = {}
	let l:p["textDocument"] = {
	\	"uri": "file://" . a:file,
	\	"languageId": getbufvar(bufnr(a:file), "&filetype"),
	\	"version": s:file_versions[a:file],
	\	"text": join(getbufline(a:file, 1, '$'), "\n")."\n"
	\ }

	call becomplete#lsp#base#notification(l:server, "textDocument/didOpen", l:p)
endfunction
"}}}

"{{{
function becomplete#lsp#document#close(file)
	let l:server = becomplete#lsp#server#get(a:file)

	let l:p = {}
	let l:p["textDocument"] = { "uri": "file://" . a:file }

	call becomplete#lsp#base#notification(l:server, "textDocument/didClose", l:p)
endfunction
"}}}
