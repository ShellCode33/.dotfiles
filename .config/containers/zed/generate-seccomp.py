#!/usr/bin/env python3
"""Refresh the reviewed nesting profile from the host's Podman default."""

import argparse
import json
from pathlib import Path


def nesting_profile(profile):
    if profile.get("defaultAction") != "SCMP_ACT_ERRNO":
        raise ValueError("Expected a default-deny Podman seccomp profile")
    # These checks still require capabilities in the target user/UTS namespace.
    # Default conditional rules use outer capabilities, which cannot see the
    # privileges acquired later inside the newly created user namespace.
    exceptions = {"sethostname", "setns"}
    rules = []
    for rule in profile["syscalls"]:
        names = [name for name in rule["names"] if name not in exceptions]
        if names:
            rules.append(dict(rule, names=names))
    rules.append({"names": sorted(exceptions), "action": "SCMP_ACT_ALLOW", "args": []})
    return dict(profile, syscalls=rules)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source", type=Path, default=Path("/usr/share/containers/seccomp.json")
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().with_name("seccomp-nesting.json"),
    )
    args = parser.parse_args()
    args.output.write_text(
        json.dumps(nesting_profile(json.loads(args.source.read_text())), indent=2)
        + "\n"
    )
    print(f"Updated {args.output}; review changes before launching Zed.")
