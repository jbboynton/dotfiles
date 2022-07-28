# Set up the environment for the current platform and architecture
# x86-specific setup
function x86_brew_env() {
  eval "$(/usr/local/bin/brew shellenv)"

  export PATH="/usr/local/bin:$PATH"
}

# ARM-specific setup
function arm_brew_env() {
  eval "$(/opt/homebrew/bin/brew shellenv)"

  export PATH="/opt/homebrew/bin:$PATH"
}

# Perform the setup for the given OS and architecture
case "$OSTYPE" in
  linux*) x86_brew_env; export LINUX=1 ;;
  darwin*)
    case "$(arch)" in
      i386) x86_brew_env; export X86_MAC=1 ;;
      arm64) arm_brew_env; export M1_MAC=1 ;;
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

function mac_app_ids() {
  ids="1099120373 1289583905 1333542190 1441135869 1552247688 1590135777 "
  ids+="803453959 803453959 888422857 993487541"

  echo "$ids"
}

# Check if using the work laptop
if [ -f "$HOME/.work" ]; then
  export WORK=1

  # Skip any Mac App Store packages when using Homebrew on the work laptop
  export HOMEBREW_BUNDLE_MAS_SKIP="$(mac_app_ids)"

  # Add ~/.bin/work commands to path
  export PATH="$HOME/.bin/work:$PATH"
fi

# Add GNU `gnubin` directories to PATH
if type brew &>/dev/null; then
  for directory in $(brew --prefix)/opt/*/libexec/gnubin; do
    export PATH="$directory:$PATH"
  done
fi

# Add ~/.bin commands to path
export PATH="$HOME/.bin:$PATH"

# vim:ft=zsh
