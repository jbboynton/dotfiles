" spellmenu.vim - spell checking with a wildmenu-style correction popup.
"
" Park the cursor on an error and the message line shows
"
"     Tab to fix: <first suggestion> | Shift + Tab to see all | Esc to ignore
"
" <Tab>       apply the first suggestion (or jump to the nearest error
"             when the cursor is not on one)
" <S-Tab>     open the horizontal popup and cycle through every choice
" <Esc>       ignore this error everywhere for the rest of the session
"
" Capitalisation checking is done here rather than by Vim. Vim's
" 'spellcapcheck' cannot be made to work for this:
"
"   * it highlights the whole word, and only the offending first letter
"     should be marked
"   * it does not treat a list item as the start of a sentence
"   * it cannot be taught about abbreviations. Vim hands the pattern a
"     string beginning at the period, so a lookbehind can never see the
"     'etc' in front of it. Verified: '\%(.\)\@<=' suppresses every caps
"     error and '\%(.\)\@<!' suppresses none.
"
" So 'spellcapcheck' is emptied and s:LineCaps() does the work.

let g:spellmenu_indicator = get(g:, 'spellmenu_indicator', '✎ ')

" Words the user chose to ignore for capitalisation, this session only.
let s:caps_ignore = get(s:, 'caps_ignore', {})

" Bumped by any ignore or add, so cached error lists are invalidated.
let s:gen = get(s:, 'gen', 0)

" The most recent ignore, so a second <Esc> on the same spot undoes it.
let s:last_ignore = get(s:, 'last_ignore', {})

" Abbreviations that end in a period. Exempted from spell checking, and
" their period does not end a sentence.
let s:abbrev = [
      \ 'approx', 'etc', 'al', 'cf', 'vs', 'ie', 'eg', 'e\.g', 'i\.e',
      \ 'Dr', 'Mr', 'Mrs', 'Ms', 'Prof', 'Rev', 'Hon', 'Sr', 'Jr',
      \ 'St', 'Ave', 'Rd', 'Blvd', 'Inc', 'Ltd', 'Co', 'Corp', 'Dept',
      \ 'Fig', 'Vol', 'No', 'Ed', 'pp', 'est', 'min', 'max', 'qty',
      \ ]
let s:abbrev_re = '\%(\<\%(' . join(s:abbrev, '\|') . '\)\)$'

" ---------------------------------------------------------------------
" Syntax exemptions
" ---------------------------------------------------------------------

" Do NOT add 'transparent' to these. A transparent item does not apply
" its own 'contains', so contains=@NoSpell is silently ignored and the
" exemption does nothing at all. The cost is that matched text renders
" without syntax colour.
function! spellmenu#Syntax() abort
  " Only touch buffers that are actually spell checked. These matches
  " carry no highlighting of their own, so applying them everywhere
  " repainted acronyms and paths in Normal colour: netrw directory
  " listings lost their colours and paths inside source comments turned
  " white.
  if !&spell
    return
  endif

  syntax match spellNoUrl `\v<\w+://\S+`
        \ contains=@NoSpell containedin=ALL
  syntax match spellNoUrl `\v<www\.\S+`
        \ contains=@NoSpell containedin=ALL
  syntax match spellNoUrl `\v<\S+\@\S+\.\a{2,}>`
        \ contains=@NoSpell containedin=ALL

  " File paths. Both sides of every slash must be path characters, which
  " is what keeps this off HTML tags: in '</strong>' the slash is
  " preceded by '<', and in '/>' it is followed by '>'. An earlier
  " version used \S+/\S+ and matched closing tags, splicing itself into
  " the htmlTag region so the region never closed and every following
  " line stayed highlighted as HTML.
  " Rooted paths: /var/tmp, ~/.vim/rcfiles, ./bin/run, ../a/b
  "
  " The lookbehind is load bearing twice over. Without it the optional
  " ~ / . prefix makes a bare "/word" look rooted, so copy/paste matched
  " on its "/paste"; and a match starting after '<' would eat the '/' of
  " an HTML closing tag.
  syntax match spellNoPath
        \ `\%([[:alnum:]<]\)\@<!\%(\~\|\.\.\|\.\)\?/[[:alnum:]_.~-]\+\%(/[[:alnum:]_.~-]\+\)*`
        \ contains=@NoSpell containedin=ALL

  " Unrooted paths need either two slashes (a/b/c) or a dotted last
  " segment (src/main.go). A single bare slash is deliberately not
  " enough, so prose like copy/paste and and/or keeps its normal colour
  " and stays spell checked.
  syntax match spellNoPath
        \ `[[:alnum:]_.~-]\+\%(/[[:alnum:]_.~-]\+\)\{2,}`
        \ contains=@NoSpell containedin=ALL
  syntax match spellNoPath
        \ `[[:alnum:]_.~-]\+/[[:alnum:]_~-]*\.[[:alnum:]]\+`
        \ contains=@NoSpell containedin=ALL

  " Bare filenames. Deliberately an explicit extension list rather than
  " \a\+, so ordinary prose like "U.S" or "approx." is not swallowed.
  syntax match spellNoPath
        \ `\v<[[:alnum:]_-]+\.(md|txt|vim|yml|yaml|json|toml|sh|zsh|rb|js|ts|py|go|css|html|conf|cfg|ini|lock|log|png|jpg|svg|pdf)>`
        \ contains=@NoSpell containedin=ALL

  " Acronyms and initialisms (PIB, ROI, USDA, PIBs, ROI's).
  syntax match spellNoAcronym `\v<\u[[:upper:][:digit:]]+%('s|s)?>`
        \ contains=@NoSpell containedin=ALL

  " Abbreviations. Only the abbreviation itself, so the word after it is
  " still spell checked; the capitalisation side is handled in Vimscript.
  execute 'syntax match spellNoAbbrev'
        \ . ' `\v<(' . join(s:abbrev, '|') . ')\.`'
        \ . ' contains=@NoSpell containedin=ALL'

  call spellmenu#ApplyIgnoreOnce()
endfunction

" ---------------------------------------------------------------------
" Finding errors
" ---------------------------------------------------------------------

function! s:InSkipRegion(lnum, col) abort
  for l:id in synstack(a:lnum, a:col)
    if synIDattr(l:id, 'name') =~? 'spellNo\|code\|url\|comment'
      return 1
    endif
  endfor
  return 0
endfunction

" Capitalisation errors on one line. A sentence starts at the first word
" of a list item, after a blank line or heading, at the top of the
" buffer, after a line ending in .?!, and after .?! mid-line.
function! s:LineCaps(lnum) abort
  let l:line = getline(a:lnum)
  if l:line =~# '^\s*$' || l:line =~# '^\s*#' || l:line =~# '^\s*[`~]\{3,}'
    return []
  endif

  let l:errs = []
  let l:prefix = matchstr(l:line,
        \ '^\s*\%(>\s*\)*\%(\%([-*+]\|\d\+[.)]\)\s\+\)\?')
  let l:is_list = l:prefix =~# '\%([-*+]\|\d\+[.)]\)\s'
  let l:prev = a:lnum > 1 ? getline(a:lnum - 1) : ''
  " An ellipsis is not the end of a sentence, with or without a closing
  " quote or bracket after it.
  let l:prev_ends = l:prev =~# '[.?!][")\]'']*\s*$'
        \ && l:prev !~# '\%(\.\.\.\|…\)[")\]'']*\s*$'
  let l:starts = a:lnum == 1 || l:is_list
        \ || l:prev =~# '^\s*$' || l:prev =~# '^\s*#'
        \ || l:prev_ends

  if l:starts
    let l:c = strlen(l:prefix)
    if l:line[l:c] =~# '\l'
      call add(l:errs, s:CapErr(a:lnum, l:c + 1, l:line))
    endif
  endif

  " Mid-line: a lowercase word after a sentence-ending .?!
  " Start past the prefix so a numbered list marker ("1. ") is not read
  " as the end of a sentence.
  let l:i = strlen(l:prefix)
  while 1
    let l:p = match(l:line, '[.?!]', l:i)
    if l:p < 0
      break
    endif
    let l:i = l:p + 1
    if strpart(l:line, 0, l:p) =~# s:abbrev_re
      continue
    endif
    " Skip a period that is part of an ellipsis, written either as three
    " periods or as the single character. Only the last period of '...'
    " reaches here with a space after it, so testing the two characters
    " before it is enough.
    if strpart(l:line, 0, l:p) =~# '\%(\.\.\|…\)$'
      continue
    endif
    let l:gap = matchstr(strpart(l:line, l:p + 1), '^[")\]'']*\s\+')
    if l:gap ==# ''
      continue
    endif
    let l:c = l:p + 1 + strlen(l:gap)
    if l:line[l:c] =~# '\l'
      call add(l:errs, s:CapErr(a:lnum, l:c + 1, l:line))
    endif
  endwhile

  return filter(l:errs, '!empty(v:val)')
endfunction

function! s:CapErr(lnum, col, line) abort
  let l:word = matchstr(strpart(a:line, a:col - 1), '^\k\+')
  if l:word ==# '' || has_key(s:caps_ignore, tolower(l:word))
        \ || s:InSkipRegion(a:lnum, a:col)
    return {}
  endif
  return {'lnum': a:lnum, 'col': a:col, 'len': strlen(l:word),
        \ 'word': l:word, 'kind': 'caps'}
endfunction

" Misspellings, found with ]s so that @NoSpell regions are respected.
" spellbadword() cannot be used here: it consults the dictionary
" directly and ignores syntax exemptions entirely.
"
" Save the whole view, not just the cursor. The ]s walk scrolls the
" window, and restoring only the cursor leaves it scrolled, so the text
" jumped on InsertLeave whenever the buffer was taller than the window.
function! s:BadWords() abort
  let l:save = winsaveview()
  let l:ws = &wrapscan
  set wrapscan
  let l:out = []
  let l:seen = {}
  call cursor(1, 1)
  for l:i in range(1, 500)
    silent! normal! ]s
    let l:k = line('.') . ':' . col('.')
    if has_key(l:seen, l:k)
      break
    endif
    let l:seen[l:k] = 1
    let l:w = expand('<cword>')
    " ]s does not move when the buffer has no misspellings, so without
    " this check the word under the cursor is reported as an error on a
    " perfectly clean file. spellbadword() is only consulted to confirm
    " a word ]s already landed on, so its blindness to @NoSpell regions
    " does not matter here.
    if spellbadword(l:w)[0] ==# ''
      continue
    endif
    call add(l:out, {'lnum': line('.'), 'col': col('.'), 'len': strlen(l:w),
          \ 'word': l:w, 'kind': 'bad'})
  endfor
  let &wrapscan = l:ws
  call winrestview(l:save)
  return l:out
endfunction

" All errors in the buffer, cached until the buffer changes.
"
" The cache key includes s:gen as well as b:changedtick. Ignoring or
" adding a word does not modify the buffer, so keying on changedtick
" alone handed back the stale list and the word stayed flagged.
function! spellmenu#Errors() abort
  let l:key = b:changedtick . ':' . s:gen
  if get(b:, 'spellmenu_tick', '') ==# l:key
    return b:spellmenu_errors
  endif

  let l:errs = []
  if &spell
    let l:errs += s:BadWords()
    for l:ln in range(1, line('$'))
      let l:errs += s:LineCaps(l:ln)
    endfor
    call sort(l:errs, function('s:ByPos'))
    let l:errs = s:Dedupe(l:errs)
  endif

  let b:spellmenu_errors = l:errs
  let b:spellmenu_tick = l:key
  return l:errs
endfunction

" One entry per position. A word that is both misspelled and
" sentence-initial is reported as a misspelling; fixing the spelling
" leaves the capitalisation error behind for the next <Tab>.
function! s:Dedupe(errs) abort
  let l:seen = {}
  let l:out = []
  for l:e in a:errs
    let l:k = l:e.lnum . ':' . l:e.col
    if has_key(l:seen, l:k)
      if l:e.kind ==# 'bad' && l:out[l:seen[l:k]].kind ==# 'caps'
        let l:out[l:seen[l:k]] = l:e
      endif
      continue
    endif
    let l:seen[l:k] = len(l:out)
    call add(l:out, l:e)
  endfor
  return l:out
endfunction

function! s:ByPos(a, b) abort
  return a:a.lnum == a:b.lnum ? a:a.col - a:b.col : a:a.lnum - a:b.lnum
endfunction

function! spellmenu#ErrorAtCursor() abort
  if !&spell
    return {}
  endif
  let l:l = line('.')
  let l:c = col('.')
  for l:e in spellmenu#Errors()
    if l:e.lnum == l:l && l:c >= l:e.col && l:c < l:e.col + l:e.len
      return l:e
    endif
  endfor
  return {}
endfunction

" Nearest error to the cursor. Anything on the current line beats
" anything on another line.
function! s:Nearest() abort
  let l:best = {}
  let l:score = []
  for l:e in spellmenu#Errors()
    let l:s = l:e.lnum == line('.')
          \ ? [0, abs(l:e.col - col('.'))]
          \ : [1, abs(l:e.lnum - line('.')), l:e.lnum < line('.')]
    if empty(l:score) || l:s[0] < l:score[0]
          \ || (l:s[0] == l:score[0] && l:s[1] < l:score[1])
      let l:score = l:s
      let l:best = l:e
    endif
  endfor
  return l:best
endfunction

" ---------------------------------------------------------------------
" Choices
" ---------------------------------------------------------------------

function! s:Suggestions(err) abort
  if a:err.kind ==# 'caps'
    return [toupper(a:err.word[0]) . strpart(a:err.word, 1)]
  endif
  return spellsuggest(a:err.word, 8)
endfunction

function! s:Items(err) abort
  return s:Suggestions(a:err) + ['Ignore...', 'Add...']
endfunction

function! s:Apply(err, choice) abort
  if a:choice ==# 'Ignore...'
    call s:Ignore(a:err)
  elseif a:choice ==# 'Add...'
    silent execute 'spellgood ' . fnameescape(a:err.word)
    let s:gen += 1
    let s:caps_ignore[tolower(a:err.word)] = 1
    call s:Say('Added ' . a:err.word . ' to the spell file')
  else
    call s:Replace(a:err, a:choice)
  endif
  call spellmenu#Refresh()
endfunction

function! s:Ignore(err) abort
  " Ignore the word for capitalisation as well as spelling, whichever
  " kind was reported. A misspelled word that also begins a sentence
  " carries both errors at the same position, so silencing only the
  " spelling leaves the capitalisation error sitting there and the
  " ignore looks like it did nothing.
  let s:caps_ignore[tolower(a:err.word)] = 1
  if a:err.kind !=# 'caps'
    " Session wide, every buffer, never written to the spell file.
    silent execute 'spellgood! ' . fnameescape(a:err.word)
  endif
  let s:gen += 1
  let s:last_ignore = copy(a:err)
  call s:Say('Ignoring ' . a:err.word
        \ . ' for this session | Esc to undo')
endfunction

" Take back the most recent ignore.
function! s:Unignore() abort
  let l:e = s:last_ignore
  let s:last_ignore = {}
  if has_key(s:caps_ignore, tolower(l:e.word))
    unlet s:caps_ignore[tolower(l:e.word)]
  endif
  if l:e.kind !=# 'caps'
    silent execute 'spellundo! ' . fnameescape(l:e.word)
  endif
  let s:gen += 1
  call spellmenu#Refresh()
  call s:Say('No longer ignoring ' . l:e.word)
endfunction

" Echo without tripping the hit-enter prompt. Redrawing first clears
" whatever else was on the command line, and the message is trimmed to
" the window width so Vim never has to page it.
function! s:Say(msg) abort
  let s:hint_shown = 0
  redraw
  echohl ModeMsg
  echo strpart(a:msg, 0, &columns - 12)
  echohl None
endfunction

function! s:Replace(err, new) abort
  let l:line = getline(a:err.lnum)
  let l:s = a:err.col - 1
  call setline(a:err.lnum, strpart(l:line, 0, l:s) . a:new
        \ . strpart(l:line, l:s + a:err.len))
  call cursor(a:err.lnum, l:s + 1)
endfunction

" Fix capitalization in the lines the last insert touched, and the line
" after them, which a new period can turn into a sentence start. Only
" what was just typed: text that was already there, or pasted, is marked
" and left for <Tab>.
"
" `u` takes a fix back, and the word then shows as an error that <Esc>
" ignores. The tick check keeps an insert that typed nothing from fixing
" it again: after an undo, '[ and '] sit on the undone lines.
"
" Set g:spellmenu_autocaps to 0 to turn this off.
function! spellmenu#AutoCaps() abort
  if !&spell || !&modifiable || !get(g:, 'spellmenu_autocaps', 1)
        \ || get(b:, 'spellmenu_typed', b:changedtick) == b:changedtick
    return
  endif

  let l:first = max([line("'["), 1])
  let l:last = min([line("']") + 1, line('$')])

  for l:lnum in range(l:first, l:last)
    for l:e in s:LineCaps(l:lnum)
      let l:line = getline(l:lnum)
      call setline(l:lnum, strpart(l:line, 0, l:e.col - 1)
            \ . toupper(l:line[l:e.col - 1]) . strpart(l:line, l:e.col))
    endfor
  endfor
endfunction

" ---------------------------------------------------------------------
" Key handling
" ---------------------------------------------------------------------

function! spellmenu#Tab() abort
  let l:err = spellmenu#ErrorAtCursor()
  if !empty(l:err)
    let l:sugg = s:Suggestions(l:err)
    if !empty(l:sugg)
      call s:Apply(l:err, l:sugg[0])
    endif
    return
  endif

  let l:near = s:Nearest()
  if empty(l:near)
    return
  endif
  call cursor(l:near.lnum, l:near.col)
endfunction

function! spellmenu#Menu() abort
  let l:err = spellmenu#ErrorAtCursor()
  if empty(l:err)
    return
  endif
  call s:OpenPopup(l:err)
endfunction

function! spellmenu#Escape() abort
  let l:err = spellmenu#ErrorAtCursor()

  " Nothing flagged here. If the previous <Esc> ignored a word at this
  " very spot, a second <Esc> takes it back.
  if empty(l:err)
    if !empty(s:last_ignore)
          \ && s:last_ignore.lnum == line('.')
          \ && col('.') >= s:last_ignore.col
          \ && col('.') < s:last_ignore.col + s:last_ignore.len
      call s:Unignore()
    endif
    return
  endif

  call s:Ignore(l:err)
  call spellmenu#Refresh()
endfunction

function! spellmenu#Hint() abort
  let l:err = spellmenu#ErrorAtCursor()
  if empty(l:err)
    if get(s:, 'hint_shown', 0)
      let s:hint_shown = 0
      echo ''
    endif
    return
  endif

  let l:sugg = s:Suggestions(l:err)
  let l:fix = empty(l:sugg) ? '(no suggestion)' : l:sugg[0]
  let s:hint_shown = 1
  echohl ModeMsg
  echo 'Tab to fix: ' . l:fix
        \ . ' | Shift + Tab to see all | Esc to ignore'
  echohl None
endfunction

" ---------------------------------------------------------------------
" The popup, laid out horizontally like the command-line wildmenu
" ---------------------------------------------------------------------

function! s:OpenPopup(err) abort
  let s:items = s:Items(a:err)
  let s:err = a:err
  let s:sel = 0

  if empty(prop_type_get('spellmenuSel'))
    call prop_type_add('spellmenuSel', {'highlight': 'WildMenu'})
  endif

  " popup_create draws no border by default, unlike popup_menu.
  let s:popup = popup_create([{'text': '', 'props': []}], {
        \ 'line': 'cursor+1',
        \ 'col': 'cursor',
        \ 'pos': 'topleft',
        \ 'padding': [0, 0, 0, 0],
        \ 'highlight': 'Pmenu',
        \ 'mapping': 0,
        \ 'filter': function('s:PopupFilter'),
        \ 'callback': function('s:PopupDone'),
        \ })
  call s:Render()
endfunction

function! s:Render() abort
  let l:text = ''
  let l:props = []
  for l:i in range(len(s:items))
    let l:chunk = ' ' . s:items[l:i] . ' '
    if l:i == s:sel
      call add(l:props, {'col': strlen(l:text) + 1,
            \ 'length': strlen(l:chunk), 'type': 'spellmenuSel'})
    endif
    let l:text .= l:chunk
  endfor
  call popup_settext(s:popup, [{'text': l:text, 'props': l:props}])
endfunction

function! s:PopupFilter(id, key) abort
  if a:key ==# "\<Tab>" || a:key ==# "\<Right>"
    let s:sel = (s:sel + 1) % len(s:items)
    call s:Render()
    return 1
  elseif a:key ==# "\<S-Tab>" || a:key ==# "\<Left>"
    let s:sel = (s:sel - 1 + len(s:items)) % len(s:items)
    call s:Render()
    return 1
  elseif a:key ==# "\<CR>" || a:key ==# "\<Space>"
    call popup_close(a:id, s:sel + 1)
    return 1
  elseif a:key ==# "\<Esc>" || a:key ==# "\<C-c>"
    call popup_close(a:id, 0)
    return 1
  endif
  return 1
endfunction

function! s:PopupDone(id, result) abort
  if a:result <= 0
    return
  endif
  call s:Apply(s:err, s:items[a:result - 1])
endfunction

" ---------------------------------------------------------------------
" Highlighting and the lightline indicator
" ---------------------------------------------------------------------

highlight default link SpellCapFirst SpellCap

function! s:ClearMatches() abort
  for l:id in get(w:, 'spellmenu_ids', [])
    silent! call matchdelete(l:id)
  endfor
  let w:spellmenu_ids = []
endfunction

function! spellmenu#Refresh() abort
  call s:ClearMatches()
  if &spell
    let l:pos = []
    for l:e in spellmenu#Errors()
      if l:e.kind ==# 'caps'
        call add(l:pos, [l:e.lnum, l:e.col, 1])
      endif
    endfor
    " matchaddpos takes at most eight positions per call.
    for l:i in range(0, len(l:pos) - 1, 8)
      call add(w:spellmenu_ids,
            \ matchaddpos('SpellCapFirst', l:pos[l:i : l:i + 7]))
    endfor
  endif
  if exists('*lightline#update')
    call lightline#update()
  endif
endfunction

function! spellmenu#Lightline() abort
  if !&spell
    return ''
  endif
  let l:n = len(spellmenu#Errors())
  return l:n == 0 ? '' : g:spellmenu_indicator . l:n
endfunction

" ---------------------------------------------------------------------
" Ignore-once support, kept for the syntax hook
" ---------------------------------------------------------------------

let s:ignore_once = get(s:, 'ignore_once', {})

function! spellmenu#ApplyIgnoreOnce() abort
  for l:e in get(s:ignore_once, bufnr('%'), [])
    execute printf(
          \ 'syntax match spellIgnoreOnce /\%%%dl\%%%dc%s/ '
          \ . 'contains=@NoSpell containedin=ALL',
          \ l:e.lnum, l:e.col, escape(l:e.word, '/\'))
  endfor
endfunction
