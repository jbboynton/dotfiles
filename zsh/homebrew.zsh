# Homebrew
# Load Homebrew's zsh completions, in tmux panes that skip zprofile too

# Add Homebrew's completion functions to the completion path
fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
