# 🥪 suda.vim

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Doc](https://img.shields.io/badge/doc-%3Ah%20suda-orange.svg?style=flat-square)](doc/suda.txt)

_suda_ is a plugin to read or write files with `sudo` command.

This plugin was built while `:w !sudo tee % > /dev/null` trick does not work on [neovim][].

https://github.com/neovim/neovim/issues/1716

This plugin is strongly inspired by [sudo.vim][] but the interfaces was aggressively modified for modern Vim script.

[sudo.vim]: https://github.com/vim-scripts/sudo.vim
[neovim]: https://github.com/neovim/neovim

## Usage

Use `SudaRead` to open unreadable files like:

```
" Re-open a current file with sudo
:SudaRead

" Open /etc/sudoers with sudo
:SudaRead /etc/sudoers
```

Or `SudaWrite` to write unwritable files like:

```
" Forcedly save a current file with sudo
:SudaWrite

" Write contents to /etc/profile
:SudaWrite /etc/profile
```

You can change the prompt string with `g:suda#prompt`.

```vim
" 'Password' in french
let g:suda#prompt = 'Mot de passe: '
```

### Smart edit

When `let g:suda_smart_edit = 1` is written in your vimrc, suda automatically switch a buffer name when the target file is not readable or writable.

In short,

```
$ vim /etc/hosts
```

or

```
:e /etc/shadow
```

Will open `suda:///etc/hosts` or `suda:///etc/shadow` instead of `/etc/hosts` or `/etc/shadow` because that files are not writable or not readable.

### Windows

Install [mattn/sudo](https://github.com/mattn/sudo) to enable this plugin in Windows.
Make sure that the following shows `1`.

```vim
: echo executable('sudo')
```
