""""
"" local functions
""""

"{{{
" \brief	isolate function arguments from the given string
" 			the arguments are assumed to be enclosed in "()"
"
" \param	str		string to check for function arguments
"
" \return	the identified arguments or an empty string if
"			none could be found
function s:default_func_args(str)
	return becomplete#util#strrpair(a:str, "()")[0]
endfunction
"}}}

"{{{
" \brief	func_args callback for go, cf. s:default_func_args()
" 			for the specification
function s:go_func_args(str)
	" The go function signature uses "()" to enclose the arguments but also
	" allows them to surround the return type. Hence, try to identify two pairs
	" and return the appropriate one, depending on how many have been found.
	let [l:return_type, l:idx] = becomplete#util#strrpair(a:str, "()")

	if l:idx == -1
		return ""
	endif

	let [l:func_args, l:idx] = becomplete#util#strrpair(a:str, "()", l:idx)

	if l:idx == -1
		return l:return_type
	endif

	return l:func_args
endfunction
"}}}

"{{{
" \brief	identify the callback for a:func based on a:filetypes
"
" \param	func		function name to look for
" \param	filetypes	list of file types
"
" \return	pointer to the function for the first file type that has
" 			a defined function, if there are no functions for any of
" 			the file types the default function pointer is returned
function s:callback(func, filetypes)
	for l:ft in a:filetypes
		let l:name = "s:" . l:ft . "_" . a:func

		if exists("*" . l:name)
			return function(l:name)
		endif
	endfor

	return function("s:default_" . a:func)
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	return a dictionary that contains the callbacks for
"			language specific functions
"
" \param	filetypes	file types that shall be handled by the
" 						callbacks
"
" \return	dict mapping callback name to function pointer
function becomplete#lang#calls(filetypes)
	return {
	\	"func_args": s:callback("func_args", a:filetypes),
	\ }
endfunction
"}}}
