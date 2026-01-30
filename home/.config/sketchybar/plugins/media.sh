#!/usr/bin/env bash
set -euo pipefail

get_spotify() {
  osascript <<'APPLESCRIPT'
tell application "System Events"
  if (name of processes) does not contain "Spotify" then return ""
end tell
tell application "Spotify"
  if player state is not playing then return ""
  return artist of current track & " — " & name of current track
end tell
APPLESCRIPT
}

get_music() {
  osascript <<'APPLESCRIPT'
tell application "System Events"
  if (name of processes) does not contain "Music" then return ""
end tell
tell application "Music"
  if player state is not playing then return ""
  return artist of current track & " — " & name of current track
end tell
APPLESCRIPT
}

OUT="$(get_spotify)"
[[ -z "$OUT" ]] && OUT="$(get_music)"

if [[ -z "$OUT" ]]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

[[ "${#OUT}" -gt 60 ]] && OUT="${OUT:0:60}…"
sketchybar --set "$NAME" drawing=on label="$OUT"
