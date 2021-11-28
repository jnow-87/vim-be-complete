""""
"" local variables
""""

"{{{
let s:symbol_kinds = [
\	g:becomplete_kindsym_undef,
\	g:becomplete_kindsym_file,
\	g:becomplete_kindsym_namespace,
\	g:becomplete_kindsym_namespace,
\	g:becomplete_kindsym_namespace,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_function,
\	g:becomplete_kindsym_member,
\	g:becomplete_kindsym_member,
\	g:becomplete_kindsym_specialfunction,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_function,
\	g:becomplete_kindsym_variable,
\	g:becomplete_kindsym_macro,
\	g:becomplete_kindsym_text,
\	g:becomplete_kindsym_macro,
\	g:becomplete_kindsym_macro,
\	g:becomplete_kindsym_variable,
\	g:becomplete_kindsym_variable,
\	g:becomplete_kindsym_variable,
\	g:becomplete_kindsym_macro,
\	g:becomplete_kindsym_member,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_specialfunction,
\	g:becomplete_kindsym_type,
\ ]
"}}}

"{{{
function s:parse(response, kinds=[])
	let l:items = []

	for l:item in becomplete#lsp#response#ensure_list(a:response)
		let l:name = l:item["name"]
		let l:kind = s:symbol_kinds[l:item["kind"]]
		let l:detail = get(l:item, "detail", "")
		let l:line = becomplete#lsp#response#range(get(l:item, "location", l:item))[0]

		if a:kinds == [] || index(a:kinds, l:kind) != -1
			call becomplete#log#msg(" symbol: " . l:line . ":" . l:name . " (" . l:kind . ") " . l:detail)
			let l:items += [{
			\	"name": l:name,
			\	"line": l:line,
			\	"kind": l:kind,
			\	"detail": l:detail,
			\ }]
		endif

		if has_key(l:item, "children")
			let l:items += s:parse(l:item["children"], a:kinds)
		endif
	endfor

	return l:items
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#lsp#symbol#file(file, kinds)
	call becomplete#log#msg("list symbols for " . a:file)

	return s:parse(
	\	becomplete#lsp#base#request(
	\		becomplete#lsp#server#get(a:file),
	\		"textDocument/documentSymbol",
	\		becomplete#lsp#param#doc(a:file)
	\	),
	\	a:kinds
	\ )
endfunction
"}}}
