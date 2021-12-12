""""
"" global functions
""""

"{{{
" \brief	convert the given lsp response to a list if it isn't one already
"
" \param	response	response to convert
"
" \return	- empty list in case a:response is of the same type as v:null
"			- list containing a:response as the single element in case
"			  a:response is not a list
"			- a:response in case it is already a list
function becomplete#lsp#response#ensure_list(response)
	if type(a:response) == type(v:null)
		return []
	endif

	return (type(a:response) != type([])) ? [ a:response ] : a:response
endfunction
"}}}

"{{{
" \brief	parse an lsp uri out of a:response if it contains one
"
" \param	response	lsp response
" \param	key			key of the uri
"
" \return	content of the uri with the leading "scheme://" removed
"			an empty string if a:response doesn't contain a:key
function becomplete#lsp#response#uri(response, key="uri")
	let l:uri = get(a:response, a:key, "")

	return matchstr(l:uri, '.*://\zs.*\ze')
endfunction
"}}}

"{{{
" \brief	parse an lsp range out of response if it contains one
"
" \param	response	lsp response
" \param	key			key of the response 
"
" \return	- list with the following entries
"			  [start line, start column, end line, end column]
"			. [-1, -1, -1, -1] in case a:response doesn't contain a:key
function becomplete#lsp#response#range(response, key="range")
	if !has_key(a:response, a:key)
		return [ -1, -1, -1, -1 ]
	endif

	let l:range = a:response[a:key]

	return [
	\	l:range["start"]["line"] + 1,
	\	l:range["start"]["character"] + 1,
	\	l:range["end"]["line"] + 1,
	\	l:range["end"]["character"] + 1
	\ ]
endfunction
"}}}
