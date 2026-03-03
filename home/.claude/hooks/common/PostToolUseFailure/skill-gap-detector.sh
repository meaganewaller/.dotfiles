#!/usr/bin/env bash
set -euo pipefail

# Source shared validation utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
source "$SCRIPT_DIR/validate-path.sh"

# Register for health monitoring
hook_register "skill-gap-detector"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // ""')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
# Note: session_id could be used for future correlation but currently unused
# SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')

# Only log meaningful failures (skip empty)
if [[ -z "${ERROR}${CMD}" ]]; then
  exit 0
fi

# ============================================================================
# CONTEXT DETECTION - Understand WHERE the failure occurred
# ============================================================================

FILE_CONTEXT="unknown"
FILE_TYPE="unknown"

if [[ -n "$FILE_PATH" ]]; then
  # Detect file context based on path patterns
  case "$FILE_PATH" in
    */.claude/projects/*/subagents/*)
      FILE_CONTEXT="subagent-session"
      ;;
    */.claude/projects/*.jsonl)
      FILE_CONTEXT="session-log"
      ;;
    */.claude/dev-os-events.jsonl|*/.claude/skill-friction-log.jsonl|*/.claude/impact-log.jsonl)
      FILE_CONTEXT="telemetry-log"
      ;;
    */.claude/hooks/*)
      FILE_CONTEXT="hook-script"
      ;;
    */.claude/cues/*)
      FILE_CONTEXT="cue-file"
      ;;
    */.claude/pending-tradeoffs/*)
      FILE_CONTEXT="tradeoff-marker"
      ;;
    */.claude/*)
      FILE_CONTEXT="claude-internal"
      ;;
    *)
      FILE_CONTEXT="user-file"
      ;;
  esac

  # Detect file type
  case "$FILE_PATH" in
    *.jsonl) FILE_TYPE="jsonl-log" ;;
    *.json) FILE_TYPE="json" ;;
    *.md) FILE_TYPE="markdown" ;;
    *.sh) FILE_TYPE="shell-script" ;;
    *.rb) FILE_TYPE="ruby" ;;
    *.py) FILE_TYPE="python" ;;
    *.ts|*.tsx) FILE_TYPE="typescript" ;;
    *.js|*.jsx) FILE_TYPE="javascript" ;;
    *) FILE_TYPE="other" ;;
  esac

  # Get actual file stats if path exists
  FILE_EXISTS="false"
  FILE_IS_DIR="false"
  FILE_SIZE_KB=0

  if [[ -e "$FILE_PATH" ]]; then
    FILE_EXISTS="true"
    if [[ -d "$FILE_PATH" ]]; then
      FILE_IS_DIR="true"
    elif [[ -f "$FILE_PATH" ]]; then
      FILE_SIZE_KB=$(( $(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null || echo 0) / 1024 ))
    fi
  fi
fi

LOG_FILE="$CLAUDE_FRICTION_LOG"
ensure_file_exists "$LOG_FILE"

# Resource guard: check log size and rotate if needed
if ! guard_log_size "$LOG_FILE" 50; then
  # Rotate: keep last 1000 entries
  TEMP_LOG=$(mktemp)
  tail -n 1000 "$LOG_FILE" > "$TEMP_LOG" && mv "$TEMP_LOG" "$LOG_FILE"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create a text blob for classification (truncate to prevent memory issues)
TEXT="$(printf "%s\n%s\n%s\n" "$TOOL_NAME" "${CMD:0:2000}" "${ERROR:0:2000}" | tr '[:upper:]' '[:lower:]')"

# ============================================================================
# FRICTION TAXONOMY
# ============================================================================
# Primary domains (mutually exclusive):
#   syntax     - Parse errors, malformed input, invalid syntax
#   type       - Type mismatches, type system errors, inference failures
#   dependency - Missing packages, version conflicts, import failures
#   permission - Access denied, auth failures, sandbox restrictions
#   network    - Connection failures, timeouts, DNS, SSL errors
#   state      - File not found, stale references, resource limits, race conditions
#   config     - Misconfiguration, env vars, settings errors
#   testing    - Test failures, assertions, flaky tests
#   build      - Compilation, bundling, toolchain errors
# ============================================================================

DOMAIN="unknown"
SUBDOMAIN=""
HINTS=()
SIGNALS=()

add_hint() { HINTS+=("$1"); }
add_signal() { SIGNALS+=("$1"); }
set_domain() {
  if [[ "$DOMAIN" == "unknown" ]]; then
    DOMAIN="$1"
    SUBDOMAIN="${2:-}"
  fi
}

# ============================================================================
# TOP 5 ERROR SIGNATURES FROM THIS WEEK (highest priority)
# ============================================================================

# 1. File does not exist (most common - ~25 occurrences)
if echo "$TEXT" | grep -qiE "file does not exist|no such file or directory|ENOENT|cannot find|not found.*file|missing .*(file|json|config)"; then
  set_domain "state" "file-not-found"
  add_signal "state:file-not-found"

  # Context-specific hints for file-not-found
  case "$FILE_CONTEXT" in
    subagent-session)
      add_hint "Subagent session files are ephemeral. The subagent may have completed or been cleaned up. Check if agent is still running."
      ;;
    tradeoff-marker)
      add_hint "Tradeoff marker files are temporary. They may have been processed and removed already."
      ;;
    session-log)
      add_hint "Session log may not exist yet or has been archived. Check session ID validity."
      ;;
    *)
      add_hint "Verify the file path exists; check for typos, stale references, or race conditions in file creation."
      ;;
  esac
fi

# 2. Resource limits exceeded (~12 occurrences)
if echo "$TEXT" | grep -qiE "exceeds maximum allowed|too large|size limit|token limit|content.*exceeds|file.*too big"; then
  set_domain "state" "resource-limit"
  add_signal "state:resource-limit"

  # Context-specific hints for resource limits
  case "$FILE_CONTEXT" in
    telemetry-log)
      add_hint "Telemetry logs grow unbounded. Use 'tail -100 file | jq' or grep for specific event types instead of reading full file."
      ;;
    session-log)
      add_hint "Session logs can be large. Use grep to find specific content, or read with offset/limit for recent entries."
      ;;
    jsonl-log|*)
      if [[ "$FILE_TYPE" == "jsonl-log" ]]; then
        add_hint "JSONL files are append-only logs. Use 'tail -N' to get recent entries, or grep for specific patterns."
      else
        add_hint "Use offset/limit parameters for large files; consider chunked reading or grep for specific content."
      fi
      ;;
  esac
fi

# 3. Exit code failures with missing files (~5 occurrences)
if echo "$TEXT" | grep -qiE "exit code [1-9]" && echo "$TEXT" | grep -qiE "no such file|not found|missing"; then
  set_domain "state" "command-file-missing"
  add_signal "state:command-missing-file"
  add_hint "Check that all referenced files exist before running the command."
fi

# 4. Directory/file type mismatch
if echo "$TEXT" | grep -qiE "EISDIR|is a directory|illegal operation on a directory|expected file.*got directory"; then
  set_domain "state" "type-mismatch"
  add_signal "state:dir-file-mismatch"
  add_hint "Use ls or glob to list directory contents; Read tool requires a file path, not directory."
fi

# 5. Python module not found
if echo "$TEXT" | grep -qiE "modulenotfounderror|no module named|importerror.*no module|cannot import"; then
  set_domain "dependency" "python-module"
  add_signal "dependency:python-import"
  add_hint "Install missing package with pip; check virtualenv activation; verify PYTHONPATH."
fi

# ============================================================================
# SYNTAX ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "syntaxerror|parse error|unexpected token|invalid syntax|unterminated string|missing.*bracket|unmatched"; then
  set_domain "syntax" "parse"
  add_signal "syntax:parse-error"
  add_hint "Check for missing brackets, quotes, or semicolons; validate JSON/YAML with a linter."
fi

if echo "$TEXT" | grep -qiE "invalid json|json.*parse|unexpected.*json|malformed json"; then
  set_domain "syntax" "json"
  add_signal "syntax:json-parse"
  add_hint "Validate JSON structure; check for trailing commas, unquoted keys, or encoding issues."
fi

if echo "$TEXT" | grep -qiE "invalid yaml|yaml.*parse|yaml.*error|mapping values"; then
  set_domain "syntax" "yaml"
  add_signal "syntax:yaml-parse"
  add_hint "Check YAML indentation; avoid tabs; validate with yamllint."
fi

# ============================================================================
# TYPE ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "type error|typescript|tsc|cannot assign|is not assignable|generic|inferred|type mismatch"; then
  set_domain "type" "typescript"
  add_signal "type:typescript"
  add_hint "Trace the failing type boundary; add explicit types at IO/JSON/DB boundaries."
fi

if echo "$TEXT" | grep -qiE "sorbet|sig\\(|type.*expected.*got|incompatible types"; then
  set_domain "type" "ruby-sorbet"
  add_signal "type:sorbet"
  add_hint "Check Sorbet type annotations; use T.let for explicit typing."
fi

if echo "$TEXT" | grep -qiE "borrow checker|cannot borrow|does not live long enough|lifetime|E0[0-9]{3}"; then
  set_domain "type" "rust-ownership"
  add_signal "type:rust-borrow"
  add_hint "Review Rust ownership patterns; consider cloning or restructuring lifetimes."
fi

# ============================================================================
# DEPENDENCY ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "bundler|bundle install|gemfile|could not find gem|rubygems|gem::"; then
  set_domain "dependency" "ruby-bundler"
  add_signal "dependency:bundler"
  add_hint "Run bundle install; check Gemfile.lock consistency; verify Ruby version."
fi

if echo "$TEXT" | grep -qiE "npm err|yarn error|package.*not found|missing peer|node_modules"; then
  set_domain "dependency" "node-npm"
  add_signal "dependency:npm"
  add_hint "Run npm install; delete node_modules and reinstall; check package.json."
fi

if echo "$TEXT" | grep -qiE "cargo.*error|could not find.*crate|unresolved import.*crate"; then
  set_domain "dependency" "rust-cargo"
  add_signal "dependency:cargo"
  add_hint "Run cargo build; check Cargo.toml dependencies; verify crate names."
fi

# ============================================================================
# PERMISSION ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "permission denied|EACCES|EPERM|operation not permitted|read-only file system|access denied"; then
  set_domain "permission" "filesystem"
  add_signal "permission:fs-access"
  add_hint "Check file ownership and permissions; verify sandbox restrictions."
fi

if echo "$TEXT" | grep -qiE "401|403|unauthorized|forbidden|authentication.*failed|invalid.*token|expired.*token"; then
  set_domain "permission" "auth"
  add_signal "permission:auth"
  add_hint "Verify credentials; check token expiration; confirm API key is valid."
fi

# ============================================================================
# NETWORK ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "connection refused|ECONNREFUSED|network.*unreachable|host.*not found|dns.*failed"; then
  set_domain "network" "connection"
  add_signal "network:connection"
  add_hint "Check if the service is running; verify hostname and port; check firewall rules."
fi

if echo "$TEXT" | grep -qiE "timeout|timed out|ETIMEDOUT|deadline exceeded|request.*timeout"; then
  set_domain "network" "timeout"
  add_signal "network:timeout"
  add_hint "Increase timeout; check network latency; verify service responsiveness."
fi

if echo "$TEXT" | grep -qiE "ssl.*error|certificate.*error|CERT_|unable to verify|self.signed"; then
  set_domain "network" "ssl"
  add_signal "network:ssl"
  add_hint "Check SSL certificate validity; update CA certificates; verify hostname matches cert."
fi

# ============================================================================
# STATE ERRORS (additional patterns beyond top 5)
# ============================================================================

if echo "$TEXT" | grep -qiE "stale|outdated|already exists|conflict|locked|in use|busy"; then
  set_domain "state" "conflict"
  add_signal "state:conflict"
  add_hint "Check for stale locks; verify no concurrent modifications; refresh state."
fi

if echo "$TEXT" | grep -qiE "are identical|same file|circular|symlink loop"; then
  set_domain "state" "identity"
  add_signal "state:file-identity"
  add_hint "Check for symlinks pointing to source; avoid copying file to itself."
fi

# Generic command failure (exit code with no specific error message)
# This catches silent failures like `ls ... 2>/dev/null` or empty grep results
if echo "$TEXT" | grep -qiE "exit code [1-9]"; then
  set_domain "state" "command-failed"
  add_signal "state:command-exit-nonzero"
  add_hint "Command returned non-zero exit code; check if target exists or if output was suppressed."
fi

# ============================================================================
# CONFIG ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "env.*not set|missing.*env|undefined.*variable|config.*missing|invalid.*config"; then
  set_domain "config" "env-var"
  add_signal "config:env-var"
  add_hint "Check .env file; verify environment variable is exported; check shell profile."
fi

if echo "$TEXT" | grep -qiE "zeitwerk|autoload|uninitialized constant|nameerror.*constant"; then
  set_domain "config" "rails-autoload"
  add_signal "config:rails-autoload"
  add_hint "Verify file path matches constant naming; run zeitwerk:check."
fi

# ============================================================================
# TESTING ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "rspec|minitest|jest|vitest|pytest|test failed|assertion failed|expect.*to"; then
  set_domain "testing" "assertion"
  add_signal "testing:assertion"
  add_hint "Fix the first failure; check for shared state or time-dependent tests."
fi

# ============================================================================
# BUILD ERRORS
# ============================================================================

if echo "$TEXT" | grep -qiE "webpack|vite|esbuild|rollup|babel|node-gyp|compilation.*failed"; then
  set_domain "build" "bundler"
  add_signal "build:bundler"
  add_hint "Check node version; verify lockfile; confirm ESM/CJS compatibility."
fi

if echo "$TEXT" | grep -qiE "make.*error|cmake.*error|gcc.*error|clang.*error|linker.*error|undefined reference"; then
  set_domain "build" "native"
  add_signal "build:native-compile"
  add_hint "Check compiler version; verify system dependencies; review Makefile."
fi

# Create JSON arrays
HINTS_JSON=$(printf '%s\n' "${HINTS[@]:-}" | jq -R . | jq -s '.')
SIGNALS_JSON=$(printf '%s\n' "${SIGNALS[@]:-}" | jq -R . | jq -s '.')

# Keep excerpt short-ish
ERROR_EXCERPT=$(printf "%s\n%s" "$CMD" "$ERROR" | head -c 800 | tr '\n' ' ')

# Build context object for Read-specific diagnostics
CONTEXT_JSON="{}"
if [[ "$TOOL_NAME" == "Read" && -n "$FILE_PATH" ]]; then
  CONTEXT_JSON=$(jq -cn \
    --arg file_context "$FILE_CONTEXT" \
    --arg file_type "$FILE_TYPE" \
    --argjson file_exists "$FILE_EXISTS" \
    --argjson file_is_dir "$FILE_IS_DIR" \
    --argjson file_size_kb "$FILE_SIZE_KB" \
    '{
      file_context: $file_context,
      file_type: $file_type,
      file_exists: $file_exists,
      file_is_dir: $file_is_dir,
      file_size_kb: $file_size_kb
    }')
fi

jq -cn \
  --arg timestamp "$TIMESTAMP" \
  --arg tool_name "$TOOL_NAME" \
  --arg file_path "$FILE_PATH" \
  --arg domain "$DOMAIN" \
  --arg subdomain "$SUBDOMAIN" \
  --arg error_excerpt "$ERROR_EXCERPT" \
  --argjson hints "$HINTS_JSON" \
  --argjson signals "$SIGNALS_JSON" \
  --argjson context "$CONTEXT_JSON" \
  '{
    timestamp: $timestamp,
    tool_name: $tool_name,
    file_paths: (if $file_path == "" then [] else [$file_path] end),
    domain: $domain,
    subdomain: (if $subdomain == "" then null else $subdomain end),
    error_excerpt: $error_excerpt,
    hints: $hints,
    signals: $signals,
    context: (if $context == {} then null else $context end)
  }' >> "$LOG_FILE"

# Build structured friction_domain object
FRICTION_DOMAIN=$(jq -cn \
  --arg domain "$DOMAIN" \
  --arg subdomain "$SUBDOMAIN" \
  --argjson signals "$SIGNALS_JSON" \
  '{
    domain: $domain,
    subdomain: (if $subdomain == "" then null else $subdomain end),
    signals: $signals
  }')

# Check for repeated failures (same tool + subdomain in last 10 entries)
REPEAT_COUNT=0
if [[ -f "$LOG_FILE" ]]; then
  REPEAT_COUNT=$(tail -10 "$LOG_FILE" 2>/dev/null | jq -s --arg tool "$TOOL_NAME" --arg sub "$SUBDOMAIN" \
    '[.[] | select(.tool_name == $tool and .subdomain == $sub)] | length' 2>/dev/null || echo "0")
fi

PAYLOAD=$(jq -n \
  --arg tool "$TOOL_NAME" \
  --arg file_path "$FILE_PATH" \
  --arg file_context "${FILE_CONTEXT:-unknown}" \
  --arg file_type "${FILE_TYPE:-unknown}" \
  --arg error_excerpt "$ERROR_EXCERPT" \
  --argjson friction_domain "$FRICTION_DOMAIN" \
  --argjson hints "$HINTS_JSON" \
  --argjson repeat_count "$REPEAT_COUNT" \
  --argjson context "$CONTEXT_JSON" \
  '{
    tool: $tool,
    file_path: (if $file_path == "" then null else $file_path end),
    file_context: $file_context,
    file_type: $file_type,
    error_excerpt: (if $error_excerpt == "" then null else $error_excerpt end),
    domain: $friction_domain.domain,
    subdomain: $friction_domain.subdomain,
    hints: $hints,
    friction_domain: $friction_domain,
    repeat_count: $repeat_count,
    context: (if $context == {} then null else $context end)
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" tool_failure "$PAYLOAD"

exit 0
