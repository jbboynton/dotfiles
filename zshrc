autoload -Uz compinit promptinit
compinit
promptinit

# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

prompt walters

HISTSIZE=20000
HISTFILE=~/.zsh_history
SAVEHIST=20000

source ~/.zsh/aliases
source ~/.zsh/functions
source ~/.zsh/prompt

source ~/.zplug/init.zsh

zplug "mafredri/zsh-async"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search"

zplug load

for zsh_source in $HOME/.zsh/configs/*.zsh; do
  source $zsh_source
done

if [ "$(tty)" = "/dev/tty1" ]; then
  pgrep i3 || startx
fi

tat
only_one_monitor -q
