# Set up the environment for the current platform and architecture
# Homebrew's variables, set directly instead of running `brew shellenv`
function brew_env() {
  export HOMEBREW_PREFIX="$1"
  export HOMEBREW_CELLAR="$1/Cellar"
  export HOMEBREW_REPOSITORY="$2"
  export PATH="$1/bin:$1/sbin:$PATH"
  export MANPATH="$1/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="$1/share/info:${INFOPATH:-}"
}

# Perform the setup for the given OS and architecture
case "$OSTYPE" in
  linux*) brew_env /usr/local /usr/local/Homebrew; export LINUX=1 ;;
  darwin*)
    case "$CPUTYPE" in
      x86_64) brew_env /usr/local /usr/local/Homebrew; export X86_MAC=1 ;;
      arm64) brew_env /opt/homebrew /opt/homebrew; export M1_MAC=1 ;;
    esac
    ;;
esac

# Environment variables
export EDITOR="vim"
export BROWSER="firefox-developer-edition"
export HOMEBREW_BUNDLE_FILE="$HOME/Brewfile"
export HOMEBREW_BUNDLE_NO_LOCK=1
export HOMEBREW_CASK_OPTS="--no-quarantine"
export LESSHISTFILE="-"
export NODE_REPL_HISTORY_FILE="$HOME/.history/node_history"
export PSQL_HISTORY="$HOME/.history/psql_history"

# Check if using the work laptop
if [ -f "$HOME/.work" ]; then
  export WORK=1

  # Skip any Mac App Store packages when using Homebrew on the work laptop
  export HOMEBREW_BUNDLE_MAS_SKIP="1099120373 1289583905 1333542190 1441135869 1552247688 1590135777 803453959 888422857 993487541"

  # Add ~/.bin/work commands to path
  export PATH="$HOME/.bin/work:$PATH"
fi

# Add GNU `gnubin` directories to PATH
if [[ -n $HOMEBREW_PREFIX ]]; then
  for directory in $HOMEBREW_PREFIX/opt/*/libexec/gnubin(N); do
    export PATH="$directory:$PATH"
  done
fi

# Add ~/.bin commands to path
export PATH="$HOME/.bin:$PATH"

# Add ~/.local/bin to path
export PATH="$HOME/.local/bin:$PATH"

# Add dart-sass-embedded to path
export PATH="$HOME/.bin/sass_embedded:$PATH"

# Add Python to path
export PATH="/opt/homebrew/opt/python@3.14/libexec/bin:$PATH"

# vim:ft=zsh
