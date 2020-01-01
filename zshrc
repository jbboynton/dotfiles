# Zsh configuration

autoload -Uz compinit promptinit
compinit
promptinit

# completion
fpath=(~/.zsh/completion $fpath)

# history
HISTSIZE=10000000
HISTFILE=~/.zsh_history
SAVEHIST=10000000

# plugins
source ~/.zplug/init.zsh

zplug "mafredri/zsh-async"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search"

zplug load

# more config
for zsh_source in $HOME/.zsh/configs/*.zsh; do
  source $zsh_source
done

# X display server
if [ "$(tty)" = "/dev/tty1" ]; then
  pgrep i3 || startx
fi

# tmux
tat
