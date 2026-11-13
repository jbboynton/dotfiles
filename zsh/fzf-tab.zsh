# Fzf-tab
# Settings for fzf-tab, which swaps zsh's completion menu for fzf

# Hand the completion menu to fzf-tab
zstyle ':completion:*' menu no

# Preview folders when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -a1 --color=always --group-directories-first $realpath'

# Tab and shift + tab move through the list, wrapping at the ends; enter picks
zstyle ':fzf-tab:*' fzf-bindings 'tab:down' 'btab:up'
zstyle ':fzf-tab:*' fzf-flags --cycle
