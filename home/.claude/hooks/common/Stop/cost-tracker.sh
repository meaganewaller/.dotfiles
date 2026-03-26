#!/usr/bin/env bash
# Stop: Track token costs per model per session
# Writes JSONL entries to ~/.claude/metrics/costs.jsonl
#
# Pricing (per 1M tokens, as of 2026-03):
#   Haiku 4.5:    $1.00 input, $5.00 output
#   Sonnet 4.x:   $3.00 input, $15.00 output
#   Opus 4.5/4.6: $5.00 input, $25.00 output
#   Opus 4/4.1:   $15.00 input, $75.00 output
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "cost-tracker"
hook_set_context "$INPUT"

# Extract usage data from Stop event
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.usage.input_tokens // .input_tokens // 0' 2>/dev/null)
OUTPUT_TOKENS=$(echo "$INPUT" | jq -r '.usage.output_tokens // .output_tokens // 0' 2>/dev/null)
CACHE_READ_TOKENS=$(echo "$INPUT" | jq -r '.usage.cache_read_input_tokens // 0' 2>/dev/null)
CACHE_CREATE_TOKENS=$(echo "$INPUT" | jq -r '.usage.cache_creation_input_tokens // 0' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
MODEL=$(echo "$INPUT" | jq -r '.model // "unknown"' 2>/dev/null)

# Fallback to environment variable if model unknown
[[ "$MODEL" == "unknown" || "$MODEL" == "null" ]] && MODEL="${CLAUDE_MODEL:-unknown}"

# Skip if no tokens used
if [[ "$INPUT_TOKENS" == "0" && "$OUTPUT_TOKENS" == "0" ]]; then
    hook_success
    exit 0
fi

# ============================================================================
# PRICING RATES (per 1M tokens) - Updated 2026-03
# See: https://docs.anthropic.com/en/docs/about-claude/pricing
# ============================================================================

case "$MODEL" in
    # Haiku 3.5 (must come before haiku*3)
    *haiku*3.5*|*haiku*3-5*)
        IN_RATE=0.80
        OUT_RATE=4.00
        CACHE_READ_RATE=0.08
        CACHE_CREATE_RATE=1.00
        ;;
    # Haiku 3 (legacy)
    *haiku*3*)
        IN_RATE=0.25
        OUT_RATE=1.25
        CACHE_READ_RATE=0.03
        CACHE_CREATE_RATE=0.30  # 5m cache write (1.25x)
        ;;
    # Haiku 4.5+ (current default for haiku)
    *haiku*)
        IN_RATE=1.00
        OUT_RATE=5.00
        CACHE_READ_RATE=0.10
        CACHE_CREATE_RATE=1.25
        ;;
    # Sonnet (all 4.x versions: 4, 4.5, 4.6)
    *sonnet*)
        IN_RATE=3.00
        OUT_RATE=15.00
        CACHE_READ_RATE=0.30
        CACHE_CREATE_RATE=3.75
        ;;
    # Opus 4.1 (must come before opus*4)
    *opus*4.1*|*opus*4-1*)
        IN_RATE=15.00
        OUT_RATE=75.00
        CACHE_READ_RATE=1.50
        CACHE_CREATE_RATE=18.75
        ;;
    # Opus 4.0 (higher tier, legacy)
    *opus*4.0*|*opus*4-0*)
        IN_RATE=15.00
        OUT_RATE=75.00
        CACHE_READ_RATE=1.50
        CACHE_CREATE_RATE=18.75
        ;;
    # Opus 4.5/4.6+ (current default for opus)
    *opus*)
        IN_RATE=5.00
        OUT_RATE=25.00
        CACHE_READ_RATE=0.50
        CACHE_CREATE_RATE=6.25
        ;;
    *)
        # Default to Sonnet pricing
        IN_RATE=3.00
        OUT_RATE=15.00
        CACHE_READ_RATE=0.30
        CACHE_CREATE_RATE=3.75
        ;;
esac

# ============================================================================
# COST CALCULATION
# ============================================================================

# Calculate cost including cache tokens
COST=$(awk -v it="$INPUT_TOKENS" -v ir="$IN_RATE" \
           -v ot="$OUTPUT_TOKENS" -v or_="$OUT_RATE" \
           -v cr="$CACHE_READ_TOKENS" -v crr="$CACHE_READ_RATE" \
           -v cc="$CACHE_CREATE_TOKENS" -v ccr="$CACHE_CREATE_RATE" \
    'BEGIN {
        printf "%.6f", (it * ir + ot * or_ + cr * crr + cc * ccr) / 1000000
    }')

# ============================================================================
# WRITE METRICS
# ============================================================================

METRICS_DIR="$CLAUDE_HOME/metrics"
COSTS_FILE="$METRICS_DIR/costs.jsonl"

ensure_dir_exists "$METRICS_DIR" || {
    hook_failure "Failed to create metrics directory"
    exit 0
}

ensure_file_exists "$COSTS_FILE" || {
    hook_failure "Failed to create costs file"
    exit 0
}

# Write cost entry
jq -nc \
    --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg sid "$SESSION_ID" \
    --arg model "$MODEL" \
    --argjson input_tokens "$INPUT_TOKENS" \
    --argjson output_tokens "$OUTPUT_TOKENS" \
    --argjson cache_read "$CACHE_READ_TOKENS" \
    --argjson cache_create "$CACHE_CREATE_TOKENS" \
    --arg cost "$COST" \
    '{
        timestamp: $ts,
        session_id: $sid,
        model: $model,
        input_tokens: $input_tokens,
        output_tokens: $output_tokens,
        cache_read_tokens: $cache_read,
        cache_creation_tokens: $cache_create,
        estimated_cost_usd: ($cost | tonumber)
    }' >> "$COSTS_FILE" 2>/dev/null || {
    hook_failure "Failed to write cost entry"
    exit 0
}

# Emit telemetry event for aggregation
safe_emit "cost_tracked" "$(jq -n \
    --arg model "$MODEL" \
    --argjson input "$INPUT_TOKENS" \
    --argjson output "$OUTPUT_TOKENS" \
    --arg cost "$COST" \
    '{model: $model, input_tokens: $input, output_tokens: $output, cost_usd: ($cost | tonumber)}')" 2>/dev/null || true

hook_success
exit 0
