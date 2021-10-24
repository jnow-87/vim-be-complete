""""
"" global variables
""""

"{{{
let g:becomplete_debug = get(g:, "becomplete_debug", 0)
"}}}


""""
"" local variables
""""

"{{{
let s:debug_buf_name = "be-complete-log"
let s:debug_buf_nr = -1
let s:debug_buf_height = 20
"}}}


""""
"" local functions
""""

"{{{
function s:init()
	if s:debug_buf_nr != -1
		return
	endif

	let s:debug_buf_nr = bufadd(s:debug_buf_name)
	let s:debug_buf_line = 0
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#debug#show()
	if g:becomplete_debug == 0
		echom "be-complete debug is disabled, cf. g:becomplete_debug"
		return
	endif

	call s:init()

	" open buffer in window
	exec "rightbelow " . s:debug_buf_height . "split"
	exec "silent edit " . s:debug_buf_name

	set filetype=text
	setlocal noswapfile
	setlocal bufhidden=hide
	setlocal nowrap
	setlocal buftype=nofile
	setlocal nobuflisted
	setlocal colorcolumn=0
	setlocal nomodifiable

	" auto-close if it is the last remaining window
	exec 'autocmd BeComplete BufEnter ' . s:debug_buf_name . ' silent if winnr("$") == 1 | quit | endif'
endfunction
"}}}

"{{{
function becomplete#debug#print(msg)
	if g:becomplete_debug == 0
		return
	endif

	call s:init()

	" append lines
	call setbufvar(s:debug_buf_nr, "&modifiable", 1)
	call appendbufline(s:debug_buf_nr, s:debug_buf_line, a:msg)
	let s:debug_buf_line += 1
	call setbufvar(s:debug_buf_nr, "&modifiable", 0)

	" move cursor to last line
	let l:win_id = bufwinid(s:debug_buf_nr)

	if l:win_id != -1
		call win_execute(l:win_id, [
		\		"call setpos('.', [0, " . line("$", l:win_id) . ", 1, 0])",
		\		"redraw"
		\ 	]
		\ )
	endif
endfunction
"}}}

"{{{
function becomplete#debug#error(msg)
	call becomplete#debug#print("error " . a:msg)
	echohl ErrorMsg
	echom "be-complete error: " . a:msg
endfunction
"}}}
