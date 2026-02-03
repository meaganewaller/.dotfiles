#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"
WALLPAPERS_DIR="${HOME}/.config/theme/wallpapers"

mode="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("mode",""))')"
wallpaper="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("wallpaper",""))')"

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
