" get own script ID
nmap <c-f11><c-f12><c-f13> <sid>
let s:sid = "<SNR>" . maparg("<c-f11><c-f12><c-f13>", "n", 0, 1).sid . "_"
nunmap <c-f11><c-f12><c-f13>


""""
"" local functions
""""

"{{{
" \brief	Callback to handle the selection of an item from the symbol menu.
"			Focus the symbol and update the vim tag stack with the current
"			line.
"
" \param	selection	dictionary describing the selected item, cf. help
"						v:completed_item
function s:selected(selection)
	call becomplete#log#msg("goto: " . string(a:selection))

	if !len(a:selection) || a:selection["user_data"] == ""
		return
	endif

	call util#tagstack#push_cursor()
	call util#window#focus_line(a:selection["user_data"], 1)
endfunction
"}}}

"{{{
" \brief	lsp wrapper to get symbols for the current file
"
" \param	kinds	symbol kinds to include, according to
"					g:becomplete_kindsym_*
"
" \return	list with the symbols in the current file
function s:symbols(kinds)
	let l:file = expand("%:p")
	let l:server = becomplete#lsp#server#get(l:file)

	call l:server["doc_update"](l:file)
	let l:res = l:server["symbols"](l:file, a:kinds)

	return l:res
endfunction
"}}}

"{{{
" \brief	find the last symbol between the first and the current line
"
" \param	symbols		line-sorted list of symbols
" \param	key			key into a:symbols that shall be compared against the
"						current line number
"
" \return	index into a:symbols for the identified symbol
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
" \brief	create a popup menu for the given symbol kinds
"
" \param	kinds		symbol kinds to include, according to
"						g:becomplete_kindsym_*
" \param	closest		if 1 only the last symbol between the first and the
"						current line is included in the menu
"
" \return	string triggering a popup menu
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
" \brief	lsp symbol wrapper including all symbols in the document
"
" \return	string triggering the symbol menu
function becomplete#symbol#all()
	return s:menu([])
endfunction
"}}}

"{{{
" \brief	lsp symbol wrapper including only functions in the document
"
" \return	string triggering the symbol menu
function becomplete#symbol#functions()
	return s:menu([
	\	g:becomplete_kindsym_function,
	\	g:becomplete_kindsym_specialfunction,
	\ ])
endfunction
"}}}

"{{{
" \brief	lsp symbol wrapper including only the last function between the
"			first and the current line
"
" \return	string triggering the symbol menu
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
