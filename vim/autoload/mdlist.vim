" mdlist.vim - indent and outdent whole markdown list items.
"
" A list item is its marker line plus every following line that belongs
" to it: wrapped continuation lines, and nested items indented further
" than the marker. Shifting the range keeps relative indent, then the
" item is reflowed so continuation lines line up under the new marker
" position ('formatlistpat' is set by the markdown ftplugin and
" 'formatoptions' contains n).

let s:marker = '^\s*\%([-*+]\|\d\+[.)]\)\s\+'

" [start, end] of the list item under the cursor, or [] when not in one.
function! mdlist#Range() abort
  let l:s = line('.')
  while l:s > 1 && getline(l:s) !~# s:marker && getline(l:s) !~# '^\s*$'
    let l:s -= 1
  endwhile
  if getline(l:s) !~# s:marker
    return []
  endif

  let l:indent = indent(l:s)
  let l:e = l:s
  while l:e < line('$')
    let l:next = getline(l:e + 1)
    if l:next =~# '^\s*$'
      break
    endif
    " A marker at the same or shallower indent starts a different item.
    if l:next =~# s:marker && indent(l:e + 1) <= l:indent
      break
    endif
    let l:e += 1
  endwhile

  return [l:s, l:e]
endfunction

" dir > 0 indents, dir < 0 outdents.
function! mdlist#Shift(dir) abort
  let l:range = mdlist#Range()
  if empty(l:range)
    execute 'normal! ' . (a:dir > 0 ? '>>' : '<<')
    return
  endif

  let [l:s, l:e] = l:range
  let l:col = col('.')
  let l:off = line('.') - l:s
  execute 'silent ' . l:s . ',' . l:e . (a:dir > 0 ? '>' : '<')

  " Re-measure: the shift may have changed how far the item wraps.
  call cursor(l:s, 1)
  let l:range = mdlist#Range()
  if !empty(l:range)
    let [l:s, l:e] = l:range
    call cursor(l:s, 1)
    if l:e > l:s
      execute 'silent normal! gq' . (l:e - l:s) . 'j'
    else
      silent normal! gqgq
    endif
  endif

  call cursor(l:s + l:off, l:col)
endfunction
