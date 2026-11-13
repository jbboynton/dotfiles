# Fzf
# Fuzzy-find history, files and folders from the command line

# Load fzf's bindings after the prompt is up
zinit wait'0' lucid for \
  id-as'fzf-bindings' as'null' atload'fzf_config' \
    zdharma-continuum/null

# Bindings: ctrl + r history, ctrl + t files, ctrl + p files and folders
function fzf_config() {
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"

  zle -N fzf-file-widget-ctrl-p
  bindkey '^P' fzf-file-widget-ctrl-p
}

# List paths for ctrl + p: the current folder first, then the rest of ~
function _fzf_ctrl_p_source() {
  local -a opts=(--hidden --follow --exclude .git --exclude node_modules
    --exclude Library --exclude .Trash --exclude .cache --exclude vendor)

  # Current folder, as relative paths
  fd $opts . 2>/dev/null

  # Already searched all of ~
  if [[ $PWD == $HOME ]]; then
    return
  fi

  # Skip the current folder when searching the rest of ~
  local -a skip=()

  if [[ $PWD == $HOME/* ]]; then
    skip=(--exclude "/${PWD#$HOME/}")
  fi

  # Rest of ~, as ~/ paths
  fd $opts $skip . $HOME 2>/dev/null | sed "s|^$HOME/|~/|"
}

# Ctrl + p: insert picked paths at the cursor, or cd into a lone folder
function fzf-file-widget-ctrl-p() {
  local -a picks
  local preview='f={}; f=${f/#\~/$HOME};
    if [[ -d $f ]]; then ls -A $f;
    else bat --color=always --style=plain $f 2>/dev/null || cat $f; fi'

  # Pick paths, tab marks several
  picks=("${(@f)$(_fzf_ctrl_p_source |
    fzf --multi --height 40% --reverse --scheme=path \
      --preview "$preview")}")
  picks=(${picks:#})

  # Nothing picked
  if (( ${#picks} == 0 )); then
    zle reset-prompt
    return
  fi

  # Empty line and one folder picked: go there
  local first=${picks[1]/#\~/$HOME}

  if [[ -z $BUFFER && ${#picks} -eq 1 && -d $first ]]; then
    BUFFER="cd ${(q)first}"
    zle accept-line
    return
  fi

  # Insert each pick, quoted, keeping ~/ unquoted
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
