#!/bin/bash
# Sets up the environment for the current platform and architecture

x86_brew_env() {
  eval "$(/usr/local/bin/brew shellenv)"

  export PATH="/usr/local/bin:$PATH"
}

arm_brew_env() {
  eval "$(/opt/homebrew/bin/brew shellenv)"

  export PATH="/opt/homebrew/bin:$PATH"
}

case "$OSTYPE" in
  linux*) x86_brew_env; export LINUX=1 ;;
  darwin*)
    case "$(arch)" in
      i386) x86_brew_env; export X86_MAC=1 ;;
      arm64) arm_brew_env; export M1_MAC=1 ;;
    esac
    ;;
esac

