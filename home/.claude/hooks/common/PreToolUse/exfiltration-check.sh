#!/usr/bin/env bash
# PreToolUse (Bash): Detect potential data exfiltration patterns
#
# Blocks commands that could leak sensitive data:
# - Network transfer of sensitive files (.env, .pem, .key, etc.)
# - Piping secrets to network commands
# - Base64 encoding + network (obfuscation)
# - DNS exfiltration via command substitution
# - Script-write-then-execute patterns
#
# Hard deny rules always block. Soft rules prompt for confirmation.
set -uo pipefail

INPUT=$(cat) || exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"
hook_register "exfiltration-check"
hook_set_context "$INPUT"

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[[ "$TOOL" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$COMMAND" ]] && exit 0

# ============================================================================
# PATTERNS
# ============================================================================

# Normalize command: strip path prefixes so /usr/bin/curl matches as curl
NORM_CMD=$(echo "$COMMAND" | sed -E 's|/[^ ]*/([^ /]+)|\1|g')

# Sensitive file patterns
SENSITIVE_FILES='\.(env|pem|key|crt|p12|pfx|secret|credential|token|password|ssh|gpg|asc)'

# Network transfer tools
NET_TOOLS='(curl|wget|nc|ncat|socat|scp|rsync|sftp|ssh|http|httpie|aria2c|openssl\s+s_client|telnet|lwp-request|fetch)'

# ============================================================================
# RESPONSE HELPERS
# ============================================================================

# Hard block - no bypass possible
hard_block() {
    local reason="$1"
    safe_emit "exfiltration_blocked" "$(jq -n \
        --arg reason "$reason" \
        --arg command "${COMMAND:0:200}" \
        '{reason: $reason, command_preview: $command, severity: "hard"}')" 2>/dev/null || true

    hook_failure "blocked: $reason"

    jq -nc --arg reason "ExfiltrationCheck: $reason" \
        '{error: $reason, ok: false}'
    exit 0
}

# Soft block - prompts user for confirmation
soft_block() {
    local reason="$1"
    safe_emit "exfiltration_warning" "$(jq -n \
        --arg reason "$reason" \
        --arg command "${COMMAND:0:200}" \
        '{reason: $reason, command_preview: $command, severity: "soft"}')" 2>/dev/null || true

    jq -nc --arg reason "ExfiltrationCheck: $reason. Review carefully before allowing." \
        '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$reason}}'
    exit 0
}

# ============================================================================
# HARD DENY RULES (always block, no bypass)
# ============================================================================

# 1. Network transfer of sensitive files (including -F for curl form uploads)
if echo "$NORM_CMD" | grep -qE "curl.*(-d|--data|--upload-file|-F)|wget.*--post|nc\s|ncat\s|socat\s|http\s+(POST|PUT|PATCH)|aria2c\s|openssl\s+s_client"; then
    if echo "$NORM_CMD" | grep -qiE "$SENSITIVE_FILES"; then
        hard_block "Network transfer of sensitive file type detected"
    fi
fi

# 2. Piping secrets to network (including command substitution: curl -d "$(cat .env)")
if echo "$NORM_CMD" | grep -qE "(cat|less|head|tail|base64|xxd).*${SENSITIVE_FILES}.*\|.*${NET_TOOLS}"; then
    hard_block "Piping sensitive file to network command"
fi
if echo "$NORM_CMD" | grep -qE "${NET_TOOLS}.*\\$\(.*${SENSITIVE_FILES}"; then
    hard_block "Command substitution of sensitive file in network command"
fi

# 3. Direct file transfer tools with sensitive files
if echo "$NORM_CMD" | grep -qE "(scp|rsync|sftp)\s"; then
    if echo "$NORM_CMD" | grep -qiE "$SENSITIVE_FILES"; then
        hard_block "File transfer of sensitive file type"
    fi
fi

# 4. Posting env vars directly to network
if echo "$NORM_CMD" | grep -qE "curl.*(-d|--data).*\\\$[A-Z_]*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)"; then
    hard_block "Posting environment variable containing secrets to network"
fi

# ============================================================================
# SOFT RULES (prompt for confirmation)
# ============================================================================

# 5. Base64 encoding + network (obfuscation attempt)
if echo "$NORM_CMD" | grep -qE "base64.*\|.*${NET_TOOLS}"; then
    soft_block "Base64 encoding piped to network transfer - possible obfuscation"
fi
if echo "$NORM_CMD" | grep -qE "${NET_TOOLS}.*base64"; then
    soft_block "Network transfer with base64 - possible obfuscation"
fi

# 6. DNS exfiltration via command substitution (including backticks)
if echo "$NORM_CMD" | grep -qE "(dig|nslookup|host)\s.*(\\$\(|\`)"; then
    soft_block "Possible DNS exfiltration via command substitution"
fi

# 7. Scripting language network calls with sensitive file references
if echo "$NORM_CMD" | grep -qE "(python3?|ruby|node|perl)\s"; then
    if echo "$NORM_CMD" | grep -qiE "(requests\.(post|put|patch)|urllib|http\.request|Net::HTTP|fetch|open\()"; then
        if echo "$NORM_CMD" | grep -qiE "$SENSITIVE_FILES"; then
            soft_block "Scripting language network call with sensitive file reference"
        fi
    fi
fi

# 8. Script-write-then-execute pattern (write a script and immediately run it)
if echo "$NORM_CMD" | grep -qE "(echo|cat|printf|tee).*>.*\.(sh|py|rb|pl|js)\s*[;&|]"; then
    if echo "$NORM_CMD" | grep -qE "(bash|sh|python3?|ruby|perl|node)\s"; then
        soft_block "Script-write-then-execute pattern - review for exfiltration"
    fi
fi

# 9. Hex encoding + network (another obfuscation method)
if echo "$NORM_CMD" | grep -qE "(xxd|od -x|hexdump).*\|.*${NET_TOOLS}"; then
    soft_block "Hex encoding piped to network transfer - possible obfuscation"
fi

# 10. Tar/zip to network (bulk exfiltration)
if echo "$NORM_CMD" | grep -qE "(tar|zip|gzip).*\|.*(curl|wget|nc|socat)"; then
    soft_block "Archive piped directly to network - possible bulk exfiltration"
fi

# ============================================================================
# APPROVED
# ============================================================================

hook_success
exit 0
