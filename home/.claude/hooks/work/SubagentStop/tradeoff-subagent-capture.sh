#!/usr/bin/env bash
set -euo pipefail

# Deterministic tradeoff capture from subagent sessions
# Captures architectural reasoning without AI analysis

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

hook_register "tradeoff-subagent-capture"

INPUT=$(cat)

JOURNAL_DIR="$HOME/.claude/decision-journal"
ensure_dir_exists "$JOURNAL_DIR"

LAST_MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')
AGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // "unknown"')

# Only process Explore/Plan agents (they do architectural reasoning)
if [[ "$AGENT_TYPE" != "Explore" && "$AGENT_TYPE" != "Plan" ]]; then
  echo '{"ok":true}'
  exit 0
fi

# Get git branch and project
BRANCH="unknown"
PROJECT="unknown"
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
fi
PROJECT=$(detect_project)

DATE_PREFIX=$(date +"%Y-%m-%d-%H%M")

# Look for architectural reasoning signals
REASONING_KEYWORDS="tradeoff|trade-off|alternative|approach|design|architecture|pattern|principle|option|chose|decided|vs|versus|pros|cons|benefit|drawback|considered|layers|coupling|separation"

HAS_REASONING="false"
if echo "$LAST_MESSAGE" | grep -qiE "$REASONING_KEYWORDS"; then
  HAS_REASONING="true"
fi

if [[ "$HAS_REASONING" == "true" ]]; then
  JOURNAL_FILE="$JOURNAL_DIR/${DATE_PREFIX}-subagent-tradeoff.md"

  # Extract context snippet
  CONTEXT_SNIPPET=$(echo "$LAST_MESSAGE" | grep -iE ".{0,200}($REASONING_KEYWORDS).{0,200}" | head -10 | head -c 2000 || echo "")

  cat > "$JOURNAL_FILE" << EOF
---
project: $PROJECT
branch: $BRANCH
source: subagent-capture
agent_type: $AGENT_TYPE
---

# Tradeoff: $(date +"%Y-%m-%d")

## Context

Architectural reasoning detected in $AGENT_TYPE subagent.

## Raw Context (for review)

\`\`\`
$CONTEXT_SNIPPET
\`\`\`

## Notes

_Auto-captured from subagent. Review and edit as needed._

EOF

  # Emit event
  PAYLOAD=$(jq -n \
    --arg branch "$BRANCH" \
    --arg project "$PROJECT" \
    --arg agent_type "$AGENT_TYPE" \
    '{
      branch: $branch,
      project: $project,
      agent_type: $agent_type,
      source: "subagent-capture-deterministic",
      has_reasoning_signal: true
    }')
  echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" decision_tradeoff "$PAYLOAD" 2>/dev/null || true
fi

echo '{"ok":true}'
exit 0
