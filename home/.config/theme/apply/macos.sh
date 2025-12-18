#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"

mode="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("mode",""))')"
wallpaper="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("wallpaper",""))')"

if [ "$mode" = "dark" ]; then
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'
elif [ "$mode" = "light" ]; then
  osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'
fi

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
  osascript -e 'tell application "System Events" to tell every desktop to set picture to "'"$wallpaper"'"'
fi
