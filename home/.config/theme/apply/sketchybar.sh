#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"

python3 - <<'PY' "$CURRENT"
import json, sys, subprocess
path = sys.argv[1]
d = json.load(open(path))
acc = d.get("accent") or {}
env = {
  "THEME": d.get("name",""),
  "MODE": d.get("mode",""),
  "ACCENT_NAME": acc.get("name",""),
  "ACCENT_HEX": acc.get("hex",""),
  "PROFILE": (d.get("sketchybar") or {}).get("profile",""),
}
args = ["sketchybar", "--trigger", "theme_changed"]
for k,v in env.items():
  args += [f"{k}={v}"]
subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PY
