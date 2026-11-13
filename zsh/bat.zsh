# Bat
# Show man pages through bat, using bat-extras' batman

# What `batman --export-env` prints, written out so it costs nothing at startup
export MANPAGER="env BATMAN_IS_BEING_MANPAGER=yes bash $HOME/.local/bin/batman"
export MANROFFOPT="-c"
