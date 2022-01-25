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
