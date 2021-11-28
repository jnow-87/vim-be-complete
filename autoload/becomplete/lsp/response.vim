""""
"" global functions
""""

"{{{
function becomplete#lsp#response#unavail_list(...)
	return []
endfunction
"}}}

"{{{
function becomplete#lsp#response#ensure_list(response)
	if type(a:response) == type(v:null)
		return []
	endif

	return (type(a:response) != type([])) ? [ a:response ] : a:response
endfunction
"}}}

"{{{
function becomplete#lsp#response#uri(response, key="uri")
	let l:uri = get(a:response, a:key, "")

	return matchstr(l:uri, '.*://\zs.*\ze')
endfunction
"}}}

"{{{
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