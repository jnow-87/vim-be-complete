""""
"" global functions
""""

"{{{
function becomplete#lsp#response#ensure_list(response)
	return (type(a:response) == type({})) ? [ a:response ] : a:response
endfunction
"}}}

"{{{
function becomplete#lsp#response#uri(response)
	let l:uri = get(a:response, "uri", "")

	return matchstr(l:uri, '.*://\zs.*\ze')
endfunction
"}}}

"{{{
function becomplete#lsp#response#range(response)
	if !has_key(a:response, "range")
		return [ -1, -1, -1, -1 ]
	endif

	let l:range = a:response["range"]

	return [
	\	l:range["start"]["line"] + 1,
	\	l:range["start"]["character"] + 1,
	\	l:range["end"]["line"] + 1,
	\	l:range["end"]["character"] + 1
	\ ]
endfunction
"}}}
