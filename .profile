# Default user shell should be /bin/sh for POSIX compliance
# We can use ZSH in our terminal though
export SHELL=/usr/bin/zsh

# Desktop related variables
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway

# Force QT applications to use Wayland backend
export QT_QPA_PLATFORM=wayland

# Firefox specific
export MOZ_ENABLE_WAYLAND=1
export MOZ_WEBRENDER=1

# ZSH specific
export ZDOTDIR=~/.config/zsh

if [ "$(tty)" = "/dev/tty1" ] ; then
    exec "$XDG_CURRENT_DESKTOP"
fi
