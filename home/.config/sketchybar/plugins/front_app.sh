#!/usr/bin/env bash
set -euo pipefail

APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
# trim
[[ "${#APP}" -gt 20 ]] && APP="${APP:0:20}…"
sketchybar --set "$NAME" label="$APP"
