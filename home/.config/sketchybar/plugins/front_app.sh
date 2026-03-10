#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

#if [ "$SENDER" = "front_app_switched" ]; then
#  sketchybar --set "$NAME" label="$INFO"
#fi

# TODO: Use Aerospace to get the front app
APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
# trim
[[ "${#APP}" -gt 20 ]] && APP="${APP:0:20}…"
sketchybar --set "$NAME" label="$APP"
