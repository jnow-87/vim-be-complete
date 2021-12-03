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
