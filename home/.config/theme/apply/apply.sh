#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="${HOME}/.config/theme"
CURRENT="${THEME_DIR}/current.json"

[ -f "$CURRENT" ] || { echo "theme: current.json missing"; exit 1; }

bash "${THEME_DIR}/apply/macos.sh"
bash "${THEME_DIR}/apply/wezterm.sh"
bash "${THEME_DIR}/apply/sketchybar.sh"
bash "${THEME_DIR}/apply/vscode.sh"
bash "${THEME_DIR}/apply/cursor.sh"
