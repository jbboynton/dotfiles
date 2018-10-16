autoload -Uz compinit promptinit
compinit
promptinit

prompt walters

HISTSIZE=20000
HISTFILE=~/.zsh_history
SAVEHIST=20000

export EDITOR="vim"
export PATH="$HOME/bin:$PATH"

if [ "$(tty)" = "/dev/tty1" ]; then
  pgrep i3 || startx
fi
