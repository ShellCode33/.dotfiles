# shellcheck shell=sh
# Default user shell (in /etc/passwd) should be /bin/sh for POSIX compliance
# Terminal emulators that don't suck will default to using the SHELL variable
export SHELL=/usr/bin/zsh

# A few basics
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin"
export EDITOR='nvim'
export MANPAGER='/usr/bin/nvim -n -i NONE +Man!'
export PAGER='most'
export WORDCHARS='-_'
export LANG='en_US.UTF-8'

# Desktop related variables
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland

# Home directories
set -a
# shellcheck source=.config/user-dirs.dirs
. "$HOME/.config/user-dirs.dirs"
set +a

# Set LS_COLORS environment variable
# shellcheck source=.config/ls-colors
. "$XDG_CONFIG_HOME/ls-colors"

# Force QT applications to use Wayland backend
export QT_QPA_PLATFORM=wayland

# Force Electron applications to use Wayland backend
export ELECTRON_OZONE_PLATFORM_HINT=wayland

# Force SDL applications to use Wayland backend
export SDL_VIDEODRIVER=wayland

# KeepassXC specific
export KPXC_INITIAL_DIR="$XDG_DATA_HOME/keepassxc"

# Firefox specific
export MOZ_ENABLE_WAYLAND=1
export MOZ_WEBRENDER=1

# ZSH specific
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Python specific
export PYTHONSTARTUP="$XDG_CONFIG_HOME/python-startup.py"
export IPYTHONDIR="$XDG_CACHE_HOME/ipython" # I don't plan to configure it, put it in XDG_CONFIG_HOME instead if you want

# Go specific
export GOPATH="$XDG_DATA_HOME/go"

# NPM specific
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/config"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR/npm"

# Only for some AMD GPUs, including RX 6600
if lspci | grep -q 'RX 6600'; then
    export HSA_OVERRIDE_GFX_VERSION=10.3.0
fi

# llamacpp configuration
export LLAMA_BASE_URL="http://localhost:11434/v1"

case "$(tty)" in

    "/dev/tty1")
        # Run ssh-agent and export its variables
        eval "$(ssh-agent)" >/dev/null

        # Import all the environment variables into both dbus and systemd
        dbus-update-activation-environment --systemd --all

        "$XDG_BIN_HOME"/load-gtk-conf # See comments inside the script for why this is needed
        mkdir -p "$XDG_STATE_HOME"
        exec /usr/bin/start-hyprland >"$XDG_STATE_HOME/hyprland.log" 2>&1
        ;;

    "/dev/tty"*)
        # Automatically logout after 10 minutes of inactivity for security purposes.
        export TMOUT=600
        exec "$SHELL"
        ;;

    *)
        exec "$SHELL"
        ;;
esac
