#!/usr/bin/env bash
set -euo pipefail

day="$(date '+%-d')"

# Ordinal suffix logic (English-correct)
case "$day" in
  11|12|13) suffix="th" ;;
  *1) suffix="st" ;;
  *2) suffix="nd" ;;
  *3) suffix="rd" ;;
  *) suffix="th" ;;
esac

label="$(date "+%a %b $day")$suffix · $(date '+%-I:%M %p')"

sketchybar --set "$NAME" label="$label"
