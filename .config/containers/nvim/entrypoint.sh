#!/bin/sh
set -eu
umask 077

# Give each container's LuaLS process writable, private log and metadata directories.
lua_ls_cache="$XDG_CACHE_HOME/nvim/lua-ls"
export LLS_LOG_PATH="${LLS_LOG_PATH:-$lua_ls_cache/log}"
export LLS_META_PATH="${LLS_META_PATH:-$lua_ls_cache/meta}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
cache="$XDG_CACHE_HOME/nvim"
mkdir -p -- "$LLS_LOG_PATH" "$LLS_META_PATH" "$state/swap" "$state/shada" "$cache"
tar -xf /opt/nvim-cache-seed/cache.tar -C "$cache"

if [ -n "${TERM:-}" ] && ! infocmp -x "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

exec "$@"
