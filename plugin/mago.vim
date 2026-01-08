" mago.nvim - Neovim plugin for Mago PHP toolchain
" Maintainer: Calvin Ludwig
" Version: 0.1.0

" Prevent loading the plugin twice
if exists('g:loaded_mago')
  finish
endif
let g:loaded_mago = 1

" Load Lua commands
lua require('mago.commands')
