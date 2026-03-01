#!/usr/bin/env python3
import os
import subprocess
import sys


def main() -> int:
    dotfiles_root = os.environ.get(
        "DOTFILES_ROOT", os.path.expanduser("~/github/meaganewaller/.dotfiles")
    )
    target = os.path.join(dotfiles_root, "home/.claude/governance/bin/provenance-scan.py")
    return subprocess.call([sys.executable, target, *sys.argv[1:]])


if __name__ == "__main__":
    raise SystemExit(main())
