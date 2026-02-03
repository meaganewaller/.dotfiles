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
export ACCENT

# -----------------------------
# Pastel palette
# -----------------------------
if [[ "$MODE" == "light" ]]; then
  # Slightly darker pastels for light backgrounds
  export PASTEL_BLUE=0xff2196F3
  export PASTEL_LAVENDER=0xff9575CD
  export PASTEL_RED=0xffE91E63
  export PASTEL_ORANGE=0xffFF9800
  export PASTEL_GOLD=0xffFFC107
  export PASTEL_GREEN=0xff4CAF50
else
  # Bright pastels for dark backgrounds
  export PASTEL_BLUE=0xff31BFF3
  export PASTEL_LAVENDER=0xffA484E9
  export PASTEL_RED=0xffF4889A
  export PASTEL_ORANGE=0xffFFAF68
  export PASTEL_GOLD=0xffF6E683
  export PASTEL_GREEN=0xff79D45E
fi

# -----------------------------
# Base UI colors
# -----------------------------
if [[ "$MODE" == "light" ]]; then
  export BAR_BG=0xffF7F8FD
  export ITEM_BG=0xffFFFFFF
  export TEXT=0xff1B1E28
  export SUBTEXT=0xff5B6071
  export BORDER=0xffE6E8F2
else
  export BAR_BG=0xff111318
  export ITEM_BG=0xff1A1D24
  export TEXT=0xffF6F7FB
  export SUBTEXT=0xffC7CAD6
  export BORDER=0xff2A2E39
fi

# -----------------------------
# Semantic colors
# -----------------------------
export INFO=$PASTEL_LAVENDER
export SUCCESS=$PASTEL_GREEN
export WARN=$PASTEL_ORANGE
export ALERT=$PASTEL_RED
export HIGHLIGHT=$PASTEL_GOLD

# -----------------------------
# Per-module accent colors
# -----------------------------
export C_APP=$ACCENT
export C_MEDIA=$PASTEL_LAVENDER
export C_CLOCK=$PASTEL_GOLD
export C_BATTERY=$PASTEL_GREEN
export C_CPU=$PASTEL_ORANGE
export C_RAM=$PASTEL_LAVENDER
export C_DISK=$PASTEL_BLUE
export C_VOLUME=$PASTEL_GOLD
export C_NETWORK=$PASTEL_BLUE
export C_INTERNET=$PASTEL_GREEN
export C_RSYNC=$PASTEL_LAVENDER
export C_PING=$PASTEL_ORANGE
export C_KEYBOARD=$PASTEL_RED
export C_VPN=$PASTEL_BLUE
