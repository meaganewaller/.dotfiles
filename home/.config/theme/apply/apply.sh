#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="${HOME}/.config/theme"
CURRENT="${THEME_DIR}/current.json"

[ -f "$CURRENT" ] || { echo "theme: current.json missing"; exit 1; }

run_script() {
  local name="$1"
  local script="${THEME_DIR}/apply/${name}.sh"

  if [[ ! -f "$script" ]]; then
    echo "  $name: skipped (script not found)"
    return 0
  fi

  if bash "$script" 2>&1; then
    echo "  $name: ok"
  else
    echo "  $name: failed" >&2
  fi
}

theme_name="$(python3 -c 'import json; print(json.load(open("'"$CURRENT"'")).get("name","unknown"))')"
echo "Applying theme: $theme_name"

run_script "macos"
run_script "wezterm"
run_script "sketchybar"
run_script "vscode"
run_script "cursor"

echo "Done."
