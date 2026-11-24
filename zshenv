# Sourced by zsh at startup—use only in-process builtins and assignments.
# Anything that forks (a command, a $(...)) will slow every shell.

# mise's shims first on PATH, so a shell that reads neither zprofile nor
# zshrc still runs the version a project pins. What `mise activate zsh
# --shims` prints, written out (checked by `env_drift`); zsh/mise.zsh
# puts them first again after zprofile has added to PATH
path=($HOME/.local/share/mise/shims ${path:#$HOME/.local/share/mise/shims})

# fzf's colors, for every fzf (tmux popups too)
export FZF_DEFAULT_OPTS_FILE=$HOME/.config/fzf/fzfrc
