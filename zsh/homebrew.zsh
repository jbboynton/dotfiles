# Homebrew
# Load Homebrew's zsh completions, in tmux panes that skip zprofile too

# Add Homebrew's completion functions to the completion path
fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

# Run brew without GNU coreutils and findutils first on PATH: it expects
# the BSD tools, and `brew doctor` warns when it finds the GNU ones
brew() {
  local gnu='*/(coreutils|findutils)/libexec/gnubin'

  PATH=${(j.:.)${path:#$~gnu}} command brew "$@"
}
