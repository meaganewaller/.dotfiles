#!/usr/bin/env bash
#
# Governance CLI - Policy traceability for AI-assisted development
#
# Usage:
#   governance.sh [OPTIONS]
#
# Modes:
#   (default)           Coverage report
#   --trace <cue>       End-to-end chain for one cue
#   --control <id>      Cues implementing a control
#   --policy <file>     Cues deriving from a policy
#   --gaps              Cues without provenance
#   --stale [days]      Old verified dates (default: 90)
#   --matrix            Flat CSV for auditors
#   --lint              Validate integrity
#   --json              Machine-readable output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# Defaults
MODE="coverage"
TARGET=""
STALE_DAYS=90
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --trace)
      MODE="trace"
      TARGET="$2"
      shift 2
      ;;
    --control)
      MODE="control"
      TARGET="$2"
      shift 2
      ;;
    --policy)
      MODE="policy"
      TARGET="$2"
      shift 2
      ;;
    --gaps)
      MODE="gaps"
      shift
      ;;
    --stale)
      MODE="stale"
      if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
        STALE_DAYS="$2"
        shift
      fi
      shift
      ;;
    --matrix)
      MODE="matrix"
      shift
      ;;
    --lint)
      MODE="lint"
      shift
      ;;
    --json)
      JSON_OUTPUT=true
      shift
      ;;
    --help|-h)
      MODE="help"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# Generate manifest
MANIFEST=$(mktemp)
trap 'rm -f "$MANIFEST"' EXIT
python3 "$SCRIPT_DIR/provenance-scan.py" --repo-root "$REPO_ROOT" -o "$MANIFEST" 2>/dev/null

# Helper functions
print_header() {
  if [[ "$JSON_OUTPUT" != "true" ]]; then
    echo -e "\n${BOLD}$1${NC}"
    echo "$(echo "$1" | sed 's/./-/g')"
  fi
}

# Mode handlers

mode_help() {
  cat <<EOF
Governance CLI - Policy traceability for AI-assisted development

Usage: governance.sh [OPTIONS]

Modes:
  (default)           Coverage report showing provenance statistics
  --trace <cue>       End-to-end chain for one cue (policy → control → justifications)
  --control <id>      Find all cues implementing a specific control
  --policy <file>     Find all cues deriving from a policy document
  --gaps              List cues without any provenance metadata
  --stale [days]      List cues with old verified dates (default: 90 days)
  --matrix            Output flat CSV for auditors
  --lint              Validate provenance integrity

Options:
  --json              Output results as JSON
  --help, -h          Show this help message

Examples:
  governance.sh                          # Coverage report
  governance.sh --trace commit           # Trace the commit cue
  governance.sh --control ENG-COMMIT-001 # Find cues for control
  governance.sh --gaps                   # Find undocumented cues
  governance.sh --lint                   # Validate all provenance
EOF
}

mode_coverage() {
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq '.statistics' "$MANIFEST"
    return
  fi

  print_header "Governance Coverage Report"

  stats=$(jq '.statistics' "$MANIFEST")
  total=$(echo "$stats" | jq -r '.total_cues')
  with_prov=$(echo "$stats" | jq -r '.cues_with_provenance')
  without_prov=$(echo "$stats" | jq -r '.cues_without_provenance')
  coverage=$(echo "$stats" | jq -r '.coverage_percent')
  policies=$(echo "$stats" | jq -r '.unique_policies')
  controls=$(echo "$stats" | jq -r '.unique_controls')
  stale=$(echo "$stats" | jq -r '.stale_cues')

  echo ""
  echo -e "Total cues scanned:    ${BOLD}$total${NC}"
  echo -e "With provenance:       ${GREEN}$with_prov${NC}"
  echo -e "Without provenance:    ${RED}$without_prov${NC}"
  echo -e "Coverage:              ${BOLD}$coverage%${NC}"
  echo ""
  echo -e "Unique policies:       $policies"
  echo -e "Unique controls:       $controls"
  echo -e "Stale cues (>90d):     $stale"

  if [[ "$without_prov" -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Run 'governance.sh --gaps' to see cues without provenance${NC}"
  fi

  if [[ "$stale" -gt 0 ]]; then
    echo -e "${YELLOW}Run 'governance.sh --stale' to see stale cues${NC}"
  fi
}

mode_trace() {
  local cue_name="$TARGET"

  cue=$(jq --arg name "$cue_name" '.cues[] | select(.cue_name == $name)' "$MANIFEST")

  if [[ -z "$cue" || "$cue" == "null" ]]; then
    echo "Error: Cue not found: $cue_name" >&2
    exit 1
  fi

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "$cue" | jq '.'
    return
  fi

  print_header "Provenance Trace: $cue_name"

  echo ""
  echo -e "${BOLD}Cue:${NC} $cue_name"
  echo -e "${BOLD}Path:${NC} $(echo "$cue" | jq -r '.path')"
  echo -e "${BOLD}Description:${NC} $(echo "$cue" | jq -r '.description // "N/A"')"

  prov=$(echo "$cue" | jq '.provenance')
  if [[ "$prov" == "null" || -z "$prov" ]]; then
    echo ""
    echo -e "${RED}No provenance metadata found.${NC}"
    return
  fi

  # Policies
  echo ""
  echo -e "${BOLD}Policies:${NC}"
  echo "$prov" | jq -r '.policies[]? | if type == "object" then "  → \(.uri)" else "  → \(.)" end' 2>/dev/null || echo "  (none)"

  # Controls
  echo ""
  echo -e "${BOLD}Controls:${NC}"
  echo "$prov" | jq -r '.controls[]? | "  → [\(.id)] \(.name // "")"' 2>/dev/null || echo "  (none)"

  # Justifications
  echo ""
  echo -e "${BOLD}Justifications:${NC}"
  echo "$prov" | jq -r '.controls[]?.justifications[]? | "  • \(.)"' 2>/dev/null || echo "  (none)"

  # Rationale
  rationale=$(echo "$prov" | jq -r '.rationale // ""')
  if [[ -n "$rationale" && "$rationale" != "null" ]]; then
    echo ""
    echo -e "${BOLD}Rationale:${NC}"
    echo "  $rationale" | fold -s -w 70
  fi

  # Verified
  verified=$(echo "$prov" | jq -r '.verified // ""')
  if [[ -n "$verified" && "$verified" != "null" ]]; then
    echo ""
    echo -e "${BOLD}Verified:${NC} $verified"
  fi
}

mode_control() {
  local control_id="$TARGET"

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq --arg id "$control_id" '.control_index[$id] // []' "$MANIFEST"
    return
  fi

  print_header "Cues Implementing Control: $control_id"

  cues=$(jq -r --arg id "$control_id" '.control_index[$id][]?.cue // empty' "$MANIFEST")

  if [[ -z "$cues" ]]; then
    echo ""
    echo "No cues found implementing control: $control_id"
    return
  fi

  echo ""
  while read -r cue_name; do
    echo -e "  ${GREEN}✓${NC} $cue_name"

    # Show justifications
    jq -r --arg id "$control_id" --arg cue "$cue_name" \
      '.control_index[$id][] | select(.cue == $cue) | .justifications[]? | "      • \(.)"' \
      "$MANIFEST"
  done <<< "$cues"
}

mode_policy() {
  local policy_file="$TARGET"

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq --arg uri "$policy_file" '.policy_index[$uri] // []' "$MANIFEST"
    return
  fi

  print_header "Cues Deriving From Policy: $policy_file"

  # Try exact match first, then partial match
  cues=$(jq -r --arg uri "$policy_file" '
    .policy_index | to_entries[] |
    select(.key | contains($uri)) |
    .value[]' "$MANIFEST" 2>/dev/null)

  if [[ -z "$cues" ]]; then
    echo ""
    echo "No cues found deriving from policy: $policy_file"
    return
  fi

  echo ""
  while read -r cue_name; do
    echo -e "  ${GREEN}✓${NC} $cue_name"
  done <<< "$cues"
}

mode_gaps() {
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq '[.cues[] | select(.provenance == null) | .cue_name]' "$MANIFEST"
    return
  fi

  print_header "Cues Without Provenance"

  gaps=$(jq -r '.cues[] | select(.provenance == null) | .cue_name' "$MANIFEST")

  if [[ -z "$gaps" ]]; then
    echo ""
    echo -e "${GREEN}All cues have provenance metadata!${NC}"
    return
  fi

  echo ""
  while read -r cue_name; do
    echo -e "  ${RED}✗${NC} $cue_name"
  done <<< "$gaps"

  count=$(echo "$gaps" | wc -l | tr -d ' ')
  echo ""
  echo -e "${YELLOW}$count cue(s) missing provenance${NC}"
}

mode_stale() {
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq --argjson days "$STALE_DAYS" '[.stale_cues[] | select(.days_old > $days)]' "$MANIFEST"
    return
  fi

  print_header "Stale Provenance (>$STALE_DAYS days)"

  stale=$(jq -r --argjson days "$STALE_DAYS" \
    '.stale_cues[] | select(.days_old > $days) | "\(.cue)\t\(.days_old)d\t(\(.verified))"' \
    "$MANIFEST")

  if [[ -z "$stale" ]]; then
    echo ""
    echo -e "${GREEN}No stale provenance found!${NC}"
    return
  fi

  echo ""
  while IFS=$'\t' read -r cue_name days verified; do
    echo -e "  ${YELLOW}⚠${NC} $cue_name - $days old $verified"
  done <<< "$stale"
}

mode_matrix() {
  if [[ "$JSON_OUTPUT" == "true" ]]; then
    jq '[.cues[] | select(.provenance != null) | {
      cue: .cue_name,
      policies: [.provenance.policies[]? | if type == "object" then .uri else . end],
      controls: [.provenance.controls[]?.id],
      verified: .provenance.verified
    }]' "$MANIFEST"
    return
  fi

  echo "cue,policy,control,verified"
  jq -r '.cues[] | select(.provenance != null) |
    .cue_name as $cue |
    .provenance.verified as $verified |
    (.provenance.policies[]? | if type == "object" then .uri else . end) as $policy |
    (.provenance.controls[]?.id) as $control |
    "\($cue),\($policy // ""),\($control // ""),\($verified // "")"' "$MANIFEST"
}

mode_lint() {
  exec bash "$SCRIPT_DIR/provenance-verify.sh" --manifest "$MANIFEST" --stale-days "$STALE_DAYS"
}

# Execute mode
case "$MODE" in
  help)
    mode_help
    ;;
  coverage)
    mode_coverage
    ;;
  trace)
    mode_trace
    ;;
  control)
    mode_control
    ;;
  policy)
    mode_policy
    ;;
  gaps)
    mode_gaps
    ;;
  stale)
    mode_stale
    ;;
  matrix)
    mode_matrix
    ;;
  lint)
    mode_lint
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac
