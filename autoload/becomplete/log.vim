""""
"" local variables
""""

"{{{
let s:buf_name = "be-complete-log"
let s:buf_nr = -1
"}}}


""""
"" local functions
""""

"{{{
function s:config_str(var_name, indent)
	exec "let l:val = " . a:var_name
	return a:indent . a:var_name . ": " . l:val
endfunction
"}}}
"
"{{{
function s:init()
	if s:buf_nr != -1
		return
	endif

	" create init message
	let l:init_msg = [
	\	"    ::: be-complete configuration :::",
	\	"",
	\	s:config_str("g:becomplete_key_complete", " "),
	\	s:config_str("g:becomplete_key_complete_prev", " "),
	\	s:config_str("g:becomplete_key_arg_next", " "),
	\	s:config_str("g:becomplete_key_arg_prev", " "),
	\	"",
	\	s:config_str("g:becomplete_arg_mark_left", " "),
	\	s:config_str("g:becomplete_arg_mark_right", " "),
	\	"",
	\	s:config_str("g:becomplete_log_verbose", " "),
	\	"",
	\	" language servers",
	\ ]

	for l:cfg in g:becomplete_language_servers
		let l:init_msg += [
		\	"  " . l:cfg["command"][0] . ":"
		\	. " args: " . string(l:cfg["command"][1:])
		\	. " file-types: " . string(l:cfg["filetypes"])
		\	. " triggers: " . string(l:cfg["trigger"])
		\ ]
	endfor

	let l:init_msg += [ "", " file-type triggers" ]

	for l:ftype in keys(g:becomplete_language_triggers)
		let l:init_msg += [
		\	"  " . l:ftype . ": " . string(g:becomplete_language_triggers[l:ftype])
		\ ]
	endfor

	let l:init_msg += [
	\	"",
	\	"",
	\	"    ::: log :::",
	\	""
	\ ]

	" init log buffer
	let s:buf_nr = bufadd(s:buf_name)
	exec "silent call bufload(" . s:buf_nr . ")"
	call appendbufline(s:buf_nr, 0, l:init_msg)
	let s:buf_line = len(l:init_msg)
endfunction
"}}}


""""
"" global functions
""""

"{{{
function becomplete#log#show()
	if g:becomplete_log_verbose == 0
		echom "be-complete logging is disabled, cf. g:becomplete_log_verbose"
		return
	endif

	call s:init()

	" display and configure buffer
	exec "rightbelow " . (&lines / 5) . "split"
	exec "silent edit " . s:buf_name

	setlocal filetype=text
	setlocal noswapfile
	setlocal bufhidden=hide
	setlocal nowrap
	setlocal buftype=nofile
	setlocal nobuflisted
	setlocal colorcolumn=0
	setlocal nomodifiable

	syntax match StatusLine "^\s\+\zs::: .\+ :::"
	syntax match Error "^error:"

	highlight link becomplete_arg None

	" auto-close if it is the last remaining window
	exec 'autocmd BeComplete BufEnter ' . s:buf_name . ' silent if winnr("$") == 1 | quit | endif'
endfunction
"}}}

"{{{
function becomplete#log#msg(msg)
	if g:becomplete_log_verbose == 0
		return
	endif

	call s:init()

	" append lines
	call setbufvar(s:buf_nr, "&modifiable", 1)
	call appendbufline(s:buf_nr, s:buf_line, a:msg)
	let s:buf_line += 1
	call setbufvar(s:buf_nr, "&modifiable", 0)

	" move cursor to last line
	let l:win_id = bufwinid(s:buf_nr)

	if l:win_id != -1
		call win_execute(l:win_id, ["$", "redraw"])
	endif
endfunction
"}}}

"{{{
function becomplete#log#error(msg)
	call becomplete#log#msg("error: " . a:msg)

	echohl ErrorMsg
	echom "be-complete error: " . a:msg
endfunction
"}}}
