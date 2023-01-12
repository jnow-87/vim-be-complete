""""
"" local functions
""""

"{{{
" \brief	compare two items based on the key given in the associated
"			dictionary's "key" member
"
" \param	item0	1st item
" \param	item1	2nd item
"
" \return	- 1 if the "key" in item0 is greater or equal to the respective key
"			  in item1
"			- -1 otherwise
function s:compare(item0, item1) dict
	let l:key = self["key"]

	return (a:item0[l:key] >= a:item1[l:key]) ? 1 : -1
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	sort the given dictionary based on a:key
"
" \param	dict	dictionary to sort
" \param	key		key contained in a:dict to sort by
function becomplete#util#sort(dict, key)
	call sort(a:dict, "s:compare", { "key": a:key })
endfunction
"}}}

"{{{
" \brief	get buffer content as a single string
"
" \param	file	file to gather content for
"
" \return	String containing the buffer lines associated with a:file. Lines
"			are joined using a newline character.
function becomplete#util#buftext(file)
	return join(getbufline(a:file, 1, '$'), "\n")."\n"
endfunction
"}}}

"{{{
" \brief	find the index in a string which is the base of the word at a:idx
"
" \param	line	string to search in
" \param	idx		index into a:line where to start searching
"
" \return	index into a:line indicating the start of the word
function becomplete#util#word_base(line, idx)
    let l:start = a:idx - 1

    while l:start > 0 && a:line[l:start - 1] =~ '\i\|\k'
      let l:start -= 1
    endwhile

    return l:start
endfunction
"}}}

"{{{
" \brief	return the word at the given file location
"
" \param	file	file name
" \param	line	line number
" \param	column	column number
"
" \return	word at the given location
function becomplete#util#word_at(file, line, column)
	let l:line = get(getbufline(a:file, a:line), 0, "")
	let l:start = becomplete#util#word_base(l:line, a:column)
	let l:end = l:start

    while l:line[l:end + 1] =~ '\i\|\k'
      let l:end += 1
    endwhile

	if l:line[l:end] !~ '\i\|\k'
		return ""
	endif

	return l:line[l:start:l:end]
endfunction
"}}}

"{{{
" \brief	return the current file's name
"
" \param	in_autocmd	define if the function is called from an autocmd
"
" \return	expanded and resolved file name
function becomplete#util#curfile(in_autocmd=0)
	return resolve(expand((a:in_autocmd ? "<afile>" : "%") . ":p"))
endfunction
"}}}

"{{{
" \brief	reversely searching a string enclosed in the characters specified
" 			in a:pair resolving nesting of those characters
"
" \param	str		string to search
" \param	pair	two-character string with a:pair[0] being the left-
" 					and a:pair[1] being the right-hand side
" \param	start	index to start looking for the left side of the pair
"
" \return	list with
" 			[0]: string that contains the sub-string which is enclosed in
" 				 the given pair, including the left- and right-hand side
" 				 of the pair
" 			[1]: character index of the left-hand side  in a:str, -1 if
" 				 no matching left-hand side has been found
function becomplete#util#strrpair(str, pair, start=len(a:str)-1)
	let l:end = strridx(a:str, a:pair[1], a:start)

	if l:end == -1
		return ["", -1]
	endif

	let l:i = l:end - 1
	let l:nest = 0

	while l:i > 0
		if a:str[l:i] == a:pair[0]
			if l:nest == 0
				return [a:str[l:i:l:end], l:i]
			endif

			let l:nest -= 1

		elseif a:str[l:i] == a:pair[1]
			let l:nest += 1
		endif

		let l:i -= 1
	endwhile

	return ["", -1]
endfunction
"}}}
