function! s:AddGitignoreToWildignore(gitpath, isRoot)
	let gitignore = a:gitpath . '/.gitignore'
	if !filereadable(gitignore)
		return
	endif

	let ignorePatterns = ''

	for line in readfile(gitignore)
		" Get rid of any extraneous spacing
		let line = substitute(line, '\s|\n|\r', '', "g")

		" Skip comment lines, blank lines, or 'not' (!) lines
		if line =~ '^#' || line == '' || line =~ '^!'
			continue
		endif

		if a:isRoot
			" We're adding a gitignore at the project root

			if line[0] == '/'
				let line = strcharpart(line, 1)
			endif

			let pattern = line
		else
			" We're adding a gitignore from somewhere other than the project root

			if line =~ "/"
				let pattern = fnamemodify(a:gitpath . '/' . line, ":.")
			else
				let pattern = line
			endif
		endif

		if pattern =~ "/$" 
			let pattern .= "*" 
		endif

		let ignorePatterns .= ',' . pattern

		" If a pattern has the form dir/**/*.ext, also add a version of the
		" form dir/*.ext so that vim will handle the case of *.ext in dir/
		" itself.
		if pattern =~ '/\*\*/'
			let pattern = substitute(pattern, '/\*\*/', '/', 'g')
			let ignorePatterns .= ',' . pattern
		endif
	endfor

	let ignorePatterns = substitute(ignorePatterns, '^,', '', 'g')

	execute 'set wildignore+=' . ignorePatterns
endfunction

let home = finddir('~', ':p:h')

" Always add ~/.gitignore first
call s:AddGitignoreToWildignore(home, 1)

let cwd = getcwd()
let gitdir = finddir('.git', ';')
if gitdir == ""
	let gitdir = findfile('.git', ';')
endif

" Use :h:h since gitdir is a dir
let projectRoot = fnamemodify(gitdir, ':p:h:h')

if projectRoot != '' && projectRoot != cwd
	let dirs = []
	let curdir = cwd
	while curdir != projectRoot && curdir != '/'
		let dirs = add(dirs, curdir)
		let curdir = fnamemodify(curdir, ':h')
	endwhile

	call s:AddGitignoreToWildignore(projectRoot, 0)

	" Process the directories from project root to cwd top-down, so that rules
	" from cwd are added last (and therefore have the highest priority)
	while len(dirs) > 1
		let dir = remove(dirs, -1)
		call s:AddGitignoreToWildignore(projectRoot, 0)
	endwhile
endif

call s:AddGitignoreToWildignore(cwd, 1)
