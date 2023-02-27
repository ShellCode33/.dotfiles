# Default user shell (in /etc/passwd) should be /bin/sh for POSIX compliance
# Terminal emulators that don't suck will default to using the SHELL variable
export SHELL=/usr/bin/zsh

# A few basics
export PATH="/usr/local/bin:/usr/bin:$HOME/.local/bin"
export EDITOR='nvim'
export MANPAGER='nvim +Man!'
export PAGER='most'
export WORDCHARS='-_'
export LANG='en_US.UTF-8'

# Desktop related variables
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Home directories
set -a
. .config/user-dirs.dirs
set +a

# Set LS_COLORS environment variable
source "$XDG_CONFIG_HOME/ls-colors"

# Force QT applications to use Wayland backend
export QT_QPA_PLATFORM=wayland

# Firefox specific
export MOZ_ENABLE_WAYLAND=1
export MOZ_WEBRENDER=1

# ZSH specific
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Start graphical server on user's current tty if not already running.
if [ "$(tty)" = "/dev/tty1" ] && ! pidof -s "$XDG_CURRENT_DESKTOP" >/dev/null 2>&1
then
    exec "$XDG_CURRENT_DESKTOP" >"$XDG_STATE_HOME/$XDG_CURRENT_DESKTOP.log" 2>&1
fi
