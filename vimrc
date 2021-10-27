" Vim configuration
" Loads plugins and sources configurations in rcplugins and rcfiles

set nocompatible

" Need to set the leader before defining any leader mappings
let mapleader = "\<Space>"

" Source Vim configs in a directory.
function! s:SourceConfigFilesIn(directory)
  let directory_splat = '~/.vim/' . a:directory . '/*'
  for config_file in split(glob(directory_splat), '\n')
    if filereadable(config_file)
      execute 'source' config_file
    endif
  endfor
endfunction

" Load plugin config files
call plug#begin('~/.vim/bundle')
call s:SourceConfigFilesIn('rcplugins')
call plug#end()

" Load custom Vim configs
call s:SourceConfigFilesIn('rcfiles')
