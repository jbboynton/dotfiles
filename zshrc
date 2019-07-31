autoload -Uz compinit promptinit
compinit
promptinit

HISTSIZE=10000000
HISTFILE=~/.zsh_history
SAVEHIST=10000000

source ~/.zsh/aliases
source ~/.zsh/functions

source ~/.zplug/init.zsh

zplug "mafredri/zsh-async"
zplug "plugins/colored-man-pages", from:oh-my-zsh
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
