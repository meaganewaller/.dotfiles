#!/usr/bin/env bash
# Theme change handler for sketchybar
# Can be triggered by:
#   1. theme apply (via sketchybar --trigger theme_changed) - uses env vars
#   2. Direct call from sketchybarrc on startup - reads current.json

set -euo pipefail

CURRENT_THEME="${HOME}/.config/theme/current.json"

# If MODE not set via env, try to read from current.json
if [[ -z "${MODE:-}" ]]; then
  if [[ -f "$CURRENT_THEME" ]] && command -v python3 >/dev/null 2>&1; then
    MODE=$(python3 -c 'import json; print(json.load(open("'"$CURRENT_THEME"'")).get("mode","dark"))' 2>/dev/null || echo "dark")
    ACCENT_HEX=$(python3 -c 'import json; print((json.load(open("'"$CURRENT_THEME"'")).get("accent") or {}).get("hex","#E5C07B"))' 2>/dev/null || echo "#E5C07B")
  else
    MODE="dark"
    ACCENT_HEX="#E5C07B"
  fi
else
  # Use env vars (from theme_changed event)
  ACCENT_HEX="${ACCENT_HEX:-#E5C07B}"
fi

# Convert hex (#RRGGBB) to sketchybar format (0xffRRGGBB)
hex_to_argb() {
  local hex="${1#\#}"
  echo "0xff${hex}"
}

ACCENT=$(hex_to_argb "$ACCENT_HEX")

# -----------------------------
# Color palettes by mode
# -----------------------------
if [[ "$MODE" == "light" ]]; then
  # Light mode colors
  BAR_BG=0xffF7F8FD
  ITEM_BG=0xffFFFFFF
  TEXT=0xff1B1E28
  SUBTEXT=0xff5B6071
  BORDER=0xffE6E8F2

  # Pastel colors (slightly darker for light bg)
  PASTEL_BLUE=0xff2196F3
  PASTEL_LAVENDER=0xff9575CD
  PASTEL_RED=0xffE91E63
  PASTEL_ORANGE=0xffFF9800
  PASTEL_GOLD=0xffFFC107
  PASTEL_GREEN=0xff4CAF50
else
  # Dark mode colors
  BAR_BG=0xff111318
  ITEM_BG=0xff1A1D24
  TEXT=0xffF6F7FB
  SUBTEXT=0xffC7CAD6
  BORDER=0xff2A2E39

  # Pastel colors (brighter for dark bg)
  PASTEL_BLUE=0xff31BFF3
  PASTEL_LAVENDER=0xffA484E9
  PASTEL_RED=0xffF4889A
  PASTEL_ORANGE=0xffFFAF68
  PASTEL_GOLD=0xffF6E683
  PASTEL_GREEN=0xff79D45E
fi

# Module colors
C_APP=$ACCENT
C_MEDIA=$PASTEL_LAVENDER
C_CLOCK=$PASTEL_GOLD
C_BATTERY=$PASTEL_GREEN
C_VOLUME=$PASTEL_GOLD
C_VPN=$PASTEL_BLUE

# -----------------------------
# Update bar appearance
# -----------------------------
sketchybar --bar color=$BAR_BG

# Update default text colors
sketchybar --default \
  icon.color=$TEXT \
  label.color=$TEXT

# Update individual items
sketchybar --set front_app icon.color=$C_APP label.color=$TEXT
sketchybar --set media label.color=$TEXT
sketchybar --set clock icon.color=$C_CLOCK label.color=$TEXT
sketchybar --set battery icon.color=$C_BATTERY label.color=$TEXT
sketchybar --set vpn icon.color=$C_VPN label.color=$TEXT
sketchybar --set vpn.popup background.color=$BAR_BG label.color=$TEXT
sketchybar --set volume icon.color=$C_VOLUME label.color=$TEXT
