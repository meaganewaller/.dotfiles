#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"

# Check if sketchybar is running
if ! pgrep -x sketchybar >/dev/null 2>&1; then
  echo "theme: sketchybar not running, skipping" >&2
  exit 0
fi

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
