if exists('g:loaded_suda')
  finish
endif
let g:loaded_suda = 1

if get(g:, 'suda_startup', 1)
  call suda#init()
endif

if get(g:, 'suda_smart_edit')
  augroup suda_smart_edit
    autocmd!
    autocmd BufEnter * nested call suda#BufEnter()
  augroup end
endif
