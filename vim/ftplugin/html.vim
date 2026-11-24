setlocal textwidth=0

" PHP, Blade and other filetypes source this file too; only HTML is
" laid out by Prettier (autoload/htmlformat.vim)
if &filetype !=# 'html'
  finish
endif

call htmlformat#Setup()
