# Fzf-tab
# Settings for fzf-tab, which swaps zsh's completion menu for fzf

# Hand the completion menu to fzf-tab
zstyle ':completion:*' menu no

# Preview folders when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -a1 --color=always --group-directories-first $realpath'

# Tab fills in the highlighted completion, like zsh's own menu
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
