""""
"" local variables
""""

"{{{
" log buffer name
let s:buf_name = "be-complete-log"

" vim buffer number of the log buffer
let s:buf_nr = -1
"}}}


""""
"" local functions
""""

"{{{
" \brief	create a string containing a variable name and its value
"
" \param	var_name	name of the vim variable to use
" \param	indent		string to prepent to the resulting string
"
" \return	string with the following format
"				a:indent a:var_name <a:var_name content>
function s:config_str(var_name, indent)
	exec "let l:val = " . a:var_name
	return a:indent . a:var_name . ": " . l:val
endfunction
"}}}
"
"{{{
" \brief	init the log buffer
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
	\	s:config_str("g:becomplete_key_goto", " "),
	\	s:config_str("g:becomplete_key_goto_preview_close", " "),
	\	s:config_str("g:becomplete_key_goto_preview_expand", " "),
	\	s:config_str("g:becomplete_key_symbol_all", " "),
	\	s:config_str("g:becomplete_key_symbol_functions", " "),
	\	s:config_str("g:becomplete_key_symbol_funchead", " "),
	\	"",
	\	s:config_str("g:becomplete_arg_mark_left", " "),
	\	s:config_str("g:becomplete_arg_mark_right", " "),
	\	"",
	\	s:config_str("g:becomplete_complete_fallback", " "),
	\	"",
	\	s:config_str("g:becomplete_goto_menu_always", " "),
	\	s:config_str("g:becomplete_goto_default", " "),
	\	s:config_str("g:becomplete_goto_preview_width", " "),
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
		\	. " timeout: " . l:cfg["timeout-ms"] . "ms"
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
" \brief	open the log buffer window
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
" \brief	put a message to the log buffer
"
" \param	msg		string to put
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
" \brief	print an error message both to the log buffer and as a vim
"			message
function becomplete#log#error(msg)
	call becomplete#log#msg("error: " . a:msg)

	echohl ErrorMsg
	echom "be-complete error: " . a:msg
endfunction
"}}}
