if exists('g:loaded_becomplete') || &compatible
	finish
endif

let g:loaded_becomplete = 1


""""
"" global variables
""""

let g:becomplete_language_servers = get(g:, "becomplete_language_servers", [])
let g:becomplete_key_complete = get(g:, "becomplete_key_complete", "<tab>")
let g:becomplete_key_complete_prev = get(g:, "becomplete_key_complete_prev", "<s-tab>")
let g:becomplete_key_arg_next = get(g:, "becomplete_key_arg_next", "<c-n>")
let g:becomplete_key_arg_prev = get(g:, "becomplete_key_arg_prev", "<c-p>")
let g:becomplete_arg_mark_left = "`<"
let g:becomplete_arg_mark_right = ">`"
let g:becomplete_language_triggers = {}


""""
"" local functions
""""

"{{{
function s:init()
	" create BeComplete autocmd group
	augroup BeComplete
	augroup END

	" register servers
	for l:cfg in g:becomplete_language_servers
		call becomplete#lsp#server#register(l:cfg["command"], l:cfg["filetypes"])

		for l:ftype in l:cfg["filetypes"]
			let g:becomplete_language_triggers[l:ftype] = l:cfg["trigger"]
		endfor
	endfor
endfunction
"}}}

"{{{
function s:init_buffer()
	" function argument highlighting
	exec "syn region becomplete_arg matchgroup=None "
	\	. "start='" . g:becomplete_arg_mark_left
	\	. "' end='" . g:becomplete_arg_mark_right
	\	. "' concealends"

	" user-triggered completion
	call util#map#i(g:becomplete_key_complete,
	\	"<c-r>=becomplete#complete#on_user()<cr>",
	\	"<buffer> noescape noinsert"
	\ )

	call util#map#i(g:becomplete_key_complete_prev,
	\	"pumvisible() ? '\<c-p>' : '" . g:becomplete_key_complete_prev . "'",
	\	"<buffer> <expr> noescape noinsert"
	\ )

	call util#map#i("<cr>", "pumvisible() ? '\<c-y>' : '<cr>'", "<buffer> <expr> noescape noinsert")
	call util#map#i("<up>", "pumvisible() ? '\<c-p>' : '<up>'", "<buffer> <expr> noescape noinsert")
	call util#map#i("<down>", "pumvisible() ? '\<c-n>' : '<down>'", "<buffer> <expr> noescape noinsert")

	" language-specific completion
	for l:seq in get(g:becomplete_language_triggers, getbufvar("", "&filetype"), [])
		let l:key = l:seq[-1:]
		call util#map#i(l:key,
		\	"<c-r>=becomplete#complete#on_key('" . l:key . "', '" . l:seq . "')<cr>",
		\	"<buffer> noescape noinsert"
		\ )
	endfor

	" function argument selection
	call util#map#nvi(g:becomplete_key_arg_next, "<esc>:call becomplete#complete#arg_select(1)<cr>", "<buffer>")
	call util#map#nvi(g:becomplete_key_arg_prev, "<esc>:call becomplete#complete#arg_select(0)<cr>", "<buffer>")

	" select the first function argument upson completion
	" "<esc><right>" is required to avoid ending up in "insert select" mode
	autocmd BeComplete CompleteDone <buffer>
	\	if becomplete#complete#arg_select(1) == 0 | call feedkeys("\<esc>\<right>") | endif
endfunction
"}}}


""""
"" init
""""

call s:init()


""""
"" commands
""""

"{{{
command -nargs=0 BeCompleteDebug let g:becomplete_debug = 1 | call becomplete#debug#show()
"}}}


""""
"" autocommands
""""

"{{{
autocmd BeComplete VimLeave * silent call becomplete#lsp#server#stop_all()
autocmd BeComplete FileType * silent call s:init_buffer()
"}}}
