#!/usr/bin/env bash
# SessionStart: clear once-per-session markers so cues and state triggers can fire again.
set -euo pipefail

rm -f /tmp/.claude-devos-cue-* 2>/dev/null || true
rm -f /tmp/.claude-devos-applied-cues-* 2>/dev/null || true
rm -f /tmp/.claude-devos-session-started-* 2>/dev/null || true
rm -f /tmp/.claude-tasks-active-* 2>/dev/null || true
exit 0
