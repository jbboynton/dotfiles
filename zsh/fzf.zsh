# fzf's own bindings: Ctrl-R (history), Ctrl-T (files), Alt-C (cd).
source <(fzf --zsh)

# Ctrl-P: fuzzy-find files and folders, current directory first, then
# everything else under ~. Enter inserts the picks at the cursor; on an
# empty line, picking a single folder cd's into it. Tab marks several.

# Print paths for fzf: relative ones for the current directory, then
# ~-prefixed ones for the rest of $HOME.
function _fzf_ctrl_p_source() {
  local -a opts=(--hidden --follow --exclude .git --exclude node_modules
    --exclude Library --exclude .Trash --exclude .cache --exclude vendor)
  fd $opts . 2>/dev/null
  if [[ $PWD == $HOME ]]; then
    return
  fi
  local -a skip=()
  if [[ $PWD == $HOME/* ]]; then
    skip=(--exclude "/${PWD#$HOME/}")
  fi
  fd $opts $skip . $HOME 2>/dev/null | sed "s|^$HOME/|~/|"
}

function fzf-file-widget-ctrl-p() {
  local -a picks
  local preview='f={}; f=${f/#\~/$HOME};
    if [[ -d $f ]]; then ls -A $f;
    else bat --color=always --style=plain $f 2>/dev/null || cat $f; fi'
  picks=("${(@f)$(_fzf_ctrl_p_source |
    fzf --multi --height 40% --reverse --scheme=path \
      --preview "$preview")}")
  picks=(${picks:#})

  if (( ${#picks} == 0 )); then
    zle reset-prompt
    return
  fi

  # Empty line and one folder picked: go there.
  local first=${picks[1]/#\~/$HOME}
  if [[ -z $BUFFER && ${#picks} -eq 1 && -d $first ]]; then
    BUFFER="cd ${(q)first}"
    zle accept-line
    return
  fi

  local p
  for p in $picks; do
    if [[ $p == '~/'* ]]; then
      LBUFFER+="~/${(q)p#\~/} "
    else
      LBUFFER+="${(q)p} "
    fi
  done
  zle reset-prompt
}
zle -N fzf-file-widget-ctrl-p
bindkey '^P' fzf-file-widget-ctrl-p
