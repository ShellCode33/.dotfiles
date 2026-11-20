#!/bin/sh
set -eu
umask 077
mkdir -p "$XDG_RUNTIME_DIR" "$HOME/.cache" "$HOME/.local/share/zed/extensions/installed"
# Only this image's declared extensions are restored; all editor state is ephemeral.
cp -a /opt/zed-extensions/. "$HOME/.local/share/zed/extensions/installed/"
if [ "${1:-}" = "--shell" ]; then
    shift
    exec /bin/bash "$@"
fi
# Reconcile persistent inner containers after the previous outer session ended.
podman ps --all --sync >/dev/null
if [ "${ZED_BOX_SOFTWARE_RENDERING:-0}" = 1 ]; then
    export LIBGL_ALWAYS_SOFTWARE=true
    for driver in /usr/share/vulkan/icd.d/lvp_icd*.json; do
        if [ -f "$driver" ]; then
            export VK_DRIVER_FILES="$driver" VK_ICD_FILENAMES="$driver"
            break
        fi
    done
    export ZED_ALLOW_EMULATED_GPU=1
fi
if [ "${XDG_SESSION_TYPE:-}" = x11 ]; then
    exec dbus-run-session -- /usr/local/lib/zed-box/x11/session "$@"
fi
exec dbus-run-session -- /opt/zed.app/bin/zed --foreground "$@"
