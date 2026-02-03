#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"
SETTINGS="${HOME}/Library/Application Support/Code/User/settings.json"

# Validate current.json
if [[ ! -f "$CURRENT" ]]; then
  echo "theme: current.json not found" >&2
  exit 1
fi

theme="$(python3 -c 'import json; print((json.load(open("'"$CURRENT"'")).get("vscode") or {}).get("theme",""))' 2>/dev/null)" || {
  echo "theme: failed to parse current.json" >&2
  exit 1
}

# Skip if no theme configured
[ -n "$theme" ] || exit 0

# Skip if settings file doesn't exist (VS Code not installed or never opened)
if [[ ! -f "$SETTINGS" ]]; then
  echo "theme: VS Code settings not found, skipping" >&2
  exit 0
fi

python3 - <<'PY' "$SETTINGS" "$theme"
import re, sys
path, theme = sys.argv[1], sys.argv[2]
s = open(path, "r", encoding="utf-8").read()

# Replace existing key if present
pat = r'("workbench\.colorTheme"\s*:\s*)"(.*?)"'
if re.search(pat, s):
  s = re.sub(pat, r'\1"{}"'.format(theme.replace('"','\\"')), s, count=1)
else:
  # Insert near top (after first '{')
  s = re.sub(r'\{\s*', '{\n  "workbench.colorTheme": "'+theme.replace('"','\\"')+'",\n', s, count=1)

open(path, "w", encoding="utf-8").write(s)
PY

# Reload VS Code if running and command available
if command -v code >/dev/null 2>&1; then
  code --command workbench.action.reloadWindow >/dev/null 2>&1 || true
fi
