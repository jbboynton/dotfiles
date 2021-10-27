# # Uncomment to enable profiling
# zmodload zsh/zprof

export HOMEBREW_BUNDLE_CASK_SKIP=1
export HOMEBREW_BUNDLE_FILE="$HOME/Brewfile"
export HOMEBREW_BUNDLE_MAS_SKIP=1
export HOMEBREW_BUNDLE_NO_LOCK=1
export HOMEBREW_CASK_OPTS="--no-quarantine --require-sha"
export LESSHISTFILE="-"
export NODE_REPL_HISTORY_FILE="$HOME/.history/node_history"
export NVM_COMPLETION=1
export NVM_DIR="$HOME/.nvm"
export PSQL_HISTORY="$HOME/.history/psql_history"

HISTSIZE=10000000
HISTFILE=~/.history/zsh_history
SAVEHIST=10000000
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=yellow,bold,underline'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=magenta,bold,underline'

# Check if using the work laptop
[ -f "$HOME/.dotfiles/.work" ] && export WORK=1

# Create history directory if it doesn't exist
[ ! -d "$HOME/.history" ] && mkdir "$HOME/.history"

# Create wget directory if it doesn't exist
[ ! -d "$HOME/.wget" ] && mkdir "$HOME/.wget"

# Create zcompdump directory if it doesn't exist
[ ! -d "/tmp/zcompdump" ] && mkdir "/tmp/zcompdump"

# Add GNU `gnubin` directories to PATH
if type brew &>/dev/null; then
  for directory in $(brew --prefix)/opt/*/libexec/gnubin; do
    export PATH="$directory:$PATH"
  done
fi

# Add ~/.bin commands to path
export PATH="$HOME/.bin:$PATH"

# Use emacs keybindings
bindkey -e

# Initialize zinit
source ~/.zinit/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Zinit is weird...
zinit wait'0a' lucid light-mode for \
  atinit" \
      ZINIT[ZCOMPDUMP_PATH]=/tmp/zcompdump; \
      zicompinit; \
      zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
    OMZP::colored-man-pages \
    OMZ::plugins/nvm/nvm.plugin.zsh \
    htlsne/zinit-rbenv \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

zinit wait'0b' lucid light-mode for \
  atload"_history_substring_search_config" \
    zsh-users/zsh-history-substring-search

function _history_substring_search_config() {
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}

# Load annexes
zinit lucid light-mode for \
  zdharma-continuum/z-a-rust \
  zdharma-continuum/zinit-annex-bin-gem-node

# Installation of Rust compiler environment via the z-a-rust annex
zinit id-as"rust" as=null sbin="bin/*" lucid rustup for \
  atload=" \
      [[ ! -f ${ZINIT[COMPLETIONS_DIR]}/_cargo ]] && zinit creinstall -q rust; \
      export CARGO_HOME=\$PWD; \
      export RUSTUP_HOME=\$PWD/rustup" \
    zdharma-continuum/null

# Custom completions
zinit wait'0c' lucid light-mode for \
  atinit'compdef g=git' as'null' zdharma-continuum/null

# Load configs
for zsh_source in $HOME/.zsh/**/*; do
  source $zsh_source
done

# Start tmux
[ -n "$TMUX" ] || tat

# # Uncomment to enable profiling
# zprof | less
