function! sj#php#SplitArray()
  let arraypattern = '\(array\)\s*(\(.*\))'
  let line         = getline('.')

  if line !~? arraypattern
    return 0
  else
    let [from, to] = sj#LocateBracesOnLine('(', ')')

    if from < 0 && to < 0
      return 0
    else
      let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
      let body  = "(\n".join(pairs, ",\n")."\n)"
      call sj#ReplaceMotion('Va(', body)

      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs)

      call sj#PushCursor()
      exe "normal! jV".(body_end - body_start)."j2="
      call sj#PopCursor()

      if g:splitjoin_align
        call sj#Align(body_start, body_end, 'hashrocket')
      endif
    endif

    return 1
  endif
endfunction

function! sj#php#JoinArray()
  let line = getline('.')

  if line !~ 'array(\s*$'
    return 0
  endif

  call search('array(\s*$', 'ce', line('.'))

  let body = sj#GetMotion('Vi(')

  if g:splitjoin_normalize_whitespace
    let body = substitute(body, '\s*=>\s*', ' => ', 'g')
  endif
  let body = join(sj#TrimList(split(body, "\n")), ' ')
  call sj#ReplaceMotion('Va(', '('.body.')')

  return 1
endfunction

function! sj#php#JoinHtmlTags()
  if synIDattr(synID(line("."), col("."), 1), "name") =~ '^php'
    " then we're in php, don't try to join tags
    return 0
  else
    return sj#html#JoinTags()
  endif
endfunction

function! sj#php#SplitIfClause()
  let pattern = '\<if\s*(.\{-})\s*\S.*'

  if search(pattern, 'Wbc', line('.')) <= 0
    return 0
  endif

  normal! f(
  normal %
  normal! l

  let body = sj#Trim(sj#GetMotion('v$'))

  " remove curly brackets, if there are any
  let body = substitute(body, '^{\s*\(.\{-}\)\s*}$', '\1', '')

  if g:splitjoin_php_if_clause_curly_braces =~# 'J'
    let body = " {\n".body."\n}\n"
  else
    let body = "\n".body."\n"
  endif

  call sj#ReplaceMotion('v$', body)

  return 1
endfunction

function! sj#php#JoinIfClause()
  let pattern = '\<if\s*(.\{-})\s*\%({\s*\)\=$'

  if search(pattern, 'Wbc', line('.')) <= 0
    return 0
  endif

  normal! f(
  normal %

  if getline('.')[col('.') + 1:] =~ '^\s*{\s*$'
    " existing curly brackets
    normal! f{
    let body = sj#GetMotion('Va{')
    let body = substitute(body, "\\s*\n\\s*", ' ', 'g')

    if g:splitjoin_php_if_clause_curly_braces =~# 'j'
      " remove curly brackets
      let body = substitute(body, '^{\s*\(.\{-}\)\s*}$', '\1', '')
    endif

    call sj#ReplaceMotion('Va{', body)
  else
    " no curly brackets, must be the next line
    call sj#PushCursor()
    normal! J
    call sj#PopCursor()

    if g:splitjoin_php_if_clause_curly_braces =~# 'J'
      " add curly brackets
      normal! l
      let body = sj#GetMotion('v$')
      let body = " { ".sj#Trim(body)." }\n"
      call sj#ReplaceMotion('v$', body)
    endif
  endif

  return 1
endfunction

function! sj#php#SplitPhpMarker()
  if sj#SearchUnderCursor('<?=\=\%(php\)\=.\{-}?>') <= 0
    return 0
  endif

  let start_col = col('.')
  let skip = sj#SkipSyntax('phpStringSingle', 'phpStringDouble', 'phpComment')
  if sj#SearchSkip('?>', skip, 'We', line('.')) <= 0
    return 0
  endif
  let end_col = col('.')

  let body = sj#GetCols(start_col, end_col)
  let body = substitute(body, '^<?\(=\=\%(php\)\=\)\s*', "<?\\1\n", '')
  let body = substitute(body, '\s*?>$', "\n?>", '')

  call sj#ReplaceCols(start_col, end_col, body)
  return 1
endfunction

function! sj#php#JoinPhpMarker()
  if sj#SearchUnderCursor('<?=\=\%(php\)\=\s*$') <= 0
    return 0
  endif

  let start_lineno = line('.')
  let skip = sj#SkipSyntax('phpStringSingle', 'phpStringDouble', 'phpComment')
  if sj#SearchSkip('?>', skip, 'We') <= 0
    return 0
  endif
  let end_lineno = line('.')

  let saved_joinspaces = &joinspaces
  set nojoinspaces
  exe start_lineno.','.end_lineno.'join'
  let &joinspaces = saved_joinspaces

  return 1
endfunction
