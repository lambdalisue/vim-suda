if exists('g:loaded_suda')
  finish
endif
let g:loaded_suda = 1

if get(g:, 'suda_startup', 1)
  call suda#init()
endif

if exists('g:suda_hijack_write')
  cabbrev w W
  cabbrev wq Wq
  command! W execute suda#write_wrapper('w')
  command! Wq execute suda#write_wrapper('wq')
endif

if exists('g:suda_smart_read')
  augroup suda_smart_read
    autocmd!
    autocmd BufEnter * nested call suda#smart_read(expand('<abuf>'), expand('<afile>'))
  augroup end
endif
