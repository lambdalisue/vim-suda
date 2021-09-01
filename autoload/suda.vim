function! suda#system(cmd, ...) abort
  let cmd = has('win32')
        \ ? printf('sudo %s', a:cmd)
        \ : printf('sudo -p '''' -n %s', a:cmd)
  if &verbose
    echomsg '[suda]' cmd
  endif
  let result = a:0 ? system(cmd, a:1) : system(cmd)
  if v:shell_error == 0
    return result
  endif
  try
    call inputsave()
    redraw | let password = inputsecret(g:suda#prompt)
  finally
    call inputrestore()
  endtry
  let cmd = printf('sudo -p '''' -S %s', a:cmd)
  return system(cmd, password . "\n" . (a:0 ? a:1 : ''))
endfunction

function! suda#read(expr, ...) abort range
  let path = s:strip_prefix(expand(a:expr))
  let path = fnamemodify(path, ':p')
  let options = extend({
        \ 'cmdarg': v:cmdarg,
        \ 'range': '',
        \}, a:0 ? a:1 : {}
        \)

  if filereadable(path)
    return substitute(execute(printf(
          \ '%sread %s %s',
          \ options.range,
          \ options.cmdarg,
          \ path,
          \)), '^\r\?\n', '', '')
  endif

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
  let path = s:strip_prefix(expand(a:expr))
  let path = fnamemodify(path, ':p')
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
    if has('win32')
      " In MS Windows, tee.exe has been placed at $VIMRUNTIME and $VIMRUNTIME
      " is added to $PATH in Vim process so `executable('tee')` returns 1.
      " However, sudo.exe executes a command in a new environment.  The
      " directory $VIMRUNTIME is not added here, so `tee` is not found.
      " Using a full path for tee command to avoid this problem.
      let tee_cmd = exepath('tee')
      let result = suda#system(
            \ printf('%s %s', shellescape(tee_cmd), shellescape(path)),
            \ join(readfile(tempfile, 'b'), "\n")
            \)
    else
      " `bs=1048576` is equivalent to `bs=1M` for GNU dd or `bs=1m` for BSD dd
      " Both `bs=1M` and `bs=1m` are non-POSIX
      let result = suda#system(printf(
            \ 'dd if=%s of=%s bs=1048576',
            \ shellescape(tempfile),
            \ shellescape(path)
            \))
    endif
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
  doautocmd <nomodeline> BufReadPre
  let ul = &undolevels
  set undolevels=-1
  try
    let echo_message = suda#read('<afile>', {
          \ 'range': '1',
          \})
    silent 0delete _
    setlocal buftype=acwrite
    setlocal nobackup noswapfile noundofile
    setlocal nomodified
    filetype detect
    redraw | echo echo_message
  catch
    call s:echomsg_exception()
  finally
    let &undolevels = ul
    doautocmd <nomodeline> BufReadPost
  endtry
endfunction

function! suda#FileReadCmd() abort
  doautocmd <nomodeline> FileReadPre
  try
    " XXX
    " A '[ mark indicates the {range} of the command.
    " However, the mark becomes 1 even user execute ':0read'.
    " So check the last command to find if the {range} was 0 or not.
    let range = histget('cmd', -1) =~# '^0r\%[ead]\>' ? '0' : '''['
    redraw | echo suda#read('<afile>', {
          \ 'range': range,
          \})
  catch
    call s:echomsg_exception()
  finally
    doautocmd <nomodeline> FileReadPost
  endtry
endfunction

function! suda#BufWriteCmd() abort
  doautocmd <nomodeline> BufWritePre
  try
    let echo_message = suda#write('<afile>', {
          \ 'range': '''[,'']',
          \})
    let lhs = expand('%')
    let rhs = expand('<afile>')
    if lhs ==# rhs || substitute(rhs, '^suda://', '', '') ==# lhs
      setlocal nomodified
    endif
    redraw | echo echo_message
  catch
    call s:echomsg_exception()
  finally
    doautocmd <nomodeline> BufWritePost
  endtry
endfunction

function! suda#FileWriteCmd() abort
  doautocmd <nomodeline> FileWritePre
  try
    redraw | echo suda#write('<afile>', {
          \ 'range': '''[,'']',
          \})
  catch
    call s:echomsg_exception()
  finally
    doautocmd <nomodeline> FileWritePost
  endtry
endfunction

function! suda#BufEnter() abort
  if exists('b:suda_smart_edit_checked')
    return
  endif
  let b:suda_smart_edit_checked = 1
  let bufname = expand('<afile>')
  if !empty(&buftype)
        \ || empty(bufname)
        \ || match(bufname, '^[a-z]\+://*') isnot# -1
        \ || isdirectory(bufname)
    " Non file buffer
    return
  elseif filereadable(bufname) && filewritable(bufname)
    " File is readable and writeable
    return
  elseif empty(getftype(bufname))
    " if file doesn't exist, we search for a all directories up it's path to
    " see if each one of them is writable, if not, we `return`
    let parent = fnamemodify(bufname, ':p')
    while parent !=# fnamemodify(parent, ':h')
      let parent = fnamemodify(parent, ':h')
      if filewritable(parent) is# 2
        return
      elseif !filereadable(parent) && isdirectory(parent)
        break
      endif
    endwhile
  endif
  let bufnr = str2nr(expand('<abuf>'))
  execute printf(
        \ 'keepalt keepjumps edit suda://%s',
        \ fnamemodify(bufname, ':p'),
        \)
  execute printf('silent! %dbwipeout', bufnr)
endfunction

function! s:escape_patterns(expr) abort
  return escape(a:expr, '^$~.*[]\')
endfunction

function! s:strip_prefix(expr) abort
  return substitute(a:expr, '\v^(suda://)+', '', '')
endfunction

function! s:echomsg_exception() abort
  redraw
  echohl ErrorMsg
  for line in split(v:exception, '\n')
    echomsg printf('[suda] %s', line)
  endfor
  echohl None
endfunction

" Pseudo autocmd to suppress 'No such autocmd' message
augroup suda_internal
  autocmd!
  autocmd BufReadPre,BufReadPost     suda://* :
  autocmd FileReadPre,FileReadPost   suda://* :
  autocmd BufWritePre,BufWritePost   suda://* :
  autocmd FileWritePre,FileWritePost suda://* :
augroup END

" Configure
let g:suda#prompt = get(g:, 'suda#prompt', 'Password: ')
