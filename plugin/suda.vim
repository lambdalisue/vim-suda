if exists('g:loaded_suda')
  finish
endif
let g:loaded_suda = 1

if get(g:, 'suda_startup', 1)
  call suda#init()
endif

if get(g:, 'suda_hijack_write')
  cabbrev w SudaW
  cabbrev wq SudaWq
  command! SudaW call suda#write_wrapper('w')
  command! SudaWq call suda#write_wrapper('wq')
endif

if get(g:, 'suda_smart_read')
  augroup suda_smart_read
    autocmd!
    autocmd BufEnter * nested call suda#smart_read(expand('<abuf>'), expand('<afile>'))
  augroup end
endif
