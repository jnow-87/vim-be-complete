if exists('g:loaded_becomplete') || &diff || &compatible
	finish
endif

let g:loaded_becomplete = 1


""""
"" configuration variables
""""

"{{{
" key bindings
let g:becomplete_key_complete = get(g:, "becomplete_key_complete", "<tab>")
let g:becomplete_key_complete_prev = get(g:, "becomplete_key_complete_prev", "<s-tab>")
let g:becomplete_key_arg_next = get(g:, "becomplete_key_arg_next", "<c-n>")
let g:becomplete_key_arg_prev = get(g:, "becomplete_key_arg_prev", "<c-p>")
let g:becomplete_key_goto = get(g:, "becomplete_key_goto", "gt")
let g:becomplete_key_goto_preview_close = get(g:, "becomplete_key_goto_preview_close", "q")
let g:becomplete_key_goto_preview_expand = get(g:, "becomplete_key_goto_preview_expand", "x")
let g:becomplete_key_symbol_all = get(g:, "becomplete_key_symbol_all", "ls")
let g:becomplete_key_symbol_functions = get(g:, "becomplete_key_symbol_functions", "lf")
let g:becomplete_key_symbol_funchead = get(g:, "becomplete_key_symbol_funchead", "lh")

" markers for function argument selection
let g:becomplete_arg_mark_left = "`<"
let g:becomplete_arg_mark_right = ">`"

" vim completion key sequence to use when no language server is available
let g:becomplete_complete_fallback = get(g:, "becomplete_complete_fallback", "<c-n>")

" use the g:becomplete_complete_fallback sequence also if the language server
" returns no completion items
let g:becomplete_complete_fallback_on_empty = get(g:, "becomplete_complete_fallback_on_empty", 0)

" always show a menu for goto commands, even if a single item will be shown
let g:becomplete_goto_menu_always = get(g:, "becomplete_goto_menu_always", 1)

" default mode to use for viewing goto targets
"	either "split" or "tab"
let g:becomplete_goto_default = get(g:, "becomplete_goto_default", "split")

" width of the goto preview window
let g:becomplete_goto_preview_width = get(g:, "becomplete_goto_preview_width", (&columns / 5))

" strings used as the kind key in menus, such as the completion or symbol menu
let g:becomplete_kindsym_undef = get(g:, "becomplete_kindsym_undef", "?")
let g:becomplete_kindsym_type = get(g:, "becomplete_kindsym_type", "t")
let g:becomplete_kindsym_namespace = get(g:, "becomplete_kindsym_namespace", ":")
let g:becomplete_kindsym_function = get(g:, "becomplete_kindsym_function", "f")
let g:becomplete_kindsym_specialfunction = get(g:, "becomplete_kindsym_specialfunction", "~")
let g:becomplete_kindsym_member = get(g:, "becomplete_kindsym_member", "m")
let g:becomplete_kindsym_variable = get(g:, "becomplete_kindsym_variable", "v")
let g:becomplete_kindsym_macro = get(g:, "becomplete_kindsym_macro", "d")
let g:becomplete_kindsym_file = get(g:, "becomplete_kindsym_file", "i")
let g:becomplete_kindsym_text = get(g:, "becomplete_kindsym_text", "s")

let g:becomplete_type_declaration = get(g:, "becomplete_type_declaration", "dcl")
let g:becomplete_type_definition = get(g:, "becomplete_type_definition", "def")

" dictionary of languages the ctags server shall be used for
" structure
" 	<language>: {
" 		"recursive": <0 | 1>	index all files of that kind during initialisation
" 	}
let g:becomplete_ctags_languages = get(g:, "becomplete_ctags_languages", [])
"}}}


""""
"" global variables
""""

"{{{
" list of language server configurations each with the following keys:
"	command: list of strings representing the language server binary and its
"			 command line arguments
"	filetypes: list of vim file type strings the server supports
"	timeout-ms: timeout for synchronous request in milliseconds
"	trigger: list of strings which trigger a completion request when typed
let g:becomplete_language_servers = get(g:, "becomplete_language_servers", [])

" mapping from vim file types to completion request triggers
let g:becomplete_language_triggers = {}
"}}}


""""
"" local functions
""""

"{{{
" \brief	plugin init
function s:init()
	" create BeComplete autocmd group
	augroup BeComplete
	augroup END

	" register servers
	for l:cfg in g:becomplete_language_servers
		call becomplete#server#register(l:cfg["command"], l:cfg["filetypes"], l:cfg["timeout-ms"])

		for l:ftype in l:cfg["filetypes"]
			let g:becomplete_language_triggers[l:ftype] = l:cfg["trigger"]
		endfor
	endfor
endfunction
"}}}

"{{{
" \brief	buffer initialisation
"
" \param	file	file name
function s:buffer_init(file)
	let l:ftype = getbufvar(a:file, "&filetype")
	let l:server = becomplete#server#start(l:ftype)

	if l:server["initialised"] == 1
		call l:server["doc_open"](a:file)

		" function argument highlighting
		exec "syn region becomplete_arg matchgroup=None "
		\	. "start='" . g:becomplete_arg_mark_left
		\	. "' end='" . g:becomplete_arg_mark_right
		\	. "' concealends"

		" language-specific completion triggers
		for l:seq in get(g:becomplete_language_triggers, l:ftype, [])
			let l:key = l:seq[-1:]
			call util#map#i(l:key,
			\	"<c-r>=becomplete#complete#key('" . l:key . "', '" . l:seq . "')<cr>",
			\	"<buffer> noescape noinsert"
			\ )
		endfor
	endif
endfunction
"}}}

"{{{
" \brief	buffer cleanup
"
" \param	file	file name
function s:buffer_unload(file)
	let l:server = becomplete#server#get(a:file)
	call l:server["doc_close"](a:file)
endfunction
"}}}

"{{{
" \brief	signal buffer modification
"
" \param	file	file name
function s:buffer_modified(file)
	let l:server = becomplete#server#get(a:file)
	call l:server["doc_update"](a:file)
	call l:server["doc_write"](a:file)
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
command -nargs=0 BeCompleteLog call becomplete#log#show()
command -nargs=0 BeCompleteCtagsSymtab call becomplete#ctags#symtab#print()
"}}}


""""
"" autocommands
""""

"{{{
" buffer control
autocmd BeComplete FileType * call s:buffer_init(becomplete#util#curfile(1))
autocmd BeComplete BufUnload * call s:buffer_unload((becomplete#util#curfile(1)))
autocmd BeComplete BufWritePost * call s:buffer_modified((becomplete#util#curfile(1)))

" shutdown
autocmd BeComplete VimLeave * call becomplete#server#stop_all()

" completion handler
autocmd BeComplete CompleteDone * call becomplete#complete#done()
"}}}


""""
"" mappings
""""

"{{{
" user-triggered completion
call util#map#i(g:becomplete_key_complete, "<c-r>=becomplete#complete#user()<cr>", "noescape noinsert")
call util#map#i(g:becomplete_key_complete_prev, "pumvisible() ? '\<c-p>' : '" . g:becomplete_key_complete_prev . "'", "<expr> noescape noinsert")

" popup menu navigation
call util#map#i("<cr>", "pumvisible() ? '\<c-y>' : '<cr>'", "<expr> noescape noinsert")
call util#map#i("<up>", "pumvisible() ? '\<c-p>' : '<up>'", "<expr> noescape noinsert")
call util#map#i("<down>", "pumvisible() ? '\<c-n>' : '<down>'", "<expr> noescape noinsert")

" function argument selection
call util#map#nvi(g:becomplete_key_arg_next, "<esc>:call becomplete#complete#signature_select(1)<cr>")
call util#map#nvi(g:becomplete_key_arg_prev, "<esc>:call becomplete#complete#signature_select(0)<cr>")

" goto
call util#map#n(g:becomplete_key_goto, "<insert><c-r>=becomplete#goto#decldef()<cr>")

" symbol
call util#map#n(g:becomplete_key_symbol_all, "<insert><c-r>=becomplete#symbol#all()<cr>")
call util#map#n(g:becomplete_key_symbol_functions, "<insert><c-r>=becomplete#symbol#functions()<cr>")
call util#map#n(g:becomplete_key_symbol_funchead, "<insert><c-r>=becomplete#symbol#function_head()<cr>")
"}}}
