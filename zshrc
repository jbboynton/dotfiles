autoload -Uz compinit promptinit
compinit
promptinit

# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

prompt walters

HISTSIZE=20000
HISTFILE=~/.zsh_history
SAVEHIST=20000

tat

if [ "$(tty)" = "/dev/tty1" ]; then
  pgrep i3 || startx
fi
