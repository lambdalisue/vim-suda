if exists('g:loaded_suda')
  finish
endif
let g:loaded_suda = 1

if get(g:, 'suda_smart_edit')
  augroup suda_smart_edit
    autocmd!
    autocmd BufEnter * nested call suda#BufEnter()
  augroup end
endif

augroup suda_plugin
  autocmd!
  autocmd BufReadCmd   suda://* call suda#BufReadCmd()
  autocmd FileReadCmd  suda://* call suda#FileReadCmd()
  autocmd BufWriteCmd  suda://* call suda#BufWriteCmd()
  autocmd FileWriteCmd suda://* call suda#FileWriteCmd()
augroup END

function! s:read(args) abort
  let args = empty(a:args) ? expand('%:p') : a:args
  execute printf('edit suda://%s', args)
endfunction
command! -nargs=? -complete=file SudaRead  call s:read(<q-args>)

function! s:write(args) abort
  let args = empty(a:args) ? expand('%:p') : a:args
  execute printf('write suda://%s', args)
endfunction
command! -nargs=? -complete=file SudaWrite call s:write(<q-args>)
