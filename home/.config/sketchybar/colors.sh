#!/usr/bin/env bash

# -----------------------------
# Bright Pastel Theme (source)
# -----------------------------
PASTEL_BLUE=0xff31BFF3      # Highlighter Blue
PASTEL_LAVENDER=0xffA484E9  # Coral Lavender
PASTEL_RED=0xffF4889A       # Fresh Light Red
PASTEL_ORANGE=0xffFFAF68    # Tranquil Orange
PASTEL_GOLD=0xffF6E683      # Glossy Gold
PASTEL_GREEN=0xff79D45E     # Grassy Green

# -----------------------------
# Base UI (pick a vibe)
# -----------------------------

# --- Option A: Dark base
BAR_BG=0xff111318
ITEM_BG=0xff1A1D24
TEXT=0xffF6F7FB
SUBTEXT=0xffC7CAD6
BORDER=0xff2A2E39

# --- Option B: Light base
# BAR_BG=0xffF7F8FD
# ITEM_BG=0xffFFFFFF
# TEXT=0xff1B1E28
# SUBTEXT=0xff5B6071
# BORDER=0xffE6E8F2

# -----------------------------
# Semantic colors (map to your palette)
# -----------------------------
ACCENT=$PASTEL_BLUE
INFO=$PASTEL_LAVENDER
SUCCESS=$PASTEL_GREEN
WARN=$PASTEL_ORANGE
ALERT=$PASTEL_RED
HIGHLIGHT=$PASTEL_GOLD

# -----------------------------
# Suggested per-module accents
# -----------------------------
C_APP=$PASTEL_BLUE
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
