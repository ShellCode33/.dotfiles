"""Prepare persistent Codex state and run a command in the container."""

import fcntl
import os
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

LEGACY_DAEMON_RELEASES = Path("/home/nvim/.codex/packages/app-server-daemon/releases")


def migrate_daemon_selection(home):
    package = home / "packages/app-server-daemon"
    current = package / "current"
    if not current.is_symlink() or current.exists():
        return

    with (package / "install.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if not current.is_symlink():
            return
        target = current.readlink()
        if target.parent != LEGACY_DAEMON_RELEASES:
            return
        relative = Path("releases") / target.name
        executable = package / relative / "bin/codex"
        if not executable.is_file() or not os.access(executable, os.X_OK):
            return
        # Publish the relative link atomically while holding Codex's install lock.
        with TemporaryDirectory(dir=package) as scratch:
            staging = Path(scratch) / "current"
            staging.symlink_to(relative)
            staging.replace(current)


def main():
    command = sys.argv[1:]
    migrate_daemon_selection(Path(os.environ["CODEX_HOME"]))
    os.execvp(command[0], command)


if __name__ == "__main__":
    main()
