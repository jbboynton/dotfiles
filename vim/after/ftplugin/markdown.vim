" Runs after every other ftplugin, which is the point.
"
" Vim's runtime ftplugin/markdown.vim does:
"
"     runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
"
" so ~/.vim/ftplugin/html.vim (setlocal textwidth=0) is pulled into every
" markdown buffer *after* ~/.vim/ftplugin/markdown.vim has run, wiping
" textwidth. Setting it here instead means nothing loads after us.

setlocal textwidth=80
setlocal spell spelllang=en_us

" The runtime ftplugin sets 4-space indents unless
" g:markdown_recommended_style is 0. Put back the global 2.
setlocal tabstop=2 shiftwidth=2 softtabstop=2

" Indent and outdent a whole list item with Ctrl-> and Ctrl-<.
"
" A terminal cannot send those combinations on its own: there is no
" control code for Ctrl-Shift-Period. Alacritty is configured to send
" CSI-u sequences for them (see config/alacritty/alacritty.toml), and
" they are picked up here as <F13> and <F14>. Without those Alacritty
" bindings these mappings simply never fire.
execute "set <F13>=\<Esc>[62;5u"
execute "set <F14>=\<Esc>[60;5u"

nnoremap <buffer><silent> <F13> :call mdlist#Shift(1)<CR>
nnoremap <buffer><silent> <F14> :call mdlist#Shift(-1)<CR>
