suda.vim
===============================================================================
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20suda-orange.svg?style=flat-square)](doc/suda.txt)

*suda* is a plugin to read or write files with `sudo` command.

This plugin was built while `:w !sudo tee % > /dev/null` trick does not work on [neovim][].

https://github.com/neovim/neovim/issues/1716

This plugin is strongly inspired by [sudo.vim][] but the interfaces was aggressively modified for modern Vim script.

[sudo.vim]: https://github.com/vim-scripts/sudo.vim
[neovim]: https://github.com/neovim/neovim



Usage
-------------------------------------------------------------------------------

Use `suda://` prefix in `read`, `edit`, `write`, or `saveas` commands.

```vim
" Open a current file with sudo
:e suda://%

" Save a current file with sudo
:w suda://%

" Edit /etc/sudoers
:e suda:///etc/sudoers

" Read /etc/sudoers (insert content under the cursor)
:r suda:///etc/sudoers

" Read /etc/sudoers at the end
:$r suda:///etc/sudoers

" Write contents to /etc/profile
:w suda:///etc/profile

" Save contents to /etc/profile
:saveas suda:///etc/profile
```

You can change the protocol prefix with `g:suda#prefix`.

```vim
let g:suda#prefix = 'suda://'
" multiple protocols can be defined too
let g:suda#prefix = ['suda://', 'sudo://', '_://']
```
