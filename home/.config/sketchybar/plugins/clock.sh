#!/usr/bin/env bash
set -euo pipefail
sketchybar --set "$NAME" label="$(date '+%a · %H:%M')"
