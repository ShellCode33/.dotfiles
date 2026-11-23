"""Prepare persistent Codex state and run a command in the container."""

import fcntl
import os
import signal
import socket
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

AUTH_HOME = Path("/run/codex-auth")
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


def link_credentials(home):
    # Codex writes through auth.json symlinks. Share its refresh locks as well.
    with TemporaryDirectory(dir=home) as scratch:
        for name in ("auth.json", "auth.lock", "auth.json.lock"):
            link = home / name
            target = AUTH_HOME / name
            if link.is_symlink() and link.readlink() == target:
                continue
            staging = Path(scratch) / name
            staging.symlink_to(target)
            staging.replace(link)


def run_in_foreground(command, control):
    # The extra process group lets Codex's SIGTSTP take effect inside the PID namespace.
    pid = os.fork()
    if pid == 0:
        control.close()
        os.setpgid(0, 0)
        previous = signal.signal(signal.SIGTTOU, signal.SIG_IGN)
        os.tcsetpgrp(0, os.getpgrp())
        signal.signal(signal.SIGTTOU, previous)
        # Podman passes a blocked job-control signal mask to the container.
        signal.pthread_sigmask(
            signal.SIG_UNBLOCK, (signal.SIGTSTP, signal.SIGTTIN, signal.SIGTTOU)
        )
        os.execvp(command[0], command)

    while True:
        _, status = os.waitpid(pid, os.WUNTRACED)
        if not os.WIFSTOPPED(status):
            return os.waitstatus_to_exitcode(status)
        try:
            control.sendall(b"s")
            if control.recv(1) == b"r":
                os.killpg(pid, signal.SIGCONT)
                continue
        except (BrokenPipeError, ConnectionResetError):
            pass
        os.killpg(pid, signal.SIGKILL)


def main():
    *command, descriptor = sys.argv[1:]
    if command[:2] == ["/usr/bin/codex", "logout"]:
        # Codex removes auth.json itself during logout, so give it the shared directory.
        os.environ["CODEX_HOME"] = str(AUTH_HOME)
    else:
        home = Path(os.environ["CODEX_HOME"])
        migrate_daemon_selection(home)
        link_credentials(home)
    if descriptor == "-1":
        os.execvp(command[0], command)
    with socket.socket(fileno=int(descriptor)) as control:
        status = run_in_foreground(command, control)
        sys.exit(128 - status if status < 0 else status)


if __name__ == "__main__":
    main()
