#!/usr/bin/env bash

# -----------------------------
# Theme-aware colors for sketchybar
# Reads current theme from ~/.config/theme/current.json
# Falls back to dark mode if not available
# -----------------------------

CURRENT_THEME="${HOME}/.config/theme/current.json"
MODE="dark"
ACCENT_HEX="#E5C07B"

# Try to read current theme
if [[ -f "$CURRENT_THEME" ]] && command -v python3 >/dev/null 2>&1; then
  MODE=$(python3 -c 'import json; print(json.load(open("'"$CURRENT_THEME"'")).get("mode","dark"))' 2>/dev/null || echo "dark")
  ACCENT_HEX=$(python3 -c 'import json; print((json.load(open("'"$CURRENT_THEME"'")).get("accent") or {}).get("hex","#E5C07B"))' 2>/dev/null || echo "#E5C07B")
fi

# Convert hex (#RRGGBB) to sketchybar format (0xffRRGGBB)
hex_to_argb() {
  local hex="${1#\#}"
  echo "0xff${hex}"
}

ACCENT=$(hex_to_argb "$ACCENT_HEX")

# -----------------------------
# Pastel palette
# -----------------------------
if [[ "$MODE" == "light" ]]; then
  # Slightly darker pastels for light backgrounds
  PASTEL_BLUE=0xff2196F3
  PASTEL_LAVENDER=0xff9575CD
  PASTEL_RED=0xffE91E63
  PASTEL_ORANGE=0xffFF9800
  PASTEL_GOLD=0xffFFC107
  PASTEL_GREEN=0xff4CAF50
else
  # Bright pastels for dark backgrounds
  PASTEL_BLUE=0xff31BFF3
  PASTEL_LAVENDER=0xffA484E9
  PASTEL_RED=0xffF4889A
  PASTEL_ORANGE=0xffFFAF68
  PASTEL_GOLD=0xffF6E683
  PASTEL_GREEN=0xff79D45E
fi

# -----------------------------
# Base UI colors
# -----------------------------
if [[ "$MODE" == "light" ]]; then
  BAR_BG=0xffF7F8FD
  ITEM_BG=0xffFFFFFF
  TEXT=0xff1B1E28
  SUBTEXT=0xff5B6071
  BORDER=0xffE6E8F2
else
  BAR_BG=0xff111318
  ITEM_BG=0xff1A1D24
  TEXT=0xffF6F7FB
  SUBTEXT=0xffC7CAD6
  BORDER=0xff2A2E39
fi

# -----------------------------
# Semantic colors
# -----------------------------
INFO=$PASTEL_LAVENDER
SUCCESS=$PASTEL_GREEN
WARN=$PASTEL_ORANGE
ALERT=$PASTEL_RED
HIGHLIGHT=$PASTEL_GOLD

# -----------------------------
# Per-module accent colors
# -----------------------------
C_APP=$ACCENT
C_MEDIA=$PASTEL_LAVENDER
C_CLOCK=$PASTEL_GOLD
C_BATTERY=$PASTEL_GREEN
C_CPU=$PASTEL_ORANGE
C_RAM=$PASTEL_LAVENDER
C_DISK=$PASTEL_BLUE
C_VOLUME=$PASTEL_GOLD
C_NETWORK=$PASTEL_BLUE
C_INTERNET=$PASTEL_GREEN
C_RSYNC=$PASTEL_LAVENDER
C_PING=$PASTEL_ORANGE
C_KEYBOARD=$PASTEL_RED
C_VPN=$PASTEL_BLUE
