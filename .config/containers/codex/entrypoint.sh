#!/bin/sh
set -eu
umask 077

mkdir -p -- "$CODEX_HOME" "$XDG_RUNTIME_DIR"
exec /usr/local/bin/nvim-entrypoint "$@"
