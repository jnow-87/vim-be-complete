"{{{
"{{{
" dictionary with the configuration for supported languages
" key to dictionary is the language name (vim file type), each entry contains
" the following keys
" 	"kinds": dictionary mapping ctags kinds to g:becomplete_kindsym_*
" 	"prototype_kind": the ctags kind that represents a symbol declaration
let s:lang_config = {
\	"undef": {
\		"kinds": {},
\		"prototype_kind": "",
\	},
\	"asm": {
\		"kinds": {
\			"d": g:becomplete_kindsym_macro,
\			"l": g:becomplete_kindsym_text,
\			"m": g:becomplete_kindsym_macro,
\			"t": g:becomplete_kindsym_type,
\		},
\		"prototype_kind": "",
\	},
\	"c": {
\		"kinds": {
\			"c": g:becomplete_kindsym_type,
\			"d": g:becomplete_kindsym_macro,
\			"e": g:becomplete_kindsym_member,
\			"f": g:becomplete_kindsym_function,
\			"g": g:becomplete_kindsym_type,
\			"l": g:becomplete_kindsym_variable,
\			"m": g:becomplete_kindsym_member,
\			"n": g:becomplete_kindsym_namespace,
\			"p": g:becomplete_kindsym_function,
\			"s": g:becomplete_kindsym_type,
\			"t": g:becomplete_kindsym_type,
\			"u": g:becomplete_kindsym_type,
\			"v": g:becomplete_kindsym_variable,
\			"x": g:becomplete_kindsym_variable,
\		},
\		"prototype_kind": "s:becomplete_kindsym_function",
\	},
\	"cpp": {
\		"kinds": {
\			"c": g:becomplete_kindsym_type,
\			"d": g:becomplete_kindsym_macro,
\			"e": g:becomplete_kindsym_member,
\			"f": g:becomplete_kindsym_function,
\			"g": g:becomplete_kindsym_type,
\			"l": g:becomplete_kindsym_variable,
\			"m": g:becomplete_kindsym_member,
\			"n": g:becomplete_kindsym_namespace,
\			"p": g:becomplete_kindsym_function,
\			"s": g:becomplete_kindsym_type,
\			"t": g:becomplete_kindsym_type,
\			"u": g:becomplete_kindsym_type,
\			"v": g:becomplete_kindsym_variable,
\			"x": g:becomplete_kindsym_variable,
\		},
\		"prototype_kind": "s:becomplete_kindsym_function",
\	},
\	"vim": {
\		"kinds": {
\			"a": g:becomplete_kindsym_variable,
\			"c": g:becomplete_kindsym_variable,
\			"f": g:becomplete_kindsym_function,
\			"m": g:becomplete_kindsym_variable,
\			"v": g:becomplete_kindsym_variable,
\		},
\		"prototype_kind": "",
\	},
\	"sh": {
\		"kinds": {
\			"f": g:becomplete_kindsym_function,
\		},
\		"prototype_kind": "",
\	},
\	"make": {
\		"kinds": {
\			"m": g:becomplete_kindsym_macro,
\		},
\		"prototype_kind": "",
\	},
\	"python": {
\		"kinds": {
\			"c": g:becomplete_kindsym_type,
\			"f": g:becomplete_kindsym_function,
\			"m": g:becomplete_kindsym_member,
\			"v": g:becomplete_kindsym_variable,
\			"i": g:becomplete_kindsym_file,
\		},
\		"prototype_kind": "",
\	},
\	"java": {
\		"kinds": {
\			"c": g:becomplete_kindsym_type,
\			"e": g:becomplete_kindsym_member,
\			"f": g:becomplete_kindsym_member,
\			"g": g:becomplete_kindsym_type,
\			"i": g:becomplete_kindsym_namespace,
\			"l": g:becomplete_kindsym_variable,
\			"m": g:becomplete_kindsym_function,
\			"p": g:becomplete_kindsym_namespace,
\		},
\		"prototype_kind": "",
\	},
\	"php": {
\		"kinds": {
\			"c": g:becomplete_kindsym_type,
\			"i": g:becomplete_kindsym_namespace,
\			"d": g:becomplete_kindsym_macro,
\			"f": g:becomplete_kindsym_function,
\			"j": g:becomplete_kindsym_function,
\		},
\		"prototype_kind": "",
\	},
\ }
"}}}

" mapping from ctags language names to vim file types
let s:lang_map = {
\	"Asm": "asm",
\	"C": "c",
\	"C++": "cpp",
\	"Vim": "vim",
\	"Sh": "sh",
\	"Make": "make",
\	"Python": "python",
\	"Java": "java",
\	"PHP": "php",
\ }

" symbol table containing all files that a symbol is found in
" structure:
" 	{
" 		<symbol name>: {
" 			<file>: [ <symbol according to s:symbol()> ]
" 		}
" 	}
let s:symtab = {}

" symbol table containing all symbols per file
" structure:
" 	{
" 		<file>: [ <symbol according to s:symbol()> ]
" 	}
let s:filesymtab = {}
"}}}


""""
"" local functions
""""

"{{{
" \brief	create a symbol object
"
" \param	name	symbol name
" \param	file	file name that the symbol occurs in
" \param	line	line into a:file
" \param	kind	symbol kind according to g:becomplete_kindsym_*
" \param	type	symbol type according to g:becomplete_type_*
" \param	detail	string containing symbol details, such as a signature
"
" \return	symbol object
function s:symbol(name, file, line, kind, type, detail)
	return {
	\	"name": a:name,
	\	"file": a:file,
	\	"line": a:line,
	\	"kind": a:kind,
	\	"type": a:type,
	\	"detail": a:detail,
	\ }
endfunction
"}}}

"{{{
" \brief	return the supported ctags kinds for the given language
"
" \param	lang	vim file type to get kinds for
"
" \return	non-whitespaced string with ctags kinds
function s:kinds(lang)
	if !has_key(s:lang_config, a:lang)
		return ""
	endif

	return join(keys(s:lang_config[a:lang]["kinds"]), "")
endfunction
"}}}

"{{{
" \brief	extract symbol signature from line
"
" \param	line	string to parse
"
" \return	string with the signature
function s:parse_signature(line)
	let l:start = stridx(a:line, "/^")
	let l:end = stridx(a:line, "\$/;\"", l:start)

	if l:start == -1 || l:end == -1
		return ""
	endif

	" extract signature from line
	let l:sig = strpart(a:line, l:start + 2, l:end - l:start - 2)
	let l:sig = matchstr(l:sig, "[a-zA-Z].*[)a-zA-Z0-9]")

	return l:sig
endfunction
"}}}

"{{{
" \brief	extract the given key out of line
"			line is parsed for a:key in the form of "<a:key>:<value>"
"
" \param	line	string to parse
" \param	key		string containing a key to look for
"
" \return	string with the value associated with a:key
"			if the pattern "<a:key>:" is not detected an empty string is
"			returned
function s:parse_key(line, key)
	let l:start = stridx(a:line, a:key . ":")
	let l:colon = stridx(a:line, ":", l:start)
	let l:end = stridx(a:line, "\t", l:colon)

	if l:start == -1 || l:colon == -1
		return ""
	endif

	return a:line[l:colon + 1:(l:end == -1) ? l:end : l:end - 1]
endfunction
"}}}

"{{{
" \brief	update the symbol table
"
" \param	pattern		string passed on to ctags describing the files to
"						parse
function s:update(pattern)
	let l:cmd = "ctags"
	\ . " -R"
	\ . " --filter=yes"
	\ . " --languages=c,c++,asm,vim,sh,make,python,java,php"
	\ . " --fields=zknl"
	\ . " --c-kinds=" . s:kinds("c")
	\ . " --c++-kinds=" . s:kinds("cpp")
	\ . " --asm-kinds=" . s:kinds("asm")
	\ . " --vim-kinds=" . s:kinds("vim")
	\ . " --sh-kinds=" . s:kinds("sh")
	\ . " --make-kinds=" . s:kinds("make")
	\ . " --python-kinds=" . s:kinds("python")
	\ . " --java-kinds=" . s:kinds("java")
	\ . " --php-kinds=" . s:kinds("php")


	call becomplete#log#msg("update ctags symbol table for files: " . a:pattern)

	for l:line in systemlist(l:cmd, a:pattern)
		" parse line
		let l:tokens = split(l:line, '\t')

		if len(l:tokens) < 3
			continue
		endif

		let l:name = l:tokens[0]
		let l:file = fnamemodify(l:tokens[1], ':p')
		let l:signature = s:parse_signature(l:tokens[2])
		let l:signature = (l:signature == "") ? l:name : l:signature
		let l:linenr = str2nr(s:parse_key(l:line, "line"))
		let l:lang = get(s:lang_map, s:parse_key(l:line, "language"), "undef")
		let l:kind = get(s:lang_config[l:lang]["kinds"], s:parse_key(l:line, "kind"), g:becomplete_kindsym_undef)
		let l:type = (l:kind == s:lang_config[l:lang]["prototype_kind"]) ?
			\ g:becomplete_type_declaration : g:becomplete_type_definition

		let l:sym = s:symbol(l:name, l:file, l:linenr, l:kind, l:type, l:signature)

		" update symbol tables
		call becomplete#log#msg(" symbol: " . string(l:sym))

		let s:symtab[l:name] = get(s:symtab, l:name, {})
		let s:symtab[l:name][l:file] = get(s:symtab[l:name], l:file, [])
		let s:symtab[l:name][l:file] += [ l:sym ]

		let s:filesymtab[l:file] = get(s:filesymtab, l:file, [])
		let s:filesymtab[l:file] += [ l:sym ]
	endfor
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	initialise the symbol table, parsing all supported files in the
"			current directory
function becomplete#ctags#symtab#init()
	call s:update(".")
endfunction
"}}}

"{{{
" \brief	update the symbol table, parsing the given file
"
" \param	file	file name
function becomplete#ctags#symtab#update(file)
	" remove existing symbols for a:file
	for l:sym in get(s:filesymtab, a:file, [])
		let s:symtab[l:sym["name"]][a:file] = []
	endfor

	let s:filesymtab[a:file] = []

	" parse symbols of a:file
	call s:update(a:file)
endfunction
"}}}

"{{{
" \brief	return all symbols for the given file and kinds
"
" \param	file	file name
" \param	kinds	list of kinds according to g:becomplete_kindsym_*
"
" \return	list of symbols according to s:symbol()
function becomplete#ctags#symtab#filesymbols(file, kinds=[])
	let l:symbols = get(s:filesymtab, a:file, [])

	if a:kinds == []
		return l:symbols
	endif

	let l:items = []

	for l:sym in l:symbols
		if index(a:kinds, l:sym["kind"]) != -1
			let l:items += [ l:sym ]
		endif
	endfor

	return l:items
endfunction
"}}}

"{{{
" \brief	find all occurrences of the given symbol
"
" \param	name	symbol name
"
" \return	list of symbols according to s:symbol()
function becomplete#ctags#symtab#lookup(name)
	let l:symbols = []

	for l:lst in values(get(s:symtab, a:name, {}))
		let l:symbols += l:lst
	endfor

	return l:symbols
endfunction
"}}}

"{{{
" \brief	return a list of supported vim file types
"
" \return	list of vim file types
function becomplete#ctags#symtab#filetypes()
	return values(s:lang_map)
endfunction
"}}}
