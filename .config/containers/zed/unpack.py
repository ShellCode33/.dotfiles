"""Runs inside the image build, after artifact hashes have been verified."""

import hashlib
import json
import shutil
import tarfile
import tomllib
from pathlib import Path

root = Path("/tmp/artifacts")
lock = json.loads((root / "artifacts.lock.json").read_text())
for item in [lock["zed"], *lock["extensions"], *lock["tools"]]:
    archive = root / item["file"]
    with archive.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    if digest != item["sha256"]:
        raise SystemExit(f"Hash mismatch: {archive.name}")
    if item in lock["tools"]:
        relative = Path(item["destination"])
        if relative.is_absolute() or ".." in relative.parts:
            raise SystemExit("Invalid tool destination")
        dest = Path("/opt/zed-tools") / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(archive, dest)
        dest.chmod(0o755 if relative.parts[0] == "bin" else 0o644)
        continue
    if item is lock["zed"]:
        dest = Path("/opt")
    else:
        dest = Path("/opt/zed-extensions") / item["id"]
    dest.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive) as tar:
        tar.extractall(dest, filter="data")
    if item in lock["extensions"]:
        manifest = tomllib.loads((dest / "extension.toml").read_text())
        assert manifest["id"] == item["id"]
        assert manifest["version"] == item["version"]
