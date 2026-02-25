#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // ""')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only log meaningful failures (skip empty)
if [[ -z "${ERROR}${CMD}" ]]; then
  exit 0
fi

mkdir -p "$HOME/.claude"
LOG_FILE="$HOME/.claude/skill-friction-log.jsonl"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create a text blob for classification
TEXT="$(printf "%s\n%s\n%s\n" "$TOOL_NAME" "$CMD" "$ERROR" | tr '[:upper:]' '[:lower:]')"

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
if echo "$TEXT" | grep -qiE "file does not exist|no such file or directory|ENOENT|cannot find|not found.*file"; then
  set_domain "state" "file-not-found"
  add_signal "state:file-not-found"
  add_hint "Verify the file path exists; check for typos, stale references, or race conditions in file creation."
fi

# 2. Resource limits exceeded (~12 occurrences)
if echo "$TEXT" | grep -qiE "exceeds maximum allowed|too large|size limit|token limit|content.*exceeds|file.*too big"; then
  set_domain "state" "resource-limit"
  add_signal "state:resource-limit"
  add_hint "Use offset/limit parameters for large files; consider chunked reading or grep for specific content."
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

jq -cn \
  --arg timestamp "$TIMESTAMP" \
  --arg tool_name "$TOOL_NAME" \
  --arg file_path "$FILE_PATH" \
  --arg domain "$DOMAIN" \
  --arg subdomain "$SUBDOMAIN" \
  --arg error_excerpt "$ERROR_EXCERPT" \
  --argjson hints "$HINTS_JSON" \
  --argjson signals "$SIGNALS_JSON" \
  '{
    timestamp: $timestamp,
    tool_name: $tool_name,
    file_paths: (if $file_path == "" then [] else [$file_path] end),
    domain: $domain,
    subdomain: (if $subdomain == "" then null else $subdomain end),
    error_excerpt: $error_excerpt,
    hints: $hints,
    signals: $signals
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

PAYLOAD=$(jq -n \
  --arg tool "$TOOL_NAME" \
  --argjson friction_domain "$FRICTION_DOMAIN" \
  '{
    tool: $tool,
    domain: $friction_domain.domain,
    friction_domain: $friction_domain
  }')

echo "$INPUT" | "$HOME/.claude/hooks/dev-os-emit.sh" tool_failure "$PAYLOAD"

exit 0
