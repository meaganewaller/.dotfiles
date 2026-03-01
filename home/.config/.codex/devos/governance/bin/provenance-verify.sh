#!/usr/bin/env bash
# provenance-verify.sh - Validate provenance manifest integrity.
#
# Usage:
#   provenance-verify.sh [manifest.json]
#   provenance-scan.py | provenance-verify.sh
#
# Validates:
#   - All policy.uri paths exist
#   - All controls have non-empty justifications
#   - verified dates are valid ISO format and not stale
#   - rationale is non-empty
#
# Exit codes:
#   0 = valid
#   1 = errors found

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}!${NC}"

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/github/meaganewaller/.dotfiles}"
STALE_DAYS="${STALE_DAYS:-90}"

errors=0
warnings=0

log_ok() {
  echo -e "  ${CHECK} $1"
}

log_error() {
  echo -e "  ${CROSS} $1"
  ((errors++)) || true
}

log_warn() {
  echo -e "  ${WARN} $1"
  ((warnings++)) || true
}

# Read manifest from file or stdin
if [[ $# -gt 0 && -f "$1" ]]; then
  manifest=$(cat "$1")
else
  manifest=$(cat)
fi

if [[ -z "$manifest" ]]; then
  echo -e "${RED}Error: No manifest provided${NC}"
  echo "Usage: provenance-verify.sh [manifest.json]"
  echo "   or: provenance-scan.py | provenance-verify.sh"
  exit 1
fi

# Check if jq is available
if ! command -v jq &>/dev/null; then
  echo -e "${RED}Error: jq is required but not installed${NC}"
  exit 1
fi

# Validate JSON
if ! echo "$manifest" | jq . >/dev/null 2>&1; then
  echo -e "${RED}Error: Invalid JSON in manifest${NC}"
  exit 1
fi

echo -e "\n\033[1mProvenance Verification\033[0m\n"

# Get cues with provenance
cues_with_prov=$(echo "$manifest" | jq -r '.cues[] | select(.has_provenance == true) | .name')

if [[ -z "$cues_with_prov" ]]; then
  echo "No cues with provenance found."
  exit 0
fi

# Calculate stale date threshold
stale_threshold=$(date -v-${STALE_DAYS}d +%Y-%m-%d 2>/dev/null || date -d "-${STALE_DAYS} days" +%Y-%m-%d 2>/dev/null || echo "1970-01-01")

for cue_name in $cues_with_prov; do
  echo -e "\033[1m$cue_name\033[0m"

  # Get provenance for this cue
  prov=$(echo "$manifest" | jq -r ".cues[] | select(.name == \"$cue_name\") | .provenance")

  # Check policy URIs exist
  policy_uris=$(echo "$prov" | jq -r '.policy[]?.uri // empty' 2>/dev/null || true)
  if [[ -n "$policy_uris" ]]; then
    while IFS= read -r uri; do
      [[ -z "$uri" ]] && continue
      # Check if path exists (relative to dotfiles root or absolute)
      if [[ -f "$DOTFILES_ROOT/$uri" ]]; then
        log_ok "policy: $uri"
      elif [[ -f "$uri" ]]; then
        log_ok "policy: $uri"
      else
        log_error "policy not found: $uri"
      fi
    done <<< "$policy_uris"
  else
    log_warn "no policy references"
  fi

  # Check controls have justifications
  controls=$(echo "$prov" | jq -c '.controls[]?' 2>/dev/null || true)
  if [[ -n "$controls" ]]; then
    while IFS= read -r control; do
      [[ -z "$control" ]] && continue
      ctrl_id=$(echo "$control" | jq -r '.id // empty')
      justifications=$(echo "$control" | jq -r '.justifications[]? // empty')

      if [[ -z "$ctrl_id" ]]; then
        log_error "control missing id"
      elif [[ -z "$justifications" ]]; then
        log_error "control $ctrl_id: missing justifications"
      else
        just_count=$(echo "$control" | jq '.justifications | length')
        log_ok "control $ctrl_id: $just_count justification(s)"
      fi
    done <<< "$controls"
  else
    log_warn "no control references"
  fi

  # Check verified date
  verified=$(echo "$prov" | jq -r '.verified // empty')
  if [[ -z "$verified" ]]; then
    log_error "missing verified date"
  elif ! [[ "$verified" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    log_error "invalid verified date format: $verified (expected YYYY-MM-DD)"
  elif [[ "$verified" < "$stale_threshold" ]]; then
    log_warn "stale verified date: $verified (older than $STALE_DAYS days)"
  else
    log_ok "verified: $verified"
  fi

  # Check rationale
  rationale=$(echo "$prov" | jq -r '.rationale // empty')
  if [[ -z "$rationale" ]]; then
    log_error "missing rationale"
  else
    word_count=$(echo "$rationale" | wc -w | tr -d ' ')
    log_ok "rationale: $word_count words"
  fi

  echo ""
done

# Summary
echo -e "\033[1mSummary\033[0m"
total_cues=$(echo "$manifest" | jq '.stats.total_cues')
with_prov=$(echo "$manifest" | jq '.stats.with_provenance')
coverage=$(echo "$manifest" | jq '.stats.coverage_percent')

echo -e "  Coverage: ${with_prov}/${total_cues} cues (${coverage}%)"

if [[ $errors -gt 0 ]]; then
  echo -e "  ${CROSS} ${errors} error(s)"
  exit 1
elif [[ $warnings -gt 0 ]]; then
  echo -e "  ${WARN} ${warnings} warning(s)"
  exit 0
else
  echo -e "  ${CHECK} All checks passed"
  exit 0
fi
