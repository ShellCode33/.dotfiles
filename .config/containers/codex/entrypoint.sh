#!/bin/sh
set -eu
umask 077

mkdir -p -- "$CODEX_HOME" "$XDG_RUNTIME_DIR"
if [ -n "${CODEX_PASTA_PROXY_PORTS:-}" ]; then
    export CONTAINERS_CONF_OVERRIDE="$XDG_RUNTIME_DIR/pasta-proxy.conf"
    printf '[network]\npasta_options = ["-T", "%s"]\n' "$CODEX_PASTA_PROXY_PORTS" >"$CONTAINERS_CONF_OVERRIDE"
fi
if [ -n "${TERM:-}" ] && ! infocmp -x "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi
exec "$@"
