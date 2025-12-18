#!/usr/bin/env bash
set -euo pipefail
CURRENT="${HOME}/.config/theme/current.json"

name="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("name",""))')"
mode="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("mode",""))')"
profile="$(python3 -c 'import json; print((json.load(open("'"$CURRENT"'")).get("sketchybar") or {}).get("profile",""))')"

sketchybar --trigger theme_changed THEME="$name" MODE="$mode" PROFILE="$profile" >/dev/null 2>&1 || true
