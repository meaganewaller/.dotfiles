#!/usr/bin/env bash
set -euo pipefail

# Finalize weekly review: regenerate dashboard with synthesized content and publish to Jekyll
#
# Usage: finalize_review.sh <review_dir>
# Example: finalize_review.sh ~/.codex/devos/reviews/week-of-2026-02-23
#
# This script should be run AFTER AI has filled all placeholders in review.md

REVIEW_DIR="${1:-}"
if [[ -z "$REVIEW_DIR" || ! -d "$REVIEW_DIR" ]]; then
  echo "Usage: finalize_review.sh <review_dir>" >&2
  exit 1
fi

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMMARY_JSON="$REVIEW_DIR/summary.json"
REVIEW_MD="$REVIEW_DIR/review.md"

# Validate inputs
if [[ ! -f "$SUMMARY_JSON" ]]; then
  echo "Error: Missing $SUMMARY_JSON" >&2
  exit 1
fi

if [[ ! -f "$REVIEW_MD" ]]; then
  echo "Error: Missing $REVIEW_MD" >&2
  exit 1
fi

# Check that placeholders have been filled
if grep -q "PLACEHOLDER:" "$REVIEW_MD"; then
  echo "⚠ Warning: review.md still contains unfilled placeholders:" >&2
  grep "PLACEHOLDER:" "$REVIEW_MD" | head -5 >&2
  echo "Continuing anyway..." >&2
fi

# Step 1: Regenerate dashboard with synthesized content
echo "Regenerating dashboard..." >&2
python3 "$SKILL_DIR/render_dashboard.py" "$SUMMARY_JSON"

# Step 2: Publish to Jekyll and open browser
echo "Publishing to Jekyll..." >&2
bash "$SKILL_DIR/publish_to_jekyll.sh" "$REVIEW_DIR"

echo "✓ Review finalized and published" >&2
