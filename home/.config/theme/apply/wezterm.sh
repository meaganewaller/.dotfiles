#!/usr/bin/env bash
set -euo pipefail

# If wezterm isn't running, this will fail; ignore.
wezterm cli reload-config >/dev/null 2>&1 || true
