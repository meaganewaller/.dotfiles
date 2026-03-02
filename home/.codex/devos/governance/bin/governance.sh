#!/usr/bin/env bash
# codex-governance - Unified CLI for policy provenance governance.
#
# Usage: codex-governance [MODE] [OPTIONS]
#
# Modes:
#   (default)           Coverage report
#   --trace <cue>       End-to-end chain for one cue
#   --control <id>      Cues implementing a control
#   --policy <file>     Cues deriving from a policy
#   --gaps              Cues without provenance
#   --stale <days>      Old verified dates (default: 90)
#   --matrix            Flat CSV/table for auditors
#   --lint              Validate integrity
#   --json              Machine-readable output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/github/meaganewaller/.dotfiles}"
GOVERNANCE_ROOT="${GOVERNANCE_ROOT:-$DOTFILES_ROOT/home/.config/.codex/devos/governance}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}!${NC}"
INFO="${BLUE}→${NC}"

# Default options
MODE="coverage"
JSON_OUTPUT=0
STALE_DAYS=90
TARGET=""

usage() {
  cat <<EOF
${BOLD}codex-governance${NC} - Policy provenance governance CLI

${BOLD}USAGE${NC}
    codex-governance [MODE] [OPTIONS]

${BOLD}MODES${NC}
    (default)           Coverage report
    --trace <cue>       End-to-end chain for one cue
    --control <id>      Cues implementing a control
    --policy <file>     Cues deriving from a policy
    --gaps              Cues without provenance
    --stale [days]      Old verified dates (default: 90)
    --matrix            Flat CSV/table for auditors
    --lint              Validate provenance integrity

${BOLD}OPTIONS${NC}
    --json              Machine-readable JSON output
    --help              Show this help

${BOLD}EXAMPLES${NC}
    codex-governance                     # Coverage report
    codex-governance --trace commit      # Trace commit cue
    codex-governance --control ENG-COMMIT-001
    codex-governance --gaps              # Find missing provenance
    codex-governance --lint              # Validate all provenance
    codex-governance --matrix --json     # Export for auditors
EOF
}

# Generate manifest using scan script
generate_manifest() {
  local cue_roots=""

  # Build cue roots
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  if [[ -d "$codex_home/devos/cues" ]]; then
    cue_roots="$codex_home/devos/cues"
  fi

  # Also include dotfiles cues
  local dotfiles_cues="$DOTFILES_ROOT/home/.config/.codex/devos/cues"
  if [[ -d "$dotfiles_cues" ]]; then
    if [[ -n "$cue_roots" ]]; then
      cue_roots="$cue_roots:$dotfiles_cues"
    else
      cue_roots="$dotfiles_cues"
    fi
  fi

  python3 "$SCRIPT_DIR/provenance-scan.py" --cue-roots "$cue_roots" --dotfiles-root "$DOTFILES_ROOT"
}

# Mode: coverage report
mode_coverage() {
  local manifest
  manifest=$(generate_manifest)

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$manifest" | jq '{stats: .stats, cues: [.cues[] | {name, has_provenance}]}'
    return
  fi

  echo -e "\n${BOLD}Governance Coverage Report${NC}\n"

  local total with_prov without_prov coverage
  total=$(echo "$manifest" | jq '.stats.total_cues')
  with_prov=$(echo "$manifest" | jq '.stats.with_provenance')
  without_prov=$(echo "$manifest" | jq '.stats.without_provenance')
  coverage=$(echo "$manifest" | jq '.stats.coverage_percent')

  echo -e "  Total cues:      ${BOLD}$total${NC}"
  echo -e "  With provenance: ${GREEN}$with_prov${NC}"
  echo -e "  Without:         ${YELLOW}$without_prov${NC}"
  echo ""

  # Coverage bar
  local bar_width=30
  local coverage_int=${coverage%.*}  # Strip decimal for bash arithmetic
  local filled=$((coverage_int * bar_width / 100))
  local empty=$((bar_width - filled))
  local bar="${GREEN}"
  for ((i=0; i<filled; i++)); do bar+="█"; done
  bar+="${NC}"
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo -e "  Coverage: [$bar] ${BOLD}${coverage}%${NC}"

  echo ""

  # List cues with status
  echo -e "${BOLD}Cues:${NC}"
  echo "$manifest" | jq -r '.cues[] | "\(.has_provenance)\t\(.name)"' | while IFS=$'\t' read -r has_prov name; do
    if [[ "$has_prov" == "true" ]]; then
      echo -e "  ${CHECK} $name"
    else
      echo -e "  ${CROSS} $name"
    fi
  done
}

# Mode: trace a single cue
mode_trace() {
  local cue_name="$1"
  local manifest
  manifest=$(generate_manifest)

  local cue_data
  cue_data=$(echo "$manifest" | jq ".cues[] | select(.name == \"$cue_name\")")

  if [[ -z "$cue_data" || "$cue_data" == "null" ]]; then
    echo -e "${RED}Error: Cue '$cue_name' not found${NC}" >&2
    exit 1
  fi

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$cue_data"
    return
  fi

  echo -e "\n${BOLD}Tracing: $cue_name${NC}\n"

  local has_prov
  has_prov=$(echo "$cue_data" | jq -r '.has_provenance')

  if [[ "$has_prov" != "true" ]]; then
    echo -e "  ${WARN} No provenance metadata found"
    echo ""
    echo -e "  ${INFO} Add a provenance block to this cue's frontmatter."
    return
  fi

  # Show chain
  echo -e "${BOLD}Cue${NC}"
  echo -e "  └── $cue_name"

  echo ""
  echo -e "${BOLD}Policies${NC}"
  local policies
  policies=$(echo "$cue_data" | jq -r '.provenance.policy[]?.uri // empty')
  if [[ -n "$policies" ]]; then
    while IFS= read -r uri; do
      [[ -z "$uri" ]] && continue
      if [[ -f "$DOTFILES_ROOT/$uri" ]]; then
        echo -e "  └── ${GREEN}$uri${NC}"
      else
        echo -e "  └── ${RED}$uri (not found)${NC}"
      fi
    done <<< "$policies"
  else
    echo -e "  └── ${YELLOW}(none)${NC}"
  fi

  echo ""
  echo -e "${BOLD}Controls${NC}"
  echo "$cue_data" | jq -r '.provenance.controls[]? | "  └── \(.id): \(.name // "unnamed")"'

  echo ""
  echo -e "${BOLD}Verification${NC}"
  local verified rationale
  verified=$(echo "$cue_data" | jq -r '.provenance.verified // "(not set)"')
  rationale=$(echo "$cue_data" | jq -r '.provenance.rationale // "(not set)"')
  echo -e "  Verified: $verified"
  echo -e "  Rationale: ${rationale:0:80}..."
}

# Mode: find cues by control
mode_control() {
  local control_id="$1"
  local manifest
  manifest=$(generate_manifest)

  local cues
  cues=$(echo "$manifest" | jq -r ".indices.by_control[\"$control_id\"][]? // empty")

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$manifest" | jq "{control: \"$control_id\", cues: .indices.by_control[\"$control_id\"] // []}"
    return
  fi

  echo -e "\n${BOLD}Control: $control_id${NC}\n"

  if [[ -z "$cues" ]]; then
    echo -e "  ${WARN} No cues implement this control"
  else
    echo "Implemented by:"
    while IFS= read -r cue; do
      echo -e "  ${CHECK} $cue"
    done <<< "$cues"
  fi
}

# Mode: find cues by policy
mode_policy() {
  local policy_file="$1"
  local manifest
  manifest=$(generate_manifest)

  local cues
  cues=$(echo "$manifest" | jq -r ".indices.by_policy[\"$policy_file\"][]? // empty")

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$manifest" | jq "{policy: \"$policy_file\", cues: .indices.by_policy[\"$policy_file\"] // []}"
    return
  fi

  echo -e "\n${BOLD}Policy: $policy_file${NC}\n"

  if [[ -z "$cues" ]]; then
    echo -e "  ${WARN} No cues derive from this policy"
  else
    echo "Derived cues:"
    while IFS= read -r cue; do
      echo -e "  ${CHECK} $cue"
    done <<< "$cues"
  fi
}

# Mode: find cues without provenance
mode_gaps() {
  local manifest
  manifest=$(generate_manifest)

  local gaps
  gaps=$(echo "$manifest" | jq -r '.cues[] | select(.has_provenance == false) | .name')

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$manifest" | jq '{gaps: [.cues[] | select(.has_provenance == false) | .name]}'
    return
  fi

  echo -e "\n${BOLD}Cues Missing Provenance${NC}\n"

  if [[ -z "$gaps" ]]; then
    echo -e "  ${CHECK} All cues have provenance metadata"
  else
    while IFS= read -r cue; do
      echo -e "  ${CROSS} $cue"
    done <<< "$gaps"

    echo ""
    local count
    count=$(echo "$gaps" | wc -l | tr -d ' ')
    echo -e "${YELLOW}$count cue(s) need provenance metadata${NC}"
  fi
}

# Mode: find stale cues
mode_stale() {
  local days="${1:-$STALE_DAYS}"
  local manifest
  manifest=$(generate_manifest)

  # Calculate threshold date
  local threshold
  threshold=$(date -v-${days}d +%Y-%m-%d 2>/dev/null || date -d "-${days} days" +%Y-%m-%d 2>/dev/null || echo "1970-01-01")

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$manifest" | jq --arg threshold "$threshold" '{
      threshold: $threshold,
      stale: [.cues[] | select(.has_provenance == true and .provenance.verified < $threshold) | {name, verified: .provenance.verified}]
    }'
    return
  fi

  echo -e "\n${BOLD}Stale Provenance (older than $days days)${NC}\n"

  local found=0
  echo "$manifest" | jq -r ".cues[] | select(.has_provenance == true) | \"\(.name)\t\(.provenance.verified // \"none\")\"" | while IFS=$'\t' read -r name verified; do
    if [[ "$verified" < "$threshold" ]]; then
      echo -e "  ${WARN} $name (verified: $verified)"
      found=1
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo -e "  ${CHECK} No stale provenance found"
  fi
}

# Mode: matrix output for auditors
mode_matrix() {
  local manifest
  manifest=$(generate_manifest)

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    echo "$manifest" | jq '[.cues[] | select(.has_provenance == true) | {
      cue: .name,
      policies: [.provenance.policy[]?.uri // empty] | join(";"),
      controls: [.provenance.controls[]?.id // empty] | join(";"),
      verified: .provenance.verified
    }]'
    return
  fi

  echo -e "cue,policies,controls,verified"
  echo "$manifest" | jq -r '.cues[] | select(.has_provenance == true) | [
    .name,
    ([.provenance.policy[]?.uri // empty] | join(";")),
    ([.provenance.controls[]?.id // empty] | join(";")),
    (.provenance.verified // "")
  ] | @csv'
}

# Mode: lint/validate
mode_lint() {
  local manifest
  manifest=$(generate_manifest)

  if [[ $JSON_OUTPUT -eq 1 ]]; then
    # Run verifier and capture both output and exit code
    local result exit_code
    result=$(echo "$manifest" | DOTFILES_ROOT="$DOTFILES_ROOT" STALE_DAYS="$STALE_DAYS" bash "$SCRIPT_DIR/provenance-verify.sh" 2>&1) || exit_code=$?
    echo "{\"valid\": $([[ ${exit_code:-0} -eq 0 ]] && echo "true" || echo "false"), \"output\": $(echo "$result" | jq -Rs .)}"
    return ${exit_code:-0}
  fi

  echo "$manifest" | DOTFILES_ROOT="$DOTFILES_ROOT" STALE_DAYS="$STALE_DAYS" bash "$SCRIPT_DIR/provenance-verify.sh"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --json)
      JSON_OUTPUT=1
      shift
      ;;
    --trace)
      MODE="trace"
      TARGET="${2:-}"
      [[ -z "$TARGET" ]] && { echo "Error: --trace requires a cue name" >&2; exit 1; }
      shift 2
      ;;
    --control)
      MODE="control"
      TARGET="${2:-}"
      [[ -z "$TARGET" ]] && { echo "Error: --control requires a control ID" >&2; exit 1; }
      shift 2
      ;;
    --policy)
      MODE="policy"
      TARGET="${2:-}"
      [[ -z "$TARGET" ]] && { echo "Error: --policy requires a policy file" >&2; exit 1; }
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
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Execute mode
case "$MODE" in
  coverage) mode_coverage ;;
  trace)    mode_trace "$TARGET" ;;
  control)  mode_control "$TARGET" ;;
  policy)   mode_policy "$TARGET" ;;
  gaps)     mode_gaps ;;
  stale)    mode_stale "$STALE_DAYS" ;;
  matrix)   mode_matrix ;;
  lint)     mode_lint ;;
esac
