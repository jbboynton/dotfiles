# # Uncomment to enable profiling
# zmodload zsh/zprof

# # Benchmark shell startup time
# time zsh -i -c exit

HISTSIZE=100000
HISTFILE=~/.history/zsh_history
SAVEHIST=100000

# Save each command's start time and duration
setopt EXTENDED_HISTORY
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=yellow,bold,underline'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=magenta,bold,underline'

# Create history directory if it doesn't exist
[ ! -d "$HOME/.history" ] && mkdir "$HOME/.history"

# Create wget directory if it doesn't exist
[ ! -d "$HOME/.wget" ] && mkdir "$HOME/.wget"

# Create zcompdump directory if it doesn't exist
[ ! -d "/tmp/zcompdump" ] && mkdir "/tmp/zcompdump"

# Use emacs keybindings
bindkey -e

# Zinit is weird...
# Initialize Zinit
source ~/.zinit/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load annexes
zinit lucid for \
  zdharma-continuum/z-a-rust \
  zdharma-continuum/zinit-annex-bin-gem-node

# Installation of Rust compiler environment via the z-a-rust annex
zinit id-as"rust" as=null sbin="bin/*" wait'0' lucid rustup for \
  atload=" \
    [[ ! -f ${ZINIT[COMPLETIONS_DIR]}/_cargo ]] && zinit creinstall -q rust; \
    export CARGO_HOME=\$PWD; \
    export RUSTUP_HOME=\$PWD/rustup" \
    zdharma-continuum/null

# Main Zinit invocation
zinit wait'0' lucid for \
  atinit" \
    ZINIT[ZCOMPDUMP_PATH]=/tmp/zcompdump; \
    zicompinit; \
    zicdreplay" \
    Aloxaf/fzf-tab \
    zdharma-continuum/fast-syntax-highlighting \
    zsh-users/zsh-history-substring-search \
  blockf atpull'zinit creinstall -q .' zsh-users/zsh-completions \
  htlsne/zinit-rbenv

# Custom completions
zinit wait'0' lucid for \
  atinit'custom_completions' as'null' zdharma-continuum/null

function custom_completions() {
  compdef g=git
}

# Load configs
for zsh_source in $HOME/.zsh/**/*; do
  source $zsh_source
done

# Start tmux
[ -n "$TMUX" ] || tat

# # Uncomment to enable profiling
# zprof | less
