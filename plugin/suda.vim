if exists('g:loaded_suda')
  finish
endif
let g:loaded_suda = 1

if get(g:, 'suda_startup', 1)
  call suda#init()
endif

if exists('g:suda_hijack_write')
  cabbrev w W
  cabbrev wa Wa
  cabbrev wq Wq
  cabbrev wqa Wqa
  command! W execute suda#write_wrapper('')
  command! Wa execute suda#write_wrapper('a')
  command! Wq execute suda#write_wrapper('q')
  command! Waq execute suda#write_wrapper('aq')
endif

if exists('g:suda_smart_read')
  augroup suda_smart_read
    au!
    au BufReadCmd * nested call suda#smart_read()
  augroup end
endif
