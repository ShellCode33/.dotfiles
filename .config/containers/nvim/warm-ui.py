"""Attach a minimal UI so the build can warm Neovim's interactive startup."""

import subprocess
import sys

import msgpack

with subprocess.Popen(
    ["nvim", "--embed", *sys.argv[1:]],
    stdin=subprocess.PIPE,
    stdout=subprocess.DEVNULL,
) as nvim:
    nvim.stdin.write(msgpack.packb([0, 1, "nvim_ui_attach", [100, 30, {"rgb": True}]]))
    nvim.stdin.flush()
    try:
        status = nvim.wait(timeout=60)
    except subprocess.TimeoutExpired:
        nvim.kill()
        raise SystemExit("Neovim UI warmup timed out") from None
    raise SystemExit(status)
