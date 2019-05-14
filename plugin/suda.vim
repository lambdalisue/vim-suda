if exists('g:loaded_suda')
  finish
endif
let g:loaded_suda = 1

if get(g:, 'suda_startup', 1)
  call suda#init()
endif

if get(g:, 'suda_smart_read')
  augroup suda_smart_read_primary
    autocmd!
    autocmd BufEnter * nested call suda#BufEnter()
    autocmd VimEnter *
          \ augroup suda_smart_read_primary |
          \   autocmd! * |
          \ augroup END
  augroup END

  augroup suda_smart_read_secondary
    autocmd! * <buffer>
    autocmd BufNew *
         \ augroup suda_smart_read_local |
         \   autocmd BufEnter <buffer=abuf> nested call suda#BufEnter() |
         \ augroup END
  augroup END
endif
