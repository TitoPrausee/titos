" titOS — Neovim Grundkonfiguration / basic config
set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set smartindent
set termguicolors
set mouse=a
set clipboard=unnamedplus
set ignorecase smartcase
syntax on

" titOS Akzentfarben / accent colours
highlight LineNr guifg=#7a6a9a
highlight CursorLineNr guifg=#b48cff
highlight Comment guifg=#6ad0e0

" Leertaste als Leader / space as leader
let mapleader=" "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
