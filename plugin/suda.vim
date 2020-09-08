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
