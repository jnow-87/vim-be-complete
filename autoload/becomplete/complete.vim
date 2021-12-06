""""
"" local functions
""""

"{{{
" \brief	callback to handle the result of an lsp completion request and
"			show a popup menu
"
" \param	items	list with vim complete-items
function s:completion_hdlr(items)
	call complete(becomplete#complete#find_start() + 1, a:items)
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	find the column in the current line which is the base of the
"			completion, i.e. the beginning of the word under the cursor
"
" \return	column indicating the completion start
function becomplete#complete#find_start()
    let l:line = getline('.')
    let l:start = col('.') - 1

    while l:start > 0 && l:line[l:start - 1] =~ '\i\|\k'
      let l:start -= 1
    endwhile

    return l:start
endfunction
"}}}

"{{{
" \brief	annotate function signature arguments with markers to jump between
"			the arguments
"
" \param	str		string to annotate
"
" \return	annotated string
function becomplete#complete#arg_annotate(str)
	" locate signature in a:str
	let l:sig_start = stridx(a:str, "(")
	let l:sig_end = strridx(a:str, ")")
	let l:sig = a:str[l:sig_start + 1:l:sig_end - 1]

	" return if no or empty signature found
	" remove trailing ')' to be consistent with amended signatures
	if l:sig_start == -1 || l:sig_end == -1 || len(l:sig) == 0
		return a:str[-1:-1] == ')' ? a:str[:-2] : a:str
	endif

	" surround function arguments with markers
	let l:braces = 0
	let l:in_arg = 1
	let l:anno = a:str[0:l:sig_start] . g:becomplete_arg_mark_left

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
function becomplete#complete#arg_select(forward)
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

"{{{
" \brief	user-triggered lsp completion wrapper
"
" \return	string to be used with an "<c-r>=" mapping
function becomplete#complete#on_user()
	if pumvisible()
		return "\<c-n>"
	endif

	let l:file = expand("%:p")
	let l:server = becomplete#lsp#server#get(l:file)

	let l:char = getline('.')[col(".") - 2]

	" abort completion
	if l:char == " " || l:char == "\t" || l:char == ""
		return util#map#escape(g:becomplete_key_complete)
	endif

	" lsp or fallback completion
	if l:server["initialised"] == 1
		let l:file = expand("%:p")

		call becomplete#lsp#document#open(l:file)
		call s:completion_hdlr(l:server["complete"](l:file, line("."), col("."), function("s:completion_hdlr")))
		call becomplete#lsp#document#close(l:file)

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
function becomplete#complete#on_key(key, seq)
	let l:line = getline(".")
	let l:col = col(".")

	if a:key == a:seq || l:line[l:col - len(a:seq):l:col - 2] . a:key == a:seq
		call feedkeys(util#map#escape(g:becomplete_key_complete))
	endif

	return a:key
endfunction
"}}}
