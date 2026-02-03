#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"

# Heuristic:
# - If default route goes through utunX -> VPN very likely ON
# - Or if any utun interface has an inet address -> VPN likely ON
vpn_on=0
details=""

default_if="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"

if [[ "${default_if:-}" == utun* ]]; then
  vpn_on=1
  details="default route: $default_if"
else
  # any utun with inet assigned?
  if ifconfig 2>/dev/null | awk '
    $1 ~ /^utun[0-9]+:/ {iface=$1; sub(":","",iface)}
    $1 == "inet" && iface != "" {print iface; exit}
  ' | grep -q '^utun'; then
    vpn_on=1
    details="utun interface active"
  fi
fi

# Handle hover events
# SketchyBar sets $SENDER to mouse.entered / mouse.exited
if [[ "${SENDER:-}" == "mouse.entered" ]]; then
  if [[ "$vpn_on" -eq 1 ]]; then
    sketchybar --set vpn.popup label="VPN Status: On"
  else
    sketchybar --set vpn.popup label="VPN Status: Off"
  fi

  # If you want the details, uncomment:
  [[ -n "$details" ]] && sketchybar --set vpn.popup label="VPN: $([[ $vpn_on -eq 1 ]] && echo On || echo Off) ($details)"

  sketchybar --set vpn popup.drawing=on
elif [[ "${SENDER:-}" == "mouse.exited" ]]; then
  sketchybar --set vpn popup.drawing=off
fi

# Always update the icon state (for normal timed updates too)
if [[ "$vpn_on" -eq 1 ]]; then
  sketchybar --set "$NAME" icon="$ICON_LOCK" icon.color=$SUCCESS
else
  sketchybar --set "$NAME" icon="$ICON_UNLOCK" icon.color=$SUBTEXT
fi
