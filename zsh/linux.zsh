# Linux-specific initialization

# X display server
if [ "$(tty)" = "/dev/tty1" ]; then
  pgrep i3 || startx
fi

# tmux
tat
