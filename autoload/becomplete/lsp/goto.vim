""""
"" local functions
""""

"{{{
function s:item_filter(items, type)
	let l:items = becomplete#lsp#response#ensure_list(a:items)
	let l:lst = []

	for l:item in l:items
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
function becomplete#lsp#goto#definition(file, line, column)
	call becomplete#log#msg("goto definition for " . a:file . ":" . a:line . ":" . a:column)

	return s:item_filter(
	\	becomplete#lsp#base#request(
	\		becomplete#lsp#server#get(a:file),
	\		"textDocument/definition",
	\		becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\	),
	\	"def"
	\ )
endfunction
"}}}

"{{{
function becomplete#lsp#goto#declaration(file, line, column)
	call becomplete#log#msg("goto declaration for " . a:file . ":" . a:line . ":" . a:column)

	return s:item_filter(
	\	becomplete#lsp#base#request(
	\		becomplete#lsp#server#get(a:file),
	\		"textDocument/declaration",
	\		becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\	),
	\	"decl"
	\ )
endfunction
"}}}
