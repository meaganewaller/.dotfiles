#!/usr/bin/env bash
set -euo pipefail

# Deterministic tradeoff capture - replaces the agent hook
# Captures large change context to decision journal without AI analysis
# The weekly review can synthesize patterns later

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

hook_register "tradeoff-auto-capture"

INPUT=$(cat)

MARKER_DIR="$HOME/.claude/pending-tradeoffs"
JOURNAL_DIR="$HOME/.claude/decision-journal"

# No pending tradeoffs? Done
if [[ ! -d "$MARKER_DIR" ]]; then
  echo '{"ok":true}'
  exit 0
fi

ensure_dir_exists "$JOURNAL_DIR"

LAST_MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# Get git branch and project
BRANCH="unknown"
PROJECT="unknown"
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
fi
PROJECT=$(detect_project)

DATE_PREFIX=$(date +"%Y-%m-%d-%H%M")

# Process each uncaptured marker
CAPTURED_COUNT=0
for marker in "$MARKER_DIR"/*.json; do
  [[ -f "$marker" ]] || continue

  CAPTURED=$(jq -r '.captured // false' "$marker" 2>/dev/null)
  if [[ "$CAPTURED" == "true" ]]; then
    continue
  fi

  FILE=$(jq -r '.file // "unknown"' "$marker" 2>/dev/null)
  LINES_CHANGED=$(jq -r '.lines_changed // 0' "$marker" 2>/dev/null)
  CHANGE_TYPE=$(jq -r '.change_type // "unknown"' "$marker" 2>/dev/null)

  # Look for tradeoff signals in last message (simple pattern matching)
  HAS_TRADEOFF_SIGNAL="false"
  TRADEOFF_KEYWORDS="tradeoff|trade-off|alternative|instead of|chose|decided|option|approach|vs|versus|rather than|pros|cons|benefit|drawback|considered"

  if echo "$LAST_MESSAGE" | grep -qiE "$TRADEOFF_KEYWORDS"; then
    HAS_TRADEOFF_SIGNAL="true"
  fi

  # Only create journal entry if there's a tradeoff signal
  if [[ "$HAS_TRADEOFF_SIGNAL" == "true" ]]; then
    JOURNAL_FILE="$JOURNAL_DIR/${DATE_PREFIX}-tradeoff.md"

    # Extract a snippet of context (first 2000 chars with tradeoff keywords)
    CONTEXT_SNIPPET=$(echo "$LAST_MESSAGE" | grep -iE ".{0,200}($TRADEOFF_KEYWORDS).{0,200}" | head -10 | head -c 2000 || echo "")

    # Write journal entry with YAML frontmatter
    cat > "$JOURNAL_FILE" << EOF
---
project: $PROJECT
branch: $BRANCH
source: auto-capture
files: $FILE
lines_changed: $LINES_CHANGED
change_type: $CHANGE_TYPE
---

# Tradeoff: $(date +"%Y-%m-%d")

## Context

Large change detected with tradeoff discussion signals.

## Raw Context (for review)

\`\`\`
$CONTEXT_SNIPPET
\`\`\`

## Notes

_Auto-captured. Review and edit as needed._

EOF

    # Emit event
    PAYLOAD=$(jq -n \
      --arg file "$FILE" \
      --arg branch "$BRANCH" \
      --arg project "$PROJECT" \
      --arg change_type "$CHANGE_TYPE" \
      --argjson lines_changed "$LINES_CHANGED" \
      '{
        file: $file,
        branch: $branch,
        project: $project,
        change_type: $change_type,
        lines_changed: $lines_changed,
        source: "auto-capture-deterministic",
        has_tradeoff_signal: true
      }')
    echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" tradeoff_auto_capture "$PAYLOAD" 2>/dev/null || true
  fi

  # Mark as captured (whether we wrote a journal or not)
  jq '.captured = true' "$marker" > "${marker}.tmp" && mv "${marker}.tmp" "$marker"
  CAPTURED_COUNT=$((CAPTURED_COUNT + 1))
done

# Clean up old markers (older than 24 hours)
find "$MARKER_DIR" -name "*.json" -mmin +1440 -delete 2>/dev/null || true

echo '{"ok":true}'
exit 0
