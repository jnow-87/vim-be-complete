" get own script ID
nmap <c-f11><c-f12><c-f13> <sid>
let s:sid = "<SNR>" . maparg("<c-f11><c-f12><c-f13>", "n", 0, 1).sid . "_"
nunmap <c-f11><c-f12><c-f13>


""""
"" local functions
""""

"{{{
" \brief	init the split preview window
function s:split_preview_init()
	" auto close the window
	autocmd BeComplete WinLeave <buffer> silent call s:split_preview_cleanup()

	" close window
	call util#map#n(g:becomplete_key_goto_preview_close, ":call " . s:sid . "split_preview_cleanup()<cr>", "<buffer>")

	" maximise
	call util#map#n(g:becomplete_key_goto_preview_expand, ":call util#window#expand()<cr>", "<buffer>")
endfunction
"}}}

"{{{
" \brief	undo s:split_preview_init() and close the preview window
function s:split_preview_cleanup()
	autocmd! BeComplete WinLeave <buffer>

	exec "nunmap <buffer> " . g:becomplete_key_goto_preview_close
	exec "nunmap <buffer> " . g:becomplete_key_goto_preview_expand

	silent! close
endfunction
"}}}

"{{{
" \brief	Focus the symbol at the given file and line.
"			Depending on the setting of s:goto_mode_split the symbol is shown
"			in a split preview window or in another tab. If the file doesn't
"			exist in a tab already, a new one is created.
"			If the file is rendered in the current tab the vim tag stack is
"			updated to allow returning to the current position.
"
" \param	file	file to goto
" \param	line	line to focus within a:file
function s:show(file, line)
	" ensure to be out of insert mode
	call feedkeys("\<esc>")

	if s:goto_mode_split == 0
		if bufnr(a:file) == bufnr()
			call util#tagstack#push_cursor()
		endif

		call util#window#focus_file(a:file, a:line, 1)

	else
		exec "rightbelow " . g:becomplete_goto_preview_width . "vsplit " . a:file
		exec a:line
		silent! foldopen

		call s:split_preview_init()
	endif
endfunction
"}}}

"{{{
" \brief	callback to handle the selection of an item from the goto menu
"			call s:show() for the selected entry
"
" \param	selection	dictionary describing the selected item, cf. help
"						v:completed_item
function s:select_hdlr(selection)
	iunmap <buffer> s
	iunmap <buffer> t

	if has_key(a:selection, "menu") && a:selection["menu"] != ""
		let [l:file, l:line] = split(a:selection["menu"], ':')
		call s:show(l:file, l:line)
	endif
endfunction
"}}}

"{{{
" \brief	Wrapper for setting s:goto_mode_split based on the given key. The
"			wrapper is supped to be used in mappings for popup menu item
"			selection.
"
" \param	key		goto mode, "s" for split mode "t" (or anything else) for
"					tab mode, cf. s:show()
function s:select(key)
	let s:goto_mode_split = (a:key == "s") ? 1 : 0

	return "\<c-y>"
endfunction
"}}}

"{{{
" \brief	Perform the goto based on the given items.
"			If the list of items contains more than one entry a popup menu
"			with them is shown.
"			If the list contains a single item it depends on
"			g:becomplete_goto_menu_always if either the item is focused or the
"			popup menu is still shown.
"			If the list is empty nothing is done.
"
" \param	items	list of dictionaries according to the s:item_filter() from
"					the plugin lsp layer
"
" \return	string to open a popup menu when used with a '<c-r>=' mapping
function s:goto(items)
	let s:goto_mode_split = (g:becomplete_goto_default == "split") ? 1 : 0
	let l:len = len(a:items)

	" handle empty list
	if l:len == 0
		return "\<esc>"
	endif

	" handle single-item list
	if l:len == 1 && g:becomplete_goto_menu_always == 0
		call s:show(a:items[0]["file"], a:items[0]["line"])

		return ""
	endif

	" generate item list for popup menu
	let l:word = expand("<cword>")
	let l:menu = []

	for l:item in a:items
		let l:menu += [{
		\	"menu": fnamemodify(l:item["file"], ":.") . ":" . l:item["line"],
		\	"kind": l:item["type"],
		\	"abbr": l:word,
		\ }]
	endfor

	call becomplete#util#sort(l:menu, "menu")

	" mappings for item selection
	call util#map#i("s", s:sid . "select('s')", "<buffer> <expr> noescape noinsert")
	call util#map#i("t", s:sid . "select('t')", "<buffer> <expr> noescape noinsert")

	" open menu
	return util#pmenu#open(l:menu, s:sid . "select_hdlr", "i", 1)
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	lsp goto wrapper
"
" \return	string triggering the goto menu
function becomplete#goto#decldef()
	let l:file = expand("%:p")
	let l:line = line(".")
	let l:col = col(".")
	let l:server = becomplete#server#get(l:file)

	call l:server["doc_update"](l:file)
	let l:defs = l:server["goto_def"](l:file, l:line, l:col)
	let l:decls = l:server["goto_decl"](l:file, l:line, l:col)

	return s:goto(l:defs + l:decls)
endfunction
"}}}
