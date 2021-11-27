" get own script ID
nmap <c-f11><c-f12><c-f13> <sid>
let s:sid = "<SNR>" . maparg("<c-f11><c-f12><c-f13>", "n", 0, 1).sid . "_"
nunmap <c-f11><c-f12><c-f13>


""""
"" local functions
""""

"{{{
function s:selected(selection)
	call becomplete#log#msg("goto: " . string(a:selection))

	if !len(a:selection) || a:selection["user_data"] == ""
		return
	endif

	call util#window#focus_line(a:selection["user_data"], 1)
endfunction
"}}}

"{{{
function s:symbols(kinds)
	let l:file = expand("%:p")
	let l:server = becomplete#lsp#server#get(l:file)

	call becomplete#lsp#document#open(l:file)
	let l:res = l:server["symbols"](l:file, a:kinds)
	call becomplete#lsp#document#close(l:file)

	return l:res
endfunction
"}}}

"{{{
function s:find_closest(symbols, key)
	let l:line = line(".")
	let l:idx = 0

	for l:sym in a:symbols
		if l:sym[a:key] <= l:line
			let l:idx += 1
		endif
	endfor

	return l:idx
endfunction
"}}}

"{{{
function s:menu(kinds, closest=0)
	let l:items = []

	for l:sym in s:symbols(a:kinds)
		let l:items += [{
		\	"word": "",
		\	"abbr": l:sym["name"],
		\	"kind": l:sym["kind"],
		\	"menu": l:sym["detail"],
		\	"user_data": l:sym["line"],
		\ }]
	endfor

	call becomplete#util#sort(l:items, "user_data")
	let l:idx = s:find_closest(l:items, "user_data")

	if a:closest != 0
		let l:items = l:idx > 0 ? [l:items[l:idx - 1]] : []
		let l:idx = 1
	endif

	return util#pmenu#open(l:items, s:sid . "selected", "i", l:idx)
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#symbol#all()
	return s:menu([])
endfunction
"}}}

"{{{
function becomplete#symbol#functions()
	return s:menu([
	\	g:becomplete_kindsym_function,
	\	g:becomplete_kindsym_specialfunction,
	\ ])
endfunction
"}}}

"{{{
function becomplete#symbol#function_head()
	return s:menu(
	\	[
	\		g:becomplete_kindsym_function,
	\		g:becomplete_kindsym_specialfunction,
	\	],
	\	1
	\ )
endfunction
"}}}
