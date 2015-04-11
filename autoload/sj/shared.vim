" Splitting if-clauses with curly braces, common to:
"
" - javascript
" - PHP
"
function! sj#shared#SplitCurlyBracketIfClause(curly_braces)
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

  if a:curly_braces =~# 'S'
    let body = " {\n".body."\n}"
  else
    let body = "\n".body
  endif

  if line('.') == line('$')
    " we shouldn't add a newline for the last line of the file, adds one too
    " many newlines
  else
    let body .= "\n"
  endif

  call sj#ReplaceMotion('v$', body)

  return 1
endfunction

" Joining if-clauses with curly braces, common to:
"
" - javascript
" - PHP
"
function! sj#shared#JoinCurlyBracketIfClause(curly_braces)
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

    if a:curly_braces =~# 'j'
      " remove curly brackets
      let body = substitute(body, '^{\s*\(.\{-}\)\s*}$', '\1', '')
    endif

    call sj#ReplaceMotion('Va{', body)
  else
    " no curly brackets, must be the next line
    call sj#PushCursor()
    normal! J
    call sj#PopCursor()

    if a:curly_braces =~# 'J'
      " add curly brackets
      normal! l
      let body = sj#GetMotion('v$')
      let body = " { ".sj#Trim(body)." }\n"
      call sj#ReplaceMotion('v$', body)
    endif
  endif

  return 1
endfunction
