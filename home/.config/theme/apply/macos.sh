#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "theme: not on macOS, skipping" >&2
  exit 0
fi

CURRENT="${HOME}/.config/theme/current.json"
WALLPAPERS_DIR="${HOME}/.config/theme/wallpapers"

# Validate current.json exists and is valid JSON
if [[ ! -f "$CURRENT" ]]; then
  echo "theme: current.json not found" >&2
  exit 1
fi

mode="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("mode",""))' 2>/dev/null)" || {
  echo "theme: failed to parse current.json" >&2
  exit 1
}
wallpaper="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("wallpaper",""))' 2>/dev/null)" || true

if [ "$mode" = "dark" ]; then
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
elif [ "$mode" = "light" ]; then
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
fi

# Resolve wallpaper path
if [ -n "$wallpaper" ]; then
  # If not absolute, look in wallpapers dir
  if [[ "$wallpaper" != /* ]]; then
    wallpaper="${WALLPAPERS_DIR}/${wallpaper}"
  fi
  if [ -f "$wallpaper" ]; then
    osascript -e 'tell application "System Events" to tell every desktop to set picture to "'"$wallpaper"'"'
  else
    echo "theme: wallpaper not found: $wallpaper" >&2
  fi
fi
