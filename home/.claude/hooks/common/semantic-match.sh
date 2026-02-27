#!/usr/bin/env bash
# semantic-match.sh - Semantic similarity matching using gzip NCD.
#
# Usage:
#   semantic-match.sh <query> <description> [vocabulary]
#
# Uses Normalized Compression Distance (NCD) to measure semantic similarity.
# Similar texts share patterns that compress well together.
#
# NCD = (C(ab) - min(C(a), C(b))) / max(C(a), C(b))
#
# Where C(x) is the compressed size of x.
# NCD ranges from 0 (identical) to ~1 (completely different).
# We consider texts similar if NCD < 0.58 (tunable threshold).
#
# Examples:
#   NCD("software design", "design the database schema") ≈ 0.52 (similar)
#   NCD("software design", "button design looks off")    ≈ 0.63 (different)
#
# Exit codes:
#   0 = match (NCD < threshold)
#   1 = no match

set -euo pipefail

QUERY="${1:-}"
DESCRIPTION="${2:-}"
VOCABULARY="${3:-}"

# Threshold for considering texts similar (lower = stricter)
NCD_THRESHOLD="${NCD_THRESHOLD:-0.65}"

[[ -z "$QUERY" || -z "$DESCRIPTION" ]] && exit 1

# First, check for vocabulary keyword overlap (fast path for short queries)
# If any vocabulary word appears in the query, consider it a match
if [[ -n "$VOCABULARY" ]]; then
  query_lower=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')
  for word in $VOCABULARY; do
    word_lower=$(echo "$word" | tr '[:upper:]' '[:lower:]')
    if [[ "$query_lower" == *"$word_lower"* ]]; then
      if [[ -n "${CUE_DEBUG:-}" ]]; then
        echo "VOCAB_MATCH: '$word_lower' found in query" >&2
      fi
      exit 0
    fi
  done
fi

# Normalize text: lowercase, collapse whitespace
normalize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ' | sed 's/^ //;s/ $//'
}

# Get compressed size of text
compressed_size() {
  echo -n "$1" | gzip -c 2>/dev/null | wc -c | tr -d ' '
}

# Combine description with vocabulary for richer matching
COMBINED="$DESCRIPTION"
if [[ -n "$VOCABULARY" ]]; then
  COMBINED="$DESCRIPTION $VOCABULARY"
fi

# Normalize inputs
NORM_QUERY=$(normalize "$QUERY")
NORM_DESC=$(normalize "$COMBINED")

# Calculate compressed sizes
SIZE_QUERY=$(compressed_size "$NORM_QUERY")
SIZE_DESC=$(compressed_size "$NORM_DESC")
SIZE_BOTH=$(compressed_size "$NORM_QUERY $NORM_DESC")

# Calculate NCD
# NCD = (C(ab) - min(C(a), C(b))) / max(C(a), C(b))
if [[ $SIZE_QUERY -lt $SIZE_DESC ]]; then
  MIN_SIZE=$SIZE_QUERY
  MAX_SIZE=$SIZE_DESC
else
  MIN_SIZE=$SIZE_DESC
  MAX_SIZE=$SIZE_QUERY
fi

# Avoid division by zero
[[ $MAX_SIZE -eq 0 ]] && exit 1

# Calculate NCD using awk for floating point
NCD=$(awk -v ab="$SIZE_BOTH" -v min="$MIN_SIZE" -v max="$MAX_SIZE" \
  'BEGIN { printf "%.4f", (ab - min) / max }')

# Compare against threshold
MATCH=$(awk -v ncd="$NCD" -v threshold="$NCD_THRESHOLD" \
  'BEGIN { print (ncd < threshold) ? 1 : 0 }')

if [[ "$MATCH" -eq 1 ]]; then
  # Debug output (only if CUE_DEBUG is set)
  if [[ -n "${CUE_DEBUG:-}" ]]; then
    echo "NCD=$NCD (threshold=$NCD_THRESHOLD) - MATCH" >&2
  fi
  exit 0
else
  if [[ -n "${CUE_DEBUG:-}" ]]; then
    echo "NCD=$NCD (threshold=$NCD_THRESHOLD) - NO MATCH" >&2
  fi
  exit 1
fi
