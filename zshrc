# Zsh configuration

# Mac: use GNU sed instead of the system sed. Run brew info gnu-sed for info.
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

autoload -Uz compinit promptinit
compinit
promptinit

# completion
fpath=(~/.zsh/completion $fpath)

# history
HISTSIZE=1000000000
HISTFILE=~/.zsh_history
SAVEHIST=1000000000

# plugins
# Mac:
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

# Linux:
# source ~/.zplug/init.zsh

zplug "mafredri/zsh-async"
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "zsh-users/zsh-history-substring-search"

zplug load

# more config
for zsh_source in $HOME/.zsh/configs/*.zsh; do
  source $zsh_source
done

case "$OSTYPE" in
  darwin*)
  ;;
  linux*)
    # X display server
    if [ "$(tty)" = "/dev/tty1" ]; then
      pgrep i3 || startx
    fi

    # tmux
    tat
  ;;
esac
