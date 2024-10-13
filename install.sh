#!/bin/bash

set -eo pipefail
trap on_error ERR
exec 2> >(while read -r line; do echo -e "\e[01;31m$line\e[0m"; done)

dotfiles_dir="$(
  cd "$(dirname "$0")"
  pwd
)"
cd "$dotfiles_dir"

on_error() {
  ret=$?
  echo "[$0] Error on line $LINENO: $BASH_COMMAND"
  exit $ret
}

link() {
  orig_file="$dotfiles_dir/$1"
  if [ -n "$2" ]; then
    dest_file="$HOME/$2"
  else
    dest_file="$HOME/$1"
  fi

  mkdir -p "$(dirname "$orig_file")"
  mkdir -p "$(dirname "$dest_file")"

  rm -rf "$dest_file"
  ln -s "$orig_file" "$dest_file"
  echo "$dest_file -> $orig_file"
}

link ".profile"

link ".config/fontconfig"
link ".config/gtk-3.0"
link ".config/dunst"
link ".config/wezterm"
link ".config/sway"
link ".config/zsh"
link ".config/gdb"
link ".config/git"
link ".config/gammastep"
link ".config/kanshi"
link ".config/nvim"
link ".config/ruff"

link ".config/ls-colors"
link ".config/chromium-flags.conf"
link ".config/electron-flags.conf"
link ".config/python-startup.py"

link ".config/mimeapps.list"
link ".config/user-dirs.dirs"

link ".mozilla/firefox/user-overrides.js"

link ".local/share/applications"
link ".local/share/wallpaper.jpg"
link ".local/bin" # Maybe I should link individual executables instead of the whole folder

# Create home directories
cut -s -d'"' -f2 "$HOME/.config/user-dirs.dirs" | sed "s|\$HOME|$HOME|g" | xargs -L 1 mkdir -p
mkdir "$HOME/dev"

# Source XDG variables
source "$HOME/.config/user-dirs.dirs"

# Mark download folder nodatacow
chattr +C "$XDG_DOWNLOAD_DIR"

# Mark cache folder nodatacow
chattr +C "$XDG_CACHE_HOME"

# Mark firefox nodatacow
mkdir -p "$HOME/.mozilla"
chattr +C "$HOME/.mozilla"

# Mark chromium nodatacow
mkdir -p "$XDG_CONFIG_HOME/chromium"
chattr +C "$XDG_CONFIG_HOME/chromium"

# Configure Rust toolchain
rustup default stable

current_user="$(whoami)"
if [ "$current_user" != "shellcode" ]; then
  # Change my username by your own
  grep -rl shellcode --exclude install.sh --exclude-dir .git | xargs sed -i "s/shellcode/$current_user/g"

  # Remove my git config, create your own if needed
  rm .config/git/config
fi
