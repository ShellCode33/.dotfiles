"""Prepare persistent Codex state and run a command in the container."""

import fcntl
import os
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

AUTH_HOME = Path("/run/codex-auth")
PROFILES = Path("/run/codex-profiles")
DEFAULT_CONFIG = Path("/run/codex-config/config.toml")
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


def writable_config_path(home):
    # Prefer the dedicated writable mount, then CODEX_HOME itself, then the
    # runtime directory as a last resort.
    for candidate in (DEFAULT_CONFIG, home / "config.toml"):
        directory = candidate.parent
        if os.path.isdir(directory) and os.access(directory, os.W_OK):
            return candidate
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
    return runtime / "codex-config.toml"


def seed_trust(home):
    # Codex persists folder trust in config.toml. Point CODEX_HOME's config.toml
    # at a writable file and pre-trust the mounted project directories so the
    # first trust write does not fail on a read-only config.
    config = writable_config_path(home)
    try:
        config.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    except OSError:
        return
    try:
        text = config.read_text(encoding="utf-8")
    except OSError:
        text = ""

    directories = {Path.cwd()}
    if len(sys.argv) > 1:
        command = sys.argv[1:]
        for flag in ("--add-dir", "-C", "--cd"):
            for index, argument in enumerate(command):
                if argument == flag and index + 1 < len(command):
                    directories.add(Path(command[index + 1]))
                elif argument.startswith(flag + "="):
                    directories.add(argument.partition("=")[2])

    for directory in sorted(directories):
        entry = f'[projects."{directory}"]'
        if entry not in text:
            text = text.rstrip("\n") + "\n\n" + entry + '\ntrust_level = "trusted"\n'

    if not text:
        return

    try:
        config.write_text(text, encoding="utf-8")
    except OSError:
        return

    link = home / "config.toml"
    if link == config or (link.is_symlink() and link.readlink() == config):
        return
    try:
        with TemporaryDirectory(dir=home) as scratch:
            staging = Path(scratch) / "config.toml"
            staging.symlink_to(config)
            staging.replace(link)
    except OSError:
        pass


def main():
    command = sys.argv[1:]
    if command[:2] == ["/usr/bin/codex", "logout"]:
        # Codex removes auth.json itself during logout, so give it the shared directory.
        os.environ["CODEX_HOME"] = str(AUTH_HOME)
    else:
        home = Path(os.environ["CODEX_HOME"])
        migrate_daemon_selection(home)
        link_credentials(home)
        seed_trust(home)
        for profile in home.glob("*.config.toml"):
            try:
                if (
                    profile.is_symlink()
                    and not profile.exists()
                    and profile.readlink() == PROFILES / profile.name
                ):
                    profile.unlink(missing_ok=True)
            except FileNotFoundError:
                pass
        for profile in PROFILES.glob("*.config.toml"):
            try:
                (home / profile.name).symlink_to(profile)
            except FileExistsError:
                pass
    os.execvp(command[0], command)


if __name__ == "__main__":
    main()
