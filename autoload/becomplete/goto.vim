" get own script ID
nmap <c-f11><c-f12><c-f13> <sid>
let s:sid = "<SNR>" . maparg("<c-f11><c-f12><c-f13>", "n", 0, 1).sid . "_"
nunmap <c-f11><c-f12><c-f13>


""""
"" local functions
""""

"{{{
function s:split_preview_init()
	autocmd BeComplete WinLeave <buffer> silent call s:split_preview_cleanup()

	call util#map#n(g:becomplete_key_goto_preview_close, ":call " . s:sid . "split_preview_cleanup()<cr>", "<buffer>")
	call util#map#n(g:becomplete_key_goto_preview_expand, ":call util#window#expand()<cr>", "<buffer>")
endfunction
"}}}

"{{{
function s:split_preview_cleanup()
	autocmd! BeComplete WinLeave <buffer>

	exec "nunmap <buffer> " . g:becomplete_key_goto_preview_close
	exec "nunmap <buffer> " . g:becomplete_key_goto_preview_expand

	silent! close
endfunction
"}}}

"{{{
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
function s:select(key)
	let s:goto_mode_split = (a:key == "s") ? 1 : 0

	return "\<c-y>"
endfunction
"}}}

"{{{
" \return	'<c-r>=' string, triggering auto completion
function s:goto(items)
	let s:goto_mode_split = (g:becomplete_goto_default == "split") ? 1 : 0
	let l:len = len(a:items)

	if l:len == 0
		return "\<esc>"
	endif

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

"{{{
function s:parse_items(items, type)
	let l:lst = []

	for l:item in a:items
		let l:file = becomplete#lsp#response#uri(l:item)
		let l:line = becomplete#lsp#response#range(l:item)[0]

		if l:file == "" || l:line == -1
			continue
		endif

		let l:lst += [{ "file": l:file, "line": l:line, "type": a:type }]
	endfor

	return l:lst
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#goto#decldef()
	let l:file = expand("%:p")
	let l:line = line(".")
	let l:col = col(".")
	let l:server = becomplete#lsp#server#get(l:file)

	call becomplete#lsp#document#open(l:file)
	let l:defs = l:server["goto_def"](l:file, l:line, l:col)
	let l:decls = l:server["goto_decl"](l:file, l:line, l:col)
	call becomplete#lsp#document#close(l:file)

	return s:goto(
	\	s:parse_items(l:defs, "def")
	\	+ s:parse_items(l:decls, "decl")
	\ )
endfunction
"}}}
