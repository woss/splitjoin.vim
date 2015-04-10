if !exists('b:splitjoin_split_callbacks')
  let b:splitjoin_split_callbacks = [
        \ 'sj#js#SplitIfClause',
        \ 'sj#js#SplitArray',
        \ 'sj#js#SplitObjectLiteral',
        \ 'sj#js#SplitFunction',
        \ 'sj#js#SplitArgs'
        \ ]
endif

if !exists('b:splitjoin_join_callbacks')
  let b:splitjoin_join_callbacks = [
        \ 'sj#js#JoinArray',
        \ 'sj#js#JoinArgs',
        \ 'sj#js#JoinFunction',
        \ 'sj#js#JoinIfClause',
        \ 'sj#js#JoinObjectLiteral',
        \ ]
endif
