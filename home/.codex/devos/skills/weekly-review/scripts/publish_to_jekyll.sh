#!/usr/bin/env bash
set -euo pipefail

# Publish synthesized weekly review to Jekyll and optionally start server
#
# Usage: publish_to_jekyll.sh <review_dir>
# Example: publish_to_jekyll.sh ~/.codex/devos/reviews/week-of-2026-02-23

REVIEW_DIR="${1:-}"
if [[ -z "$REVIEW_DIR" || ! -d "$REVIEW_DIR" ]]; then
  echo "Usage: publish_to_jekyll.sh <review_dir>" >&2
  exit 1
fi

JEKYLL_ROOT="${JEKYLL_ROOT:-$HOME/github/meaganewaller/.dotfiles/weekly-reviews}"
JEKYLL_PORT="${JEKYLL_PORT:-4000}"
SKIP_SERVER="${SKIP_SERVER:-0}"

# Validate Jekyll root
if [[ ! -d "$JEKYLL_ROOT" ]]; then
  echo "Error: Jekyll root not found: $JEKYLL_ROOT" >&2
  exit 1
fi

# Get week start from summary.json
SUMMARY_JSON="$REVIEW_DIR/summary.json"
if [[ ! -f "$SUMMARY_JSON" ]]; then
  echo "Error: Missing $SUMMARY_JSON" >&2
  exit 1
fi

WEEK_START=$(jq -r '.week.start' "$SUMMARY_JSON")
if [[ -z "$WEEK_START" || "$WEEK_START" == "null" ]]; then
  echo "Error: Could not determine week start from summary.json" >&2
  exit 1
fi

# Paths
REVIEWS_DIR="$JEKYLL_ROOT/_reviews"
DATA_DIR="$JEKYLL_ROOT/_data/dev_os"
REVIEW_MD="$REVIEW_DIR/review.md"
JEKYLL_REVIEW="$REVIEWS_DIR/${WEEK_START}-weekly-review.md"
JEKYLL_SUMMARY="$DATA_DIR/${WEEK_START}-summary.json"

mkdir -p "$REVIEWS_DIR" "$DATA_DIR"

# Copy summary.json (always update)
cp "$SUMMARY_JSON" "$JEKYLL_SUMMARY"
echo "✓ Published summary: $JEKYLL_SUMMARY" >&2

# Copy review.md content into Jekyll review (preserving frontmatter)
if [[ -f "$REVIEW_MD" ]]; then
  # Check if Jekyll review exists
  if [[ -f "$JEKYLL_REVIEW" ]]; then
    # Extract frontmatter from existing review (lines between first and second ---)
    # BSD-compatible: use awk instead of head -n -1
    FRONTMATTER=$(awk '/^---$/{p++} p==1' "$JEKYLL_REVIEW")
    if [[ -z "$FRONTMATTER" ]]; then
      # No frontmatter found, create it
      FRONTMATTER="---
layout: review
title: \"Weekly Engineering Review — ${WEEK_START}\"
date: ${WEEK_START}
summary_file: ${WEEK_START}-summary.json
---"
    else
      FRONTMATTER="${FRONTMATTER}
---"
    fi

    # Write frontmatter + review content (skip the H1 title from review.md)
    {
      echo "$FRONTMATTER"
      echo
      # Skip the first line (# Weekly Engineering Review) and blank line
      tail -n +3 "$REVIEW_MD"
    } > "$JEKYLL_REVIEW"
    echo "✓ Updated weekly review: $JEKYLL_REVIEW" >&2
  else
    # Create new review with frontmatter
    {
      echo "---"
      echo "layout: review"
      echo "title: \"Weekly Engineering Review — ${WEEK_START}\""
      echo "date: ${WEEK_START}"
      echo "summary_file: ${WEEK_START}-summary.json"
      echo "---"
      echo
      tail -n +3 "$REVIEW_MD"
    } > "$JEKYLL_REVIEW"
    echo "✓ Created weekly review: $JEKYLL_REVIEW" >&2
  fi
fi

# Copy charts if they exist
CHARTS_DIR="$REVIEW_DIR/charts"
JEKYLL_ASSETS="$JEKYLL_ROOT/assets/charts/$WEEK_START"
if [[ -d "$CHARTS_DIR" ]] && ls "$CHARTS_DIR"/*.png >/dev/null 2>&1; then
  mkdir -p "$JEKYLL_ASSETS"
  cp "$CHARTS_DIR"/*.png "$JEKYLL_ASSETS/"
  echo "✓ Published charts: $JEKYLL_ASSETS" >&2
fi

# Start Jekyll server if requested
if [[ "$SKIP_SERVER" == "1" ]]; then
  echo "• Skipping Jekyll server (SKIP_SERVER=1)" >&2
  exit 0
fi

# Check if Jekyll is already running
if lsof -i :"$JEKYLL_PORT" >/dev/null 2>&1; then
  echo "• Jekyll already running on port $JEKYLL_PORT" >&2
else
  echo "Starting Jekyll server..." >&2
  cd "$JEKYLL_ROOT"

  # Start Jekyll in background
  bundle exec jekyll serve --port "$JEKYLL_PORT" --detach >/dev/null 2>&1 || {
    echo "⚠ Failed to start Jekyll server (may need 'bundle install')" >&2
    exit 0
  }

  # Wait for server to be ready
  for _ in {1..20}; do
    if curl -s "http://localhost:$JEKYLL_PORT" >/dev/null 2>&1; then
      echo "✓ Jekyll server ready" >&2
      break
    fi
    sleep 0.5
  done
fi

REVIEW_URL="http://localhost:$JEKYLL_PORT/reviews/${WEEK_START//-/\/}/weekly-review/"

echo "✓ Opening $REVIEW_URL" >&2

# Cross-platform browser open
if command -v open >/dev/null 2>&1; then
  open "$REVIEW_URL"
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$REVIEW_URL"
else
  echo "Open in browser: $REVIEW_URL" >&2
fi
