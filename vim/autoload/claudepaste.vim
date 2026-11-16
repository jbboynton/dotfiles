" Paste into a reply to Claude (the buffer bin/claude_edit opens).
"
" Ctrl-V there calls claudepaste#Paste(). Ordinary text is pasted as it
" is. A file copied in Finder, an image on the clipboard, or a long
" stretch of text is pasted as a label, [Image #1], and a line for it is
" added at the end of the buffer, after a blank line:
"
"     [Image #1]: file:///Users/james/Screenshots/shot.png
"
" so the reply reads cleanly and Claude can open what it refers to. Labels
" count up by kind: [Image #2], [Video #1], [File #1], [Text #1].
" bin/claude_paste reads the clipboard and saves what needs saving.

let s:reader = expand('~/.bin/claude_paste')

" Put lines of text into the buffer at the cursor, as if typed there, and
" leave the cursor after them
function! s:Insert(lines) abort
  let l:row = line('.')
  let l:col = col('.') - 1
  let l:line = getline(l:row)
  let l:head = strpart(l:line, 0, l:col)
  let l:tail = strpart(l:line, l:col)
  let l:new = copy(a:lines)
  let l:new[0] = l:head . l:new[0]
  let l:end = strlen(l:new[-1])
  let l:new[-1] .= l:tail
  call setline(l:row, l:new[0])
  call append(l:row, l:new[1:])
  call cursor(l:row + len(l:new) - 1, l:end + 1)
endfunction

" The next number for a label, one more than the highest in the buffer
function! s:Next(label) abort
  let l:highest = 0

  for l:line in getline(1, '$')
    let l:found = matchlist(l:line, '^\[' . a:label . ' #\(\d\+\)\]: ')

    if !empty(l:found)
      let l:highest = max([l:highest, str2nr(l:found[1])])
    endif
  endfor

  return l:highest + 1
endfunction

" Add a label's line at the end of the buffer, a blank line above the
" first of them
function! s:Refer(name, ref) abort
  if getline('$') !~# '^\[\a\+ #\d\+\]: '
    call append('$', '')
  endif

  call append('$', a:name . ': ' . a:ref)
endfunction

function! claudepaste#Paste() abort
  let l:reader = get(g:, 'claudepaste_reader', s:reader)
  let l:out = system(shellescape(l:reader))

  try
    let l:clip = json_decode(l:out)
  catch
    echohl WarningMsg | echo 'Could not read the clipboard' | echohl None
    return
  endtry

  if has_key(l:clip, 'text')
    call s:Insert(split(l:clip.text, "\n", 1))
    return
  endif

  if !has_key(l:clip, 'items')
    echo 'Nothing on the clipboard to paste'
    return
  endif

  let l:names = []

  for l:item in l:clip.items
    let l:name = '[' . l:item.label . ' #' . s:Next(l:item.label) . ']'
    call s:Refer(l:name, l:item.ref)
    call add(l:names, l:name)
  endfor

  call s:Insert([join(l:names, ' ')])
endfunction
