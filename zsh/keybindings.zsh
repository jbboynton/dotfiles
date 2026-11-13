# Keybindings
# Check a key's sequence with: ctrl + v, then press the key

# Substring history search: ↑ and ↓
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Delete next character: fn + backspace or delete key
bindkey '^[[3~' delete-char

# Start/end of line (outside tmux): home key, end key, or fn + ←/→
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Start/end of line (inside tmux): home key, end key, or fn + ←/→
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Back/forward by word: option + ←/→
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

# Delete previous word: option + backspace
bindkey '^[^?' backward-kill-word

# Delete next word: option + fn + backspace
bindkey '^[[3;3~' kill-word
