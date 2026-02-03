#!/usr/bin/env bash
set -euo pipefail

# Check if wezterm CLI is available
if ! command -v wezterm >/dev/null 2>&1; then
  echo "theme: wezterm not installed, skipping" >&2
  exit 0
fi

# Check if wezterm is running (reload only works if it is)
if ! pgrep -x wezterm >/dev/null 2>&1 && ! pgrep -x wezterm-gui >/dev/null 2>&1; then
  echo "theme: wezterm not running, skipping" >&2
  exit 0
fi

wezterm cli reload-config >/dev/null 2>&1 || {
  echo "theme: wezterm reload failed (may not be connected)" >&2
  exit 0
}
