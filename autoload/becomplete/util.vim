""""
"" local functions
""""

"{{{
function s:compare(item0, item1) dict
	let l:key = self["key"]

	return (a:item0[l:key] >= a:item1[l:key]) ? 1 : -1
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#util#sort(dict, key)
	call sort(a:dict, "s:compare", { "key": a:key })
endfunction
"}}}
