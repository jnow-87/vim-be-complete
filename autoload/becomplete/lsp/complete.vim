""""
"" local variables
""""

"{{{
let s:complete_kinds = [
\	g:becomplete_kindsym_undef,
\	g:becomplete_kindsym_text,
\	g:becomplete_kindsym_function,
\	g:becomplete_kindsym_function,
\	g:becomplete_kindsym_specialfunction,
\	g:becomplete_kindsym_member,
\	g:becomplete_kindsym_variable,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_namespace,
\	g:becomplete_kindsym_member,
\	g:becomplete_kindsym_text,
\	g:becomplete_kindsym_macro,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_text,
\	g:becomplete_kindsym_text,
\	g:becomplete_kindsym_text,
\	g:becomplete_kindsym_file,
\	g:becomplete_kindsym_type,
\	g:becomplete_kindsym_file,
\	g:becomplete_kindsym_member,
\	g:becomplete_kindsym_macro,
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
function s:item_filter(result)
	let l:items = []

	call becomplete#log#msg(printf("%20.20s %10.10s %10.10s %25.25s %10.10s %15.15s %6.6s %10.10s %s %s",
	\	"label", "kind", "detail", "ldetail", "insert", "command", "select", "data", "docu", "edit")
	\ )

	for l:item in a:result["items"]
		let l:label = trim(get(l:item, "label", ""), " ")
		let l:ldetail = get(l:item, "labelDetails", {})
		let l:ldetail_descr = get(l:ldetail, "description", "")
		let l:ldetail = get(l:ldetail, "detail", "")
		let l:detail = get(l:item, "detail", "")
		let l:kind = s:complete_kinds[get(l:item, "kind", 0)]
		let l:docu = get(l:item, "documentation", "")
		let l:select = get(l:item, "preselect", "")
		let l:insert = get(l:item, "insertText", "")
		let l:cmd = get(l:item, "command", "")
		let l:data = get(l:item, "data", "")
		let l:edit = get(l:item, "textEdit", "")

		call becomplete#log#msg(printf("%20.20s %10.10s %10.10s %10.10s %14.14s %10.10s %15.15s %6.6s %10.10s %s %s",
		\	l:label, l:kind, l:detail, l:ldetail, l:ldetail_descr, l:insert, l:cmd, l:select, l:data, l:docu, l:edit)
		\ )

		call add(l:items, {
		\		"abbr": l:insert,
		\		"word": becomplete#complete#arg_annotate(l:label),
		\		"kind": l:kind,
		\		"menu": l:detail . " " . l:label,
		\	}
		\ )
	endfor

	return l:items
endfunction
"}}}

"{{{
function s:complete_hdlr(server, result, request_id)
	call complete(becomplete#complete#find_start() + 1, s:item_filter(a:result))
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#lsp#complete#async(file, line, column)
	call becomplete#log#msg("completion for " . a:file . ":" . a:line . ":" . a:column)

	call becomplete#lsp#base#request(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/completion",
	\	becomplete#lsp#param#doc_pos(a:file, a:line, a:column),
	\	function("s:complete_hdlr")
	\ )
endfunction
"}}}

"{{{
function becomplete#lsp#complete#sync(file, line, column)
	call becomplete#log#msg("completion for " . a:file . ":" . a:line . ":" . a:column)

	let l:res = becomplete#lsp#base#request(
	\	becomplete#lsp#server#get(a:file),
	\	"textDocument/completion",
	\	becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\ )

	return s:item_filter(l:res)
endfunction
"}}}
