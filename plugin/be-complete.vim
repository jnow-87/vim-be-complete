if exists('g:loaded_becomplete') || &compatible
	finish
endif

let g:loaded_becomplete = 1

" get own script ID
nmap <c-f11><c-f12><c-f13> <sid>
let s:sid = "<SNR>" . maparg("<c-f11><c-f12><c-f13>", "n", 0, 1).sid . "_"
nunmap <c-f11><c-f12><c-f13>


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
augroup BeComplete
augroup END

autocmd VimLeave * silent call becomplete#lsp#server#stop_all()
"}}}
