""""
"" local functions
""""

"{{{
" \brief	annotate function signature arguments with markers to jump between
"			the arguments
"
" \param	signature		string containing a function signature, i.e.
"							starting on '(' and ending on ')'
"
" \return	annotated string
function s:annotate_signature(sig)
	let l:sig = a:sig[1:-2]

	" return on invalid signature format
	if a:sig[0] != "(" || a:sig[-1:-1] != ")"
		return ""
	endif

	" return on empty signature
	" remove closing ')' to be consistent with annotated signatures
	if len(l:sig) == 0
		return "("
	endif

	" surround function arguments with markers
	let l:braces = 0
	let l:in_arg = 1
	let l:anno = "(" . g:becomplete_arg_mark_left

	for l:i in range(0, len(l:sig))
		let l:c = l:sig[l:i]

		" allow brace pairs inside arguments
		let l:braces += (l:c == "(") ? 1 : 0
		let l:braces += (l:c == ")") ? -1 : 0

		" start of an argument
		if l:c != " " && l:c != "\t" && l:in_arg == 0
			let l:anno .= g:becomplete_arg_mark_left
			let l:in_arg = 1
		endif

		" end of an argument
		if l:c == "," && l:braces == 0
			let l:anno .= g:becomplete_arg_mark_right
			let l:in_arg = 0
		endif

		" add current character
		let l:anno .= l:c
	endfor

	return l:anno . g:becomplete_arg_mark_right
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	user-triggered lsp completion wrapper
"
" \return	string to be used with an "<c-r>=" mapping
function becomplete#complete#user()
	if pumvisible()
		return "\<c-n>"
	endif

	let l:file = expand("%:p")
	let l:server = becomplete#server#get(l:file)

	let l:char = getline('.')[col(".") - 2]

	" abort completion
	if l:char == " " || l:char == "\t" || l:char == ""
		return util#map#escape(g:becomplete_key_complete)
	endif

	" lsp or fallback completion
	if l:server["initialised"] == 1 && becomplete#server#supports(l:server, "complete")
		call l:server["doc_update"](l:file)
		let l:items = l:server["complete"](l:file, line("."), col("."))
		call complete(becomplete#util#word_base(getline("."), col(".")) + 1, l:items)

		return ""

	else
		return util#map#escape(g:becomplete_complete_fallback)
	endif
endfunction
"}}}

"{{{
" \brief	trigger completion if a:key completes a:seq
"
" \param	key		typed key
" \param	seq		string with a trigger sequence
"
" \return	a:key
function becomplete#complete#key(key, seq)
	let l:line = getline(".")
	let l:col = col(".")

	if a:key == a:seq || l:line[l:col - len(a:seq):l:col - 2] . a:key == a:seq
		call feedkeys(util#map#escape(g:becomplete_key_complete))
	endif

	return a:key
endfunction
"}}}

"{{{
" \brief	Annotates a function signature if available, assuming the
"			completion item's "user_data" key contains signature information.
"			If a signature is present, the first argument of the function is
"			selected.
function becomplete#complete#done()
	let l:signature = s:annotate_signature(get(v:completed_item, "user_data", ""))

	if l:signature == ""
		return
	endif

	" insert signature
	exec "normal! i" . l:signature

	" select the first function argument upon completion "<esc>" is required
	" to avoid ending up in "insert select" mode
	if becomplete#complete#signature_select(1) == 0
		call feedkeys("\<esc>")
	endif

	call feedkeys("\<right>")
endfunction
"}}}

"{{{
" \brief	highlight a string in the current line surrounded by function
"			argument markers as annotated by
"			s:becomplete#complete#arg_annotate()
"
" \param	forward		1 to select the next argument
"						otherwise select the previous argument
"
" \return	0 an argument has been highlighted
"			-1 otherwise
function becomplete#complete#signature_select(forward)
	let l:line = getline('.')
	let l:llen = len(line)
	let l:col = col('.')

	" find next argument, surrounded by markers
	if a:forward == 1
		let l:col = (l:col >= l:llen) ? 1 : l:col - 1

		let l:left = stridx(l:line, g:becomplete_arg_mark_left, l:col)
		let l:right = stridx(l:line, g:becomplete_arg_mark_right, l:left)

	else
		let l:right = strridx(l:line, g:becomplete_arg_mark_right, l:col - len(g:becomplete_arg_mark_right) - 1)
		let l:right = (l:right == -1) ? strridx(l:line, g:becomplete_arg_mark_right, l:llen) : l:right
		let l:left = strridx(l:line, g:becomplete_arg_mark_left, l:right)
	endif

	" select argument
	if l:left != -1 && l:right != -1
		call cursor(0, l:left + 1)
		exec "normal v" . (l:right + len(g:becomplete_arg_mark_right) - l:left - 1) . "l\<c-g>"

		return 0
	endif

	return -1
endfunction
"}}}
