#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="${HOME}/.config/theme"
CURRENT="${THEME_DIR}/current.json"
GHOSTTY_CONFIG="${HOME}/.config/ghostty/config"

[ -f "$CURRENT" ] || exit 0
[ -f "$GHOSTTY_CONFIG" ] || exit 0

theme_name=$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("ghostty",{}).get("theme",""))' 2>/dev/null || true)
[ -n "$theme_name" ] || exit 0

mode=$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("mode","dark"))' 2>/dev/null || true)

# Build the theme line: light:sakura,dark:jubi or just the theme name
if [ "$mode" = "light" ]; then
  new_line="theme = light:${theme_name},dark:${theme_name}"
else
  new_line="theme = light:${theme_name},dark:${theme_name}"
fi

# Replace the theme line in ghostty config
if grep -q '^theme = ' "$GHOSTTY_CONFIG"; then
  sed -i '' "s|^theme = .*|${new_line}|" "$GHOSTTY_CONFIG"
fi
