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

mkdir -p .claude
LOG_FILE=".claude/skill-friction-log.jsonl"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create a text blob for classification
TEXT="$(printf "%s\n%s\n%s\n" "$TOOL_NAME" "$CMD" "$ERROR" | tr '[:upper:]' '[:lower:]')"

DOMAIN="unknown"
HINTS=()
SIGNALS=()

add_hint() { HINTS+=("$1"); }
add_signal() { SIGNALS+=("$1"); }

# ---------------------------
# Domain classification rules
# ---------------------------

# Rust lifetimes / borrow checker
if echo "$TEXT" | grep -qiE "borrow checker|cannot borrow|does not live long enough|lifetime|E0[0-9]{3}|E050|E0597|E0499|E0515"; then
  DOMAIN="rust lifetimes"
  add_signal "rust:lifetime/borrow"
  add_hint "Review Rust ownership + borrowing patterns; practice refactoring to reduce shared mutable borrows."
fi

# Type systems (TS, Ruby Sorbet, general)
if echo "$TEXT" | grep -qiE "type error|typescript|tsc|cannot assign|is not assignable|generic|inferred|sorbet|sig\\(|type mismatch"; then
  DOMAIN="type systems"
  add_signal "types:type-error"
  add_hint "Trace the failing type boundary; consider adding explicit types at the boundary (IO, JSON, DB)."
fi

# Async / concurrency
if echo "$TEXT" | grep -qiE "deadlock|race condition|concurrent|async|await|event loop|promise rejection|unhandledpromise|tokio|spawn|thread|mutex|channel"; then
  DOMAIN="async concurrency"
  add_signal "concurrency:async"
  add_hint "Write a minimal reproduction; map which tasks run concurrently and where shared state is accessed."
fi

# Bundler / Ruby deps
if echo "$TEXT" | grep -qiE "bundler|bundle install|gemfile|could not find gem|dependency|rubygems|bundle exec|gem::"; then
  DOMAIN="bundler"
  add_signal "ruby:bundler"
  add_hint "Check Gemfile.lock consistency; verify Ruby version + bundler version + platform constraints."
fi

# Rails autoloading / Zeitwerk
if echo "$TEXT" | grep -qiE "zeitwerk|autoload|uninitialized constant|expected file .* to define constant|nameerror.*constant|circular dependency"; then
  DOMAIN="rails autoloading"
  add_signal "rails:autoload/zeitwerk"
  add_hint "Verify file path ↔ constant naming; run zeitwerk:check; look for circular requires."
fi

# Test failures (generic)
if echo "$TEXT" | grep -qiE "rspec|minitest|jest|vitest|pytest|test failed|failing tests|assertion failed"; then
  # Only override if still unknown; otherwise keep the more specific domain above
  if [[ "$DOMAIN" == "unknown" ]]; then
    DOMAIN="testing"
    add_signal "tests:failing"
    add_hint "Prefer fixing the *first* failure; look for shared state / order dependence / time assumptions."
  fi
fi

# Build/tooling issues (node, vite, webpack, esbuild)
if echo "$TEXT" | grep -qiE "webpack|vite|esbuild|rollup|babel|module not found|cannot resolve|syntaxerror.*import|node-gyp"; then
  if [[ "$DOMAIN" == "unknown" ]]; then
    DOMAIN="build tooling"
    add_signal "build:toolchain"
    add_hint "Check node version + lockfile; confirm module resolution and ESM/CJS boundary."
  fi
fi

# Security/permissions / filesystem
if echo "$TEXT" | grep -qiE "permission denied|EACCES|EPERM|operation not permitted|read-only file system"; then
  if [[ "$DOMAIN" == "unknown" ]]; then
    DOMAIN="env/permissions"
    add_signal "env:permissions"
    add_hint "Confirm file ownership, sandbox restrictions, and whether the process is running inside a container/remote env."
  fi
fi

# Create JSON arrays
HINTS_JSON=$(printf '%s\n' "${HINTS[@]:-}" | jq -R . | jq -s '.')
SIGNALS_JSON=$(printf '%s\n' "${SIGNALS[@]:-}" | jq -R . | jq -s '.')

# Keep excerpt short-ish
ERROR_EXCERPT=$(printf "%s\n%s" "$CMD" "$ERROR" | head -c 800 | tr '\n' ' ')

jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg tool_name "$TOOL_NAME" \
  --arg file_path "$FILE_PATH" \
  --arg domain "$DOMAIN" \
  --arg error_excerpt "$ERROR_EXCERPT" \
  --argjson hints "$HINTS_JSON" \
  --argjson signals "$SIGNALS_JSON" \
  '{
    timestamp: $timestamp,
    tool_name: $tool_name,
    file_paths: (if $file_path == "" then [] else [$file_path] end),
    domain: $domain,
    error_excerpt: $error_excerpt,
    hints: $hints,
    signals: $signals
  }' >> "$LOG_FILE"

PAYLOAD=$(jq -n \
  --arg domain "$DOMAIN" \
  --arg tool "$TOOL_NAME" \
  '{
    tool: $tool,
    domain: $domain
  }')

echo "$INPUT" | .claude/hooks/dev-os-emit.sh tool_failure "$PAYLOAD"

exit 0
