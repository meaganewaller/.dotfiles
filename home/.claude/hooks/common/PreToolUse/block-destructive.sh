#!/usr/bin/env bash
# PreToolUse (Bash): Block destructive commands that could cause data loss
#
# This hook blocks dangerous commands that are rarely intentional:
# - Git force operations (push --force, reset --hard, checkout .)
# - Pipe-to-shell attacks (curl|bash, wget|sh)
# - Home/root directory wipes
#
# NOTE: Some patterns (rm -rf, mkfs, dd, DROP TABLE) are also in git-guard.sh.
# This hook provides defense-in-depth with additional context and telemetry.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"
hook_register "block-destructive"
hook_set_context "$INPUT"
hook_bus_init "$INPUT" || true  # Bus is non-critical; don't abort security hook

# Only process Bash tool calls
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
[[ -z "$COMMAND" ]] && exit 0

# JSON response helper
json_block() {
    local reason="$1"
    local suggestion="${2:-}"
    if [[ -n "$suggestion" ]]; then
        jq -n --arg e "$reason" --arg s "$suggestion" '{
            error: $e,
            suggestion: $s,
            ok: false
        }'
    else
        jq -n --arg e "$reason" '{error: $e, ok: false}'
    fi
}

# ============================================================================
# DESTRUCTIVE COMMAND PATTERNS
# Format: pattern::description::suggestion
# ============================================================================

declare -a BLOCK_PATTERNS=(
    # Git force operations - can destroy shared history
    'push[[:space:]]+(--force|-f)\b::Git force push can destroy shared history::Use --force-with-lease for safer force push'
    'push[[:space:]]+.*--force::Git force push can destroy shared history::Use --force-with-lease for safer force push'
    'reset[[:space:]]+--hard[[:space:]]+origin::Hard reset to origin discards all local changes::Stash changes first: git stash'
    'checkout[[:space:]]+\.$::Checkout . discards all unstaged changes::Use git stash or commit first'
    'git[[:space:]]+restore[[:space:]]+\.$::Restore . discards all unstaged changes::Use git stash or commit first'
    'git[[:space:]]+clean[[:space:]]+-fd::Clean -fd removes untracked files permanently::Use git clean -n first to preview'

    # Pipe-to-shell attacks - remote code execution risk
    'curl[[:space:]]+.*\|[[:space:]]*(bash|sh|zsh)\b::Piping curl to shell is a security risk::Download first, review, then run'
    'wget[[:space:]]+.*\|[[:space:]]*(bash|sh|zsh)\b::Piping wget to shell is a security risk::Download first, review, then run'
    'curl[[:space:]]+.*\|[[:space:]]*sudo::Piping curl to sudo is extremely dangerous::Download first, review, then run with sudo'

    # Directory wipes - catastrophic data loss
    'rm[[:space:]]+-rf?[[:space:]]+/[[:space:]]*$::rm -rf / would destroy the entire filesystem::This command is never correct'
    'rm[[:space:]]+-rf?[[:space:]]+~[[:space:]]*$::rm -rf ~ would destroy your home directory::Use specific paths'
    'rm[[:space:]]+-rf?[[:space:]]+\*[[:space:]]*$::rm -rf * is extremely dangerous::Use specific paths'
    'rm[[:space:]]+-rf?[[:space:]]+/home[[:space:]]*$::rm -rf /home would destroy all user data::This is almost never intentional'
    'rm[[:space:]]+-rf?[[:space:]]+/Users[[:space:]]*$::rm -rf /Users would destroy all user data::This is almost never intentional'

    # Additional dangerous commands
    'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/::Recursive 777 on root is a security disaster::Use appropriate permissions'
    '>[[:space:]]*/dev/null[[:space:]]+2>&1[[:space:]]*<[[:space:]]*[^|]::Output redirect pattern may hide errors::Review command carefully'
)

# ============================================================================
# PATTERN MATCHING
# ============================================================================

for entry in "${BLOCK_PATTERNS[@]}"; do
    PATTERN=${entry%%::*}
    remainder=${entry#*::}
    DESC=${remainder%%::*}
    SUGGESTION=${remainder##*::}

    if echo "$COMMAND" | grep -Eqi "$PATTERN"; then
        # Publish to hook bus for downstream hooks
        hook_bus_put "block-destructive" "$(jq -n \
            --arg pattern "$PATTERN" \
            --arg desc "$DESC" \
            --argjson blocked true \
            '{blocked: $blocked, pattern: $pattern, description: $desc}')" 2>/dev/null || true

        # Emit telemetry event
        safe_emit "destructive_command_blocked" "$(jq -n \
            --arg pattern "$PATTERN" \
            --arg desc "$DESC" \
            --arg command "${COMMAND:0:200}" \
            '{
                pattern: $pattern,
                description: $desc,
                command_preview: $command
            }')" 2>/dev/null || true

        # Log to hook health with failure
        hook_failure "blocked: $DESC"

        # Return blocking response
        SHORT_CMD=${COMMAND:0:100}
        [[ ${#COMMAND} -gt 100 ]] && SHORT_CMD="${SHORT_CMD}..."

        json_block "BLOCKED: $DESC
Command: $SHORT_CMD" "$SUGGESTION"
        exit 0
    fi
done

# ============================================================================
# APPROVED
# ============================================================================

hook_success
exit 0
