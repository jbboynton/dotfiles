" htmlformat.vim - edit HTML at Prettier's width, save it at the rendered
" text's.
"
" In the buffer, HTML is laid out by Prettier at its normal 80 columns.
" On disk, markup has no line limit and only rendered text wraps at 80:
" each write runs the buffer through trim, Prettier at an unlimited
" width, then bin/wrap_html_text, and writes the result, while the
" buffer keeps the version being edited. Opening a file lays it out at
" 80 again, unmodified.

" The project's own Prettier when it has one, like ALE, else the global.
function! s:Prettier() abort
  let l:local = findfile('node_modules/.bin/prettier', expand('%:p:h') . ';')
  return empty(l:local) ? 'prettier' : fnamemodify(l:local, ':p')
endfunction

" Lines run through a shell command, or v:null when it fails. Stderr is
" kept apart, so a warning can't end up in the file.
function! s:Filter(command, lines) abort
  let l:errors = tempname()
  let l:output = system(a:command . ' 2>' . shellescape(l:errors),
    \ join(a:lines, "\n") . "\n")
  let l:status = v:shell_error
  let l:message = filereadable(l:errors) ? readfile(l:errors, '', 1) : []
  call delete(l:errors)

  if l:status != 0
    echohl WarningMsg
    echomsg 'htmlformat: ' . split(a:command)[0] . ' failed'
      \ . (empty(l:message) ? '' : ': ' . l:message[0])
    echohl None
    return v:null
  endif

  let l:result = split(l:output, "\n", 1)
  if !empty(l:result) && l:result[-1] ==# ''
    call remove(l:result, -1)
  endif
  return l:result
endfunction

function! s:RunPrettier(lines, width) abort
  return s:Filter(s:Prettier() . ' --stdin-filepath '
    \ . shellescape(expand('%:p')) . ' --print-width ' . a:width, a:lines)
endfunction

" What the disk gets for the given buffer lines.
function! s:ForDisk(lines) abort
  let l:lines = map(copy(a:lines),
    \ {_, line -> substitute(line, '\s\+$', '', '')})
  while !empty(l:lines) && l:lines[-1] ==# ''
    call remove(l:lines, -1)
  endwhile

  let l:wide = s:RunPrettier(l:lines, 100000)
  let l:wrapped = l:wide is v:null ? v:null
    \ : s:Filter('wrap_html_text 80', l:wide)
  " Never lose a save: on a failure the trimmed text goes as it is.
  return l:wrapped is v:null ? l:lines : l:wrapped
endfunction

" Lay the buffer out at 80, leaving it unmodified and the change outside
" undo, so u can't bring back the on-disk layout.
function! s:LayOut() abort
  let l:lines = s:RunPrettier(getline(1, '$'), 80)
  if l:lines is v:null || l:lines ==# getline(1, '$')
    return
  endif

  let l:view = winsaveview()
  let l:undolevels = &l:undolevels
  setlocal undolevels=-1
  silent keepjumps call deletebufline('%', len(l:lines) + 1, '$')
  silent keepjumps call setline(1, l:lines)
  let &l:undolevels = l:undolevels
  setlocal nomodified
  call winrestview(l:view)
endfunction

function! htmlformat#Write() abort
  let l:file = expand('<afile>:p')
  let l:first = line("'[")
  let l:last = line("']")
  let l:lines = s:ForDisk(getline(l:first, l:last))

  if writefile(l:lines, l:file) != 0
    echohl ErrorMsg
    echomsg 'htmlformat: could not write ' . l:file
    echohl None
    return
  endif

  " Like :write, only a whole-buffer write to its own file saves it.
  if l:file ==# expand('%:p') && l:first == 1 && l:last == line('$')
    setlocal nomodified
  endif
  echo printf('"%s" %dL, %dB written', fnamemodify(l:file, ':~:.'),
    \ len(l:lines), getfsize(l:file))
  execute 'doautocmd <nomodeline> BufWritePost' fnameescape(l:file)
endfunction

function! htmlformat#Setup() abort
  augroup htmlformat
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call htmlformat#Write()
    " Another filetype for this buffer writes normally again.
    autocmd FileType <buffer> if &filetype !=# 'html'
      \ | execute 'autocmd! htmlformat * <buffer>' | endif
  augroup END

  if &buftype ==# '' && !&modified && filereadable(expand('%:p'))
    call s:LayOut()
  endif
endfunction
