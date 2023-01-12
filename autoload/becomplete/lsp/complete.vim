""""
"" local variables
""""

"{{{
" string representations for the lsp completion item kinds
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
" \brief	Isolate a function signature from the given string.
"			The signature is assumed to be found as the last part of the
"			string, i.e. the string has to end on ")"
"
" \param	str		string to check for a signature
"
" \return	the identified signature or an empty string of no signature could
"			be found
function s:signature(str)
	if a:str[-1:-1] != ")"
		return ""
	endif

	let l:i = len(a:str) - 2
	let l:nbrackets = 0

	" iterate through string, looking for the signature opening bracket
	while l:i > 0
		if a:str[l:i] == "("
			if l:nbrackets == 0
				return a:str[l:i:]
			endif

			let l:nbrackets -= 1

		elseif a:str[l:i] == ")"
			let l:nbrackets += 1
		endif

		let l:i -= 1
	endwhile

	return ""
endfunction
"}}}

"{{{
" \brief	Convert the lsp completion items to a list of dictionaries with
"			the word, kind, menu and dup keys according to vim complete-items.
"			The "user_data" key is used for function signature information.
"
" \param	response	result of the lsp completion request
" \param	line		line number of the completion
" \param	column		column relative to a:line
"
" \return	list of vim completion items
function s:item_filter(response, line, column)
	let l:items = (type(a:response) == type(v:null)) ? [] : get(a:response, "items", a:response)
	let l:lst = []
	let l:word = becomplete#util#word_at(bufname(), a:line, a:column)
	let l:wlen = len(l:word) - 1

	call becomplete#log#msg(printf("%20.20s %10.10s %10.10s %25.25s %10.10s %15.15s %6.6s %10.10s %s %s",
	\	"label", "kind", "detail", "ldetail", "insert", "command", "select", "data", "docu", "edit")
	\ )

	for l:item in l:items
		let l:label = trim(get(l:item, "label", ""), " ")
		let l:ldetail = get(l:item, "labelDetails", {})
		let l:ldetail_descr = get(l:ldetail, "description", "")
		let l:ldetail = get(l:ldetail, "detail", "")
		let l:detail = get(l:item, "detail", "")
		let l:kind = s:complete_kinds[get(l:item, "kind", 0)]
		let l:docu = get(l:item, "documentation", "")
		let l:select = get(l:item, "preselect", "")
		let l:cmd = get(l:item, "command", "")
		let l:data = get(l:item, "data", "")
		let l:edit = get(l:item, "textEdit", "")
		let l:edit = get(l:item, "textEdit", {})
		let l:insert = get(l:edit, "newText", get(l:item, "insertText", ""))

		let l:signature = s:signature(l:label)
		if l:signature == "" | let l:signature = s:signature(l:detail) | endif

		" skip items that don't start with the word under the cursor
		if l:word != "" && l:insert[0:l:wlen] !=# l:word
			continue
		endif

		" remove non-ascii characters sent by some language servers
		" e.g. clangd-14 prepends some labels with •
		let l:label = substitute(l:label, "[^[:graph:] ]", "", "g")

		call becomplete#log#msg(printf("%20.20s %10.10s %10.10s %10.10s %14.14s %10.10s %15.15s %6.6s %10.10s %s %s",
		\	l:label, l:kind, l:detail, l:ldetail, l:ldetail_descr, l:insert, l:cmd, l:select, l:data, l:docu, l:edit)
		\ )

		call add(l:lst, {
		\		"word": l:insert,
		\		"kind": l:kind,
		\		"menu": l:detail . " " . l:label,
		\		"user_data": l:signature,
		\		"dup": 1,
		\	}
		\ )
	endfor

	return l:lst
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	lsp completion wrapper
"
" \param	file	file name to do the completion for
" \param	line	line within a:file
" \param	column	column within a:line
"
" \return	list of vim completion items, cf. s:item_filter()
function becomplete#lsp#complete#completion(file, line, column)
	call becomplete#log#msg("completion for " . a:file . ":" . a:line . ":" . a:column)

	let l:res = becomplete#lsp#base#request(
	\	becomplete#server#get(a:file),
	\	"textDocument/completion",
	\	becomplete#lsp#param#doc_pos(a:file, a:line, a:column)
	\ )

	return s:item_filter(l:res, a:line, a:column)
endfunction
"}}}
