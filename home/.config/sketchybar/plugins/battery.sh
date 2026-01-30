#!/usr/bin/env bash
set -euo pipefail

PCT="$(pmset -g batt | grep -Eo '\d+%' | head -n1)"
NUM="${PCT%%%}"

color=0xffa6e3a1
if [[ "$NUM" -lt 20 ]]; then color=0xfff38ba8
elif [[ "$NUM" -lt 50 ]]; then color=0xfff9e2af
fi

sketchybar --set "$NAME" label="$PCT" label.color="$color"
