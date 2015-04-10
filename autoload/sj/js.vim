function! sj#js#SplitObjectLiteral()
  let [from, to] = sj#LocateBracesOnLine('{', '}')

  if from < 0 && to < 0
    return 0
  else
    let pairs = sj#ParseJsonObjectBody(from + 1, to - 1)
    let body  = "{\n".join(pairs, ",\n")."\n}"
    call sj#ReplaceMotion('Va{', body)

    if g:splitjoin_align
      let body_start = line('.') + 1
      let body_end   = body_start + len(pairs) - 1
      call sj#Align(body_start, body_end, 'json_object')
    endif

    return 1
  endif
endfunction

function! sj#js#SplitFunction()
  if expand('<cword>') == 'function' && getline('.') =~ '\<function\>.*(.*)\s*{.*}'
    normal! f{
    return sj#js#SplitObjectLiteral()
  else
    return 0
  endif
endfunction

function! sj#js#JoinObjectLiteral()
  let line = getline('.')

  if line =~ '{\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = split(body, "\n")
    let lines = sj#TrimList(lines)
    if g:splitjoin_normalize_whitespace
      let lines = map(lines, 'substitute(v:val, ":\\s\\+", ": ", "")')
    endif

    let body = join(lines, ' ')
    let body = '{'.body.'}'

    call sj#ReplaceMotion('Va{', body)

    return 1
  else
    return 0
  endif
endfunction

function! sj#js#JoinFunction()
  let line = getline('.')

  if line =~ 'function\%(\s\+\k\+\)\=(.*) {\s*$'
    call search('{', 'c', line('.'))
    let body = sj#GetMotion('Vi{')

    let lines = split(body, ';\=\s*\n')
    let lines = sj#TrimList(lines)
    let body = join(lines, '; ').';'
    let body = '{ '.body.' }'

    call sj#ReplaceMotion('Va{', body)

    return 1
  else
    return 0
  endif
endfunction

function! s:SplitList(delimiter)
  let start = a:delimiter[0]
  let end   = a:delimiter[1]

  let lineno = line('.')
  let indent = indent('.')

  let [from, to] = sj#LocateBracesOnLine(start, end)

  if from < 0 && to < 0
    return 0
  endif

  let items = sj#ParseJsonObjectBody(from + 1, to - 1)
  let body  = start."\n".join(items, ",\n")."\n".end
  call sj#ReplaceMotion('Va'.start, body)

  " built-in js indenting doesn't indent this properly
  for l in range(lineno + 1, lineno + len(items))
    call sj#SetIndent(l, indent + &sw)
  endfor
  " closing bracket
  let end_line = lineno + len(items) + 1
  call sj#SetIndent(end_line, indent)

  return 1
endfunction

function! sj#js#SplitArray()
  return s:SplitList(['[', ']'])
endfunction

function! sj#js#SplitArgs()
  return s:SplitList(['(', ')'])
endfunction

function! s:JoinList(delimiter)
  let start = a:delimiter[0]
  let end   = a:delimiter[1]

  let line = getline('.')

  if line !~ start . '\s*$'
    return 0
  endif

  call search(start, 'c', line('.'))
  let body = sj#GetMotion('Vi'.start)

  let lines = split(body, "\n")
  let lines = sj#TrimList(lines)
  let body  = sj#Trim(join(lines, ' '))

  call sj#ReplaceMotion('Va'.start, start.body.end)

  return 1
endfunction

function! sj#js#JoinArray()
  return s:JoinList(['[', ']'])
endfunction

function! sj#js#JoinArgs()
  return s:JoinList(['(', ')'])
endfunction

" Note: Copied from PHP case. Can't reuse due to setting name.
function! sj#js#SplitIfClause()
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

  if g:splitjoin_javascript_if_clause_curly_braces =~# 'J'
    let body = " {\n".body."\n}\n"
  else
    let body = "\n".body."\n"
  endif

  call sj#ReplaceMotion('v$', body)

  return 1
endfunction

" Note: Copied from PHP case. Can't reuse due to setting name.
function! sj#js#JoinIfClause()
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

    if g:splitjoin_javascript_if_clause_curly_braces =~# 'j'
      " remove curly brackets
      let body = substitute(body, '^{\s*\(.\{-}\)\s*}$', '\1', '')
    endif

    call sj#ReplaceMotion('Va{', body)
  else
    " no curly brackets, must be the next line
    call sj#PushCursor()
    normal! J
    call sj#PopCursor()

    if g:splitjoin_javascript_if_clause_curly_braces =~# 'J'
      " add curly brackets
      normal! l
      let body = sj#GetMotion('v$')
      let body = " { ".sj#Trim(body)." }\n"
      call sj#ReplaceMotion('v$', body)
    endif
  endif

  return 1
endfunction
