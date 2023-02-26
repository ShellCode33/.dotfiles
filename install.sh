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

link ".config/dunst"
link ".config/sway"
link ".config/zsh"

link ".config/mimeapps.list"
link ".config/user-dirs.dirs"

link ".local/share/applications"
link ".local/share/wallpaper.jpg"
link ".local/bin" # Maybe I should link individual executables instead of the whole folder

# Global git config
git config --global user.email "shellcode33@protonmail.ch"
git config --global user.name "ShellCode33"

# Download icons pack (if you change it, don't forget to grep GruvboxPlus in the dotfiles)
git clone --depth 1 https://github.com/SylEleuth/gruvbox-plus-icon-pack.git ~/.local/share/icons/GruvboxPlus

# Create home directories
cut -s -d'"' -f2 .dotfiles/.config/user-dirs.dirs | sed "s|\$HOME|$HOME|g" | xargs -L 1 mkdir -p
