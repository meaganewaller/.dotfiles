#!/usr/bin/env bash
# PreToolUse: Scan for secrets before writing to files
# Blocks writes that contain API keys, tokens, passwords, etc.
set -euo pipefail

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"
hook_register "secret-scanner"
hook_set_context "$INPUT"
hook_bus_init "$INPUT" || true  # Bus is non-critical; don't abort security hook

TOOL=$(jq -r '.tool_name // ""' <<<"$INPUT")
FILE_PATH=$(jq -r '.tool_input.file_path // ""' <<<"$INPUT")
CONTENT=$(jq -r '.tool_input.content // ""' <<<"$INPUT")
NEW_STRING=$(jq -r '.tool_input.new_string // ""' <<<"$INPUT")

json_response() {
  jq -n --arg decision "$1" --arg reason "$2" '{decision:$decision,reason:$reason}'
}

# Only check Write and Edit operations
if [[ "$TOOL" != "Write" && "$TOOL" != "Edit" ]]; then
  json_response "approve" "Not a file modification tool"
  hook_success
  exit 0
fi

# Get the content to scan
SCAN_CONTENT=""
if [[ "$TOOL" == "Write" ]]; then
  SCAN_CONTENT="$CONTENT"
elif [[ "$TOOL" == "Edit" ]]; then
  SCAN_CONTENT="$NEW_STRING"
fi

# Skip if no content
if [[ -z "$SCAN_CONTENT" ]]; then
  json_response "approve" "No content to scan"
  hook_success
  exit 0
fi

# Allow .env.example files (they should have placeholders)
if [[ "$FILE_PATH" =~ \.env\.example$ || "$FILE_PATH" =~ \.env\.sample$ || "$FILE_PATH" =~ \.env\.template$ ]]; then
  json_response "approve" "Environment template file"
  hook_success
  exit 0
fi

# Secret patterns with descriptions
# Format: PATTERN::DESCRIPTION::ALLOW_IN_COMMENTS
declare -a SECRET_PATTERNS=(
  # AWS
  'AKIA[0-9A-Z]{16}::AWS Access Key ID::no'
  '[0-9a-zA-Z/+]{40}(?=.*AWS|.*aws|.*Secret|.*secret)::AWS Secret Key (contextual)::no'

  # API Keys (generic patterns)
  'api[_-]?key["\x27]?\s*[:=]\s*["\x27][a-zA-Z0-9_\-]{20,}["\x27]::Generic API Key assignment::no'
  'apikey["\x27]?\s*[:=]\s*["\x27][a-zA-Z0-9_\-]{20,}["\x27]::Generic API Key assignment::no'

  # Bearer tokens
  'Bearer\s+[a-zA-Z0-9_\-\.]+\.[a-zA-Z0-9_\-\.]+\.[a-zA-Z0-9_\-\.]+::JWT Bearer Token::no'

  # Private keys
  '-----BEGIN (RSA )?PRIVATE KEY-----::Private Key::no'
  '-----BEGIN EC PRIVATE KEY-----::EC Private Key::no'
  '-----BEGIN OPENSSH PRIVATE KEY-----::OpenSSH Private Key::no'

  # GitHub
  'ghp_[a-zA-Z0-9]{36}::GitHub Personal Access Token::no'
  'gho_[a-zA-Z0-9]{36}::GitHub OAuth Token::no'
  'ghs_[a-zA-Z0-9]{36}::GitHub Server Token::no'
  'ghr_[a-zA-Z0-9]{36}::GitHub Refresh Token::no'
  'github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}::GitHub Fine-grained PAT::no'

  # Slack
  'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*::Slack Token::no'
  'https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[a-zA-Z0-9]+::Slack Webhook URL::no'

  # Stripe
  'sk_live_[a-zA-Z0-9]{24,}::Stripe Live Secret Key::no'
  'sk_test_[a-zA-Z0-9]{24,}::Stripe Test Secret Key::yes'
  'rk_live_[a-zA-Z0-9]{24,}::Stripe Live Restricted Key::no'

  # Database connection strings with passwords
  '(mysql|postgres|postgresql|mongodb|redis)://[^:]+:[^@]+@::Database Connection String with Password::no'

  # Generic secrets
  'password["\x27]?\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]::Password Assignment::no'
  'secret["\x27]?\s*[:=]\s*["\x27][^"\x27]{8,}["\x27]::Secret Assignment::no'

  # Anthropic
  'sk-ant-[a-zA-Z0-9\-_]{20,}::Anthropic API Key::no'

  # OpenAI
  'sk-[a-zA-Z0-9]{48}::OpenAI API Key::no'

  # Google
  'AIza[0-9A-Za-z_-]{35}::Google API Key::no'
  '[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com::Google OAuth Client ID::yes'

  # Heroku
  '[hH]eroku.*[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}::Heroku API Key::no'

  # NPM
  'npm_[a-zA-Z0-9]{36}::NPM Access Token::no'

  # SendGrid
  'SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}::SendGrid API Key::no'

  # Twilio
  'SK[a-f0-9]{32}::Twilio API Key::no'
)

# Scan for secrets
FOUND_SECRETS=""
for entry in "${SECRET_PATTERNS[@]}"; do
  PATTERN="${entry%%::*}"
  REST="${entry#*::}"
  DESC="${REST%%::*}"
  # ALLOW_COMMENTS is reserved for future use (comment-aware scanning)

  # Use grep with extended regex (-- separates options from pattern)
  if echo "$SCAN_CONTENT" | grep -qE -- "$PATTERN" 2>/dev/null; then
    # Add to found secrets
    if [[ -n "$FOUND_SECRETS" ]]; then
      FOUND_SECRETS="$FOUND_SECRETS
- $DESC"
    else
      FOUND_SECRETS="- $DESC"
    fi
  fi
done

if [[ -n "$FOUND_SECRETS" ]]; then
  # Publish to hook bus for downstream hooks
  hook_bus_put "secret-scanner" "$(jq -n \
    --argjson found true \
    --arg file "$FILE_PATH" \
    --arg secrets "$FOUND_SECRETS" \
    '{found: $found, file: $file, secrets: $secrets}')" 2>/dev/null || true

  # Emit telemetry
  safe_emit "secret_detected" "$(jq -n \
    --arg file "$FILE_PATH" \
    --arg secrets "$FOUND_SECRETS" \
    '{file: $file, secrets_found: $secrets}')" 2>/dev/null || true

  json_response "block" "BLOCKED: Potential secrets detected in content.

Found:
$FOUND_SECRETS

File: $FILE_PATH

If these are intentionally fake/example values:
1. Use placeholder format: YOUR_API_KEY_HERE
2. Or use environment variables: \${API_KEY}
3. Or add to .env.example with placeholders"
  hook_success
  exit 0
fi

# Publish clean result to hook bus
hook_bus_put "secret-scanner" '{"found": false}' 2>/dev/null || true

json_response "approve" "No secrets detected"
hook_success
exit 0
