""""
"" local variables
""""

"{{{
" string representations for the lsp document symbol item kinds
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


""""
"" local functions
""""

"{{{
" \brief	convert the lsp document symbols to a list of dictionaries
"
" \param	response	result of the lsp document symbol request
" \param	kinds		list of symbol kinds to look for, according to
"						g:becomplete_kindsym_*
"
" \return	list of dictionaries with the following keys
"				name: symbol name
"				line: line within the file
"				kind: symbol kind according to g:becomplete_kindsym_*
"				detail: auxiliary information
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
" \brief	lsp document symbol wrapper
"
" \param	file	file name to gather symbols for
" \param	kinds	list of symbol kinds to look for, according to
"					g:becomplete_kindsym_*
"
" \return	list of symbols, cf. s:parse()
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
