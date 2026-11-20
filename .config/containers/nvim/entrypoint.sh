#!/bin/sh
set -eu
umask 077

mkdir -p "$XDG_CONFIG_HOME/nvim"
cp -R /usr/local/share/nvim-config/. "$XDG_CONFIG_HOME/nvim/"

seed=/usr/local/share/nvim-data
if [ -f "$seed/.image-seed" ]; then
    data="$HOME/.local/share/nvim"
    mkdir -p "$data"
    (
        # Older images hold a shared lock while using the per-project copies.
        flock -x 9
        for directory in lazy mason site; do
            source="$seed/$directory"
            destination="$data/$directory"
            if [ ! -d "$source" ]; then
                printf 'nvim: Image dependency directory is missing: %s\n' "$source" >&2
                exit 1
            fi
            if [ -L "$destination" ] && [ "$(readlink -- "$destination")" = "$source" ]; then
                continue
            fi
            if [ -e "$destination" ] || [ -L "$destination" ]; then
                mv -T --backup=numbered -- "$destination" "$destination.before-image-share"
            fi
            ln -s -- "$source" "$destination"
        done
    ) 9>"${data%/*}/.nvim-seed.lock"
fi

if [ -n "${TERM:-}" ] && ! infocmp -x "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

exec "$@"
