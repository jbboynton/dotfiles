# Zsh configuration

# completion
fpath=(~/.zsh/completion $fpath)

autoload -Uz compinit promptinit
compinit
promptinit

compdef g=git

# history
HISTSIZE=100000000000000
HISTFILE=~/.zsh_history
SAVEHIST=100000000000000

source ~/.zplug/init.zsh

zplug "mafredri/zsh-async"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-history-substring-search", defer:3

zplug load

# more config
for zsh_source in $HOME/.zsh/configs/*.zsh; do
  source $zsh_source
done

if [ "$(tty)" = "/dev/tty1" ]; then
  pgrep i3 || startx
fi

tat
