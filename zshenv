# Zshenv
# Read by every zsh, scripts and agent shells included, so nothing here
# may start a program

# mise's shims first on PATH, so a shell that reads neither zprofile nor
# zshrc still runs the version a project pins. What `mise activate zsh
# --shims` prints, written out (checked by `env_drift`); zsh/mise.zsh
# puts them first again after zprofile has added to PATH
path=($HOME/.local/share/mise/shims ${path:#$HOME/.local/share/mise/shims})
