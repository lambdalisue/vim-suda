function! suda#init(...) abort
  let pat = a:0 ? a:1 : printf('%s*', g:suda#prefix)
  augroup suda_internal
    autocmd! *
    execute printf('autocmd BufReadCmd %s call suda#BufReadCmd()', pat)
    execute printf('autocmd FileReadCmd %s call suda#FileReadCmd()', pat)
    execute printf('autocmd BufWriteCmd %s call suda#BufWriteCmd()', pat)
    execute printf('autocmd FileWriteCmd %s call suda#FileWriteCmd()', pat)
    " Pseudo autocmd to suppress 'No such autocmd' message
    execute printf('autocmd BufReadPre,BufReadPost %s :', pat)
    execute printf('autocmd FileReadPre,FileReadPost %s :', pat)
    execute printf('autocmd BufWritePre,BufWritePost %s :', pat)
    execute printf('autocmd FileWritePre,FileWritePost %s :', pat)
  augroup END
endfunction

function! suda#system(cmd, ...) abort
  let cmd = printf('sudo -p '''' -n %s', a:cmd)
  if &verbose
    echomsg '[suda]' cmd
  endif
  let result = a:0 ? system(cmd, a:1) : system(cmd)
  if v:shell_error == 0
    return result
  endif
  try
    call inputsave()
    redraw | let password = inputsecret('Password: ')
  finally
    call inputrestore()
  endtry
  let cmd = printf('sudo -p '''' -S %s', a:cmd)
  return system(cmd, password . "\n" . (a:0 ? a:1 : ''))
endfunction

function! suda#read(expr, ...) abort range
  let path = s:expand_expression(a:expr)
  let options = extend({
        \ 'cmdarg': v:cmdarg,
        \ 'range': '',
        \}, a:0 ? a:1 : {}
        \)
  let tempfile = tempname()
  try
    let redirect = &shellredir =~# '%s'
          \ ? printf(&shellredir, shellescape(tempfile))
          \ : &shellredir . shellescape(tempfile)
    let result = suda#system(printf(
          \ 'cat %s %s',
          \ shellescape(fnamemodify(path, ':p')),
          \ redirect,
          \))
    if v:shell_error
      throw result
    else
      let echo_message = execute(printf(
            \ '%sread %s %s',
            \ options.range,
            \ options.cmdarg,
            \ tempfile,
            \))
      " Rewrite message with a correct file name
      let echo_message = substitute(
            \ echo_message,
            \ s:escape_patterns(tempfile),
            \ fnamemodify(path, ':~'),
            \ 'g',
            \)
      return substitute(echo_message, '^\r\?\n', '', '')
    endif
  finally
    silent call delete(tempfile)
  endtry
endfunction

function! suda#write(expr, ...) abort range
  let path = s:expand_expression(a:expr)
  let options = extend({
        \ 'cmdarg': v:cmdarg,
        \ 'cmdbang': v:cmdbang,
        \ 'range': '',
        \}, a:0 ? a:1 : {}
        \)
  let tempfile = tempname()
  try
    let path_exists = !empty(getftype(path))
    let echo_message = execute(printf(
          \ '%swrite%s %s %s',
          \ options.range,
          \ options.cmdbang ? '!' : '',
          \ options.cmdarg,
          \ tempfile,
          \))
    let result = suda#system(
          \ printf('tee %s', shellescape(path)),
          \ join(readfile(tempfile, 'b'), "\n")
          \)
    if v:shell_error
      throw result
    endif
    " Rewrite message with a correct file name
    let echo_message = substitute(
          \ echo_message,
          \ s:escape_patterns(tempfile),
          \ fnamemodify(path, ':~'),
          \ 'g',
          \)
    if path_exists
      let echo_message = substitute(echo_message, '\[New\] ', '', 'g')
    endif
    return substitute(echo_message, '^\r\?\n', '', '')
  finally
    silent call delete(tempfile)
  endtry
endfunction


function! suda#BufReadCmd() abort
  call s:doautocmd('BufReadPre')
  try
    let echo_message = suda#read('<afile>', {
          \ 'range': '1',
          \})
    silent 0delete _
    setlocal buftype=acwrite
    setlocal nomodified
    filetype detect
    redraw | echo echo_message
  finally
    call s:doautocmd('BufReadPost')
  endtry
endfunction

function! suda#FileReadCmd() abort
  call s:doautocmd('FileReadPre')
  try
    " XXX
    " A '[ mark indicates the {range} of the command.
    " However, the mark becomes 1 even user execute ':0read'.
    " So check the last command to find if the {range} was 0 or not.
    let range = histget('cmd', -1) =~# '^0r\%[ead]\>' ? '0' : '''['
    redraw | echo suda#read('<afile>', {
          \ 'range': range,
          \})
  finally
    call s:doautocmd('FileReadPost')
  endtry
endfunction

function! suda#BufWriteCmd() abort
  call s:doautocmd('BufWritePre')
  try
    let echo_message = suda#write('<afile>', {
          \ 'range': '''[,'']',
          \})
    if expand('%') ==# expand('<afile>')
      setlocal nomodified
    endif
    redraw | echo echo_message
  finally
    call s:doautocmd('BufWritePost')
  endtry
endfunction

function! suda#FileWriteCmd() abort
  call s:doautocmd('FileWritePre')
  try
    redraw | echo suda#write('<afile>', {
          \ 'range': '''[,'']',
          \})
  finally
    call s:doautocmd('FileWritePost')
  endtry
endfunction


function! s:escape_patterns(expr) abort
  return escape(a:expr, '^$~.*[]\')
endfunction

function! s:expand_expression(expr) abort
  let prefix = s:escape_patterns(g:suda#prefix)
  return fnamemodify(substitute(expand(a:expr), '^' . prefix, '', ''), ':p')
endfunction

function! s:doautocmd(name) abort
  execute printf(
        \ 'doautocmd %s %s',
        \ a:name,
        \ fnameescape(expand('<afile>'))
        \)
endfunction


" Configure
let g:suda#prefix = get(g:, 'suda#prefix', 'suda://')
