" Load Ruby syntax and modify it for the Brewfile DSL
source $VIMRUNTIME/syntax/ruby.vim
unlet b:current_syntax

syntax keyword brewfileDirective brew cask tap mas cask_args
highlight def link brewfileDirective Keyword

let b:current_syntax = "brewfile"
