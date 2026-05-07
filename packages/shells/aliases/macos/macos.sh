#!/usr/bin/env bash
# macOS-specific aliases and compatibility

# Timeout command compatibility - coreutils provides gtimeout on macOS
if command -v gtimeout &> /dev/null && ! command -v timeout &> /dev/null; then
   alias timeout='gtimeout'
fi

alias reset-screenshots='defaults write com.apple.screencapture location ~/Desktop/ && killall SystemUIServer'