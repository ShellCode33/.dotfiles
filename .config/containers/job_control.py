"""Relay terminal job control between a host shell and a Podman container."""

import os
import signal
import socket
import subprocess
import sys
import termios
from pathlib import Path


def has_job_control():
    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        return False
    group = os.getpgrp()
    session = os.getsid(0)
    parent = os.getppid()
    try:
        if group == session or os.tcgetpgrp(0) != group:
            return False
        while os.getsid(parent) == session:
            if os.getpgid(parent) != group:
                return True
            # A non-exec wrapper can share the shell job with the launcher.
            # In /proc/PID/stat, the state and parent PID follow the command name.
            stat = Path(f"/proc/{parent}/stat").read_bytes()
            parent = int(stat.rsplit(b")", 1)[1].split()[1])
    except OSError:
        pass
    return False


def wait_for_podman(process, control=None, shell_mode=None):
    def forward_signal(signum, _frame):
        process.send_signal(signum)

    previous_handlers = {
        signum: signal.signal(signum, forward_signal)
        for signum in (signal.SIGHUP, signal.SIGTERM)
    }
    try:
        if control is not None:
            relay_suspends(control, shell_mode)
        return process.wait()
    finally:
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)


def relay_suspends(control, shell_mode):
    while control.recv(1) == b"s":
        attached_mode = termios.tcgetattr(0)
        termios.tcsetattr(0, termios.TCSADRAIN, shell_mode)
        # A background continue must leave the terminal with the shell.
        while True:
            os.killpg(os.getpgrp(), signal.SIGSTOP)
            if os.tcgetpgrp(0) == os.getpgrp():
                break
        termios.tcsetattr(0, termios.TCSADRAIN, attached_mode)
        control.sendall(b"r")


def run_podman(args, image, command, *, job_control=False):
    if not job_control:
        with subprocess.Popen([*args, image, *command]) as process:
            return wait_for_podman(process)

    shell_mode = termios.tcgetattr(0)
    source = Path(__file__).read_text(encoding="utf-8")
    host, container = socket.socketpair()
    with host, container:
        descriptor = container.fileno()
        process = subprocess.Popen(
            [
                *args,
                f"--preserve-fd={descriptor}",
                image,
                "python3",
                "-c",
                source,
                str(descriptor),
                *command,
            ],
            pass_fds=(descriptor,),
        )
        container.close()
        try:
            return wait_for_podman(process, host, shell_mode)
        finally:
            host.close()
            termios.tcsetattr(0, termios.TCSADRAIN, shell_mode)


def run_in_foreground(command, control):
    # Give the application a non-orphaned process group and the container tty.
    pid = os.fork()
    if pid == 0:
        control.close()
        os.setpgid(0, 0)
        signal.signal(signal.SIGTTOU, signal.SIG_IGN)
        os.tcsetpgrp(0, os.getpgrp())
        # The runtime may block or ignore job-control signals before exec.
        job_signals = (signal.SIGTSTP, signal.SIGTTIN, signal.SIGTTOU, signal.SIGCONT)
        for signum in job_signals:
            signal.signal(signum, signal.SIG_DFL)
        signal.pthread_sigmask(signal.SIG_UNBLOCK, job_signals)
        os.execvp(command[0], command)

    def forward_signal(signum, _frame):
        try:
            os.killpg(pid, signum)
        except ProcessLookupError:
            try:
                os.kill(pid, signum)
            except ProcessLookupError:
                pass

    for signum in (signal.SIGHUP, signal.SIGTERM, signal.SIGINT):
        signal.signal(signum, forward_signal)

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


if __name__ == "__main__":
    with socket.socket(fileno=int(sys.argv[1])) as control:
        status = run_in_foreground(sys.argv[2:], control)
    sys.exit(128 - status if status < 0 else status)
