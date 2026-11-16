# Rbenv
# Ruby versions through rbenv, set up without running it at startup

# What `rbenv init -` prints, written out so it costs nothing at startup. Its
# `rbenv rehash` is left out: rbenv rehashes when a gem adds a command.
path=($HOME/.rbenv/shims ${path:#$HOME/.rbenv/shims})
export RBENV_SHELL=zsh

# `rehash` and `shell` change this shell; everything else is the program
function rbenv() {
  local command="${1:-}"

  if (( $# > 0 )); then
    shift
  fi

  case "$command" in
    rehash|shell) eval "$(command rbenv "sh-$command" "$@")" ;;
    *) command rbenv "$command" "$@" ;;
  esac
}
