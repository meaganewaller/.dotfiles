#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"
SETTINGS="${HOME}/Library/Application Support/Cursor/User/settings.json"

theme="$(python3 -c 'import json; print((json.load(open("'"$CURRENT"'")).get("cursor") or {}).get("theme",""))')"
[ -n "$theme" ] || exit 0
[ -f "$SETTINGS" ] || exit 0

python3 - <<'PY' "$SETTINGS" "$theme"
import re, sys
path, theme = sys.argv[1], sys.argv[2]
s = open(path, "r", encoding="utf-8").read()
pat = r'("workbench\.colorTheme"\s*:\s*)"(.*?)"'
if re.search(pat, s):
  s = re.sub(pat, r'\1"{}"'.format(theme.replace('"','\\"')), s, count=1)
else:
  s = re.sub(r'\{\s*', '{\n  "workbench.colorTheme": "'+theme.replace('"','\\"')+'",\n', s, count=1)
open(path, "w", encoding="utf-8").write(s)
PY

cursor --command workbench.action.reloadWindow >/dev/null 2>&1 || true
