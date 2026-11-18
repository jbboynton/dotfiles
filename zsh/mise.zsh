# Mise
# Per-project tool versions through mise's shims, without running it at startup

# What `mise activate zsh --shims` prints, written out. A shim runs the
# version its folder pins (.nvmrc for Node) and the system's elsewhere.
path=($HOME/.local/share/mise/shims ${path:#$HOME/.local/share/mise/shims})
