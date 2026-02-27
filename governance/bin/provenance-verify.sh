#!/usr/bin/env bash
#
# Verify provenance integrity in cues
#
# Validates:
# - All policy URIs exist as files
# - All controls have non-empty justifications
# - Verified dates are valid ISO format and not stale
# - Rationale is non-empty when provenance exists
#
# Exit codes:
#   0 = valid
#   1 = errors found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Counters
ERRORS=0
WARNINGS=0

error() {
  echo -e "${RED}ERROR${NC}: $*" >&2
  ((ERRORS++))
}

warn() {
  echo -e "${YELLOW}WARN${NC}: $*" >&2
  ((WARNINGS++))
}

info() {
  echo -e "${GREEN}OK${NC}: $*"
}

# Parse arguments
MANIFEST_FILE=""
STALE_DAYS=90

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest)
      MANIFEST_FILE="$2"
      shift 2
      ;;
    --stale-days)
      STALE_DAYS="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Generate manifest if not provided
if [[ -z "$MANIFEST_FILE" ]]; then
  MANIFEST_FILE=$(mktemp)
  trap 'rm -f "$MANIFEST_FILE"' EXIT
  python3 "$SCRIPT_DIR/provenance-scan.py" --repo-root "$REPO_ROOT" -o "$MANIFEST_FILE"
fi

# Verify manifest exists
if [[ ! -f "$MANIFEST_FILE" ]]; then
  echo "Error: Manifest file not found: $MANIFEST_FILE" >&2
  exit 1
fi

echo "Verifying provenance integrity..."
echo ""

# Extract and verify each cue
jq -c '.cues[]' "$MANIFEST_FILE" | while read -r cue; do
  cue_name=$(echo "$cue" | jq -r '.cue_name')
  has_provenance=$(echo "$cue" | jq -r '.provenance != null')

  if [[ "$has_provenance" != "true" ]]; then
    continue
  fi

  # Verify policy URIs exist
  echo "$cue" | jq -r '.provenance.policies[]? | if type == "object" then .uri else . end' 2>/dev/null | while read -r uri; do
    if [[ -n "$uri" && "$uri" != "null" ]]; then
      full_path="$REPO_ROOT/$uri"
      if [[ ! -f "$full_path" ]]; then
        error "[$cue_name] Policy URI does not exist: $uri"
      fi
    fi
  done

  # Verify controls have justifications
  echo "$cue" | jq -c '.provenance.controls[]?' 2>/dev/null | while read -r control; do
    if [[ -n "$control" && "$control" != "null" ]]; then
      control_id=$(echo "$control" | jq -r '.id // "unknown"')
      justifications=$(echo "$control" | jq -r '.justifications // []')
      justification_count=$(echo "$justifications" | jq 'length')

      if [[ "$justification_count" == "0" ]]; then
        error "[$cue_name] Control $control_id has no justifications"
      fi
    fi
  done

  # Verify verified date format and staleness
  verified=$(echo "$cue" | jq -r '.provenance.verified // ""')
  if [[ -n "$verified" && "$verified" != "null" ]]; then
    # Check format (YYYY-MM-DD)
    if ! [[ "$verified" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
      error "[$cue_name] Invalid verified date format: $verified (expected YYYY-MM-DD)"
    else
      # Check staleness
      verified_epoch=$(date -j -f "%Y-%m-%d" "$verified" "+%s" 2>/dev/null || date -d "$verified" "+%s" 2>/dev/null || echo "0")
      now_epoch=$(date "+%s")
      days_old=$(( (now_epoch - verified_epoch) / 86400 ))

      if [[ $days_old -gt $STALE_DAYS ]]; then
        warn "[$cue_name] Provenance is $days_old days old (verified: $verified)"
      fi
    fi
  fi

  # Verify rationale is non-empty
  rationale=$(echo "$cue" | jq -r '.provenance.rationale // ""')
  if [[ -z "$rationale" || "$rationale" == "null" ]]; then
    warn "[$cue_name] Missing rationale in provenance"
  fi
done

echo ""
echo "---"
echo "Verification complete."
echo "Errors: $ERRORS"
echo "Warnings: $WARNINGS"

if [[ $ERRORS -gt 0 ]]; then
  exit 1
fi

exit 0
