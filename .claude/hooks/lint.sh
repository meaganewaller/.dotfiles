#!/usr/bin/env bash
# Lint hook for dotfiles project
# Runs pre-commit checks on changed files
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

# Skip if no file path
[[ -z "$FILE_PATH" ]] && echo '{"ok":true}' && exit 0

# Get repo root
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Only lint files in this repo
[[ "$FILE_PATH" != "$REPO_ROOT"* ]] && echo '{"ok":true}' && exit 0

# Get relative path
REL_PATH="${FILE_PATH#"$REPO_ROOT"/}"

WARNINGS=()

# Shellcheck for shell scripts
if [[ "$REL_PATH" =~ \.(sh|bash)$ ]] || [[ "$REL_PATH" =~ ^bin/ ]]; then
    if command -v shellcheck &>/dev/null; then
        if ! shellcheck --severity=warning --shell=bash "$FILE_PATH" 2>/dev/null; then
            WARNINGS+=("ShellCheck found issues in $REL_PATH")
        fi
    fi
fi

# Check for trailing whitespace
if grep -qE '\s+$' "$FILE_PATH" 2>/dev/null; then
    WARNINGS+=("Trailing whitespace in $REL_PATH")
fi

# Check for missing newline at end of file
if [[ -s "$FILE_PATH" ]] && [[ "$(tail -c1 "$FILE_PATH" | wc -l)" -eq 0 ]]; then
    WARNINGS+=("No newline at end of $REL_PATH")
fi

# Check JSON syntax
if [[ "$REL_PATH" =~ \.json$ ]]; then
    if ! jq empty "$FILE_PATH" 2>/dev/null; then
        WARNINGS+=("Invalid JSON in $REL_PATH")
    fi
fi

# Check YAML syntax
if [[ "$REL_PATH" =~ \.(yaml|yml)$ ]]; then
    if command -v python3 &>/dev/null; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$FILE_PATH'))" 2>/dev/null; then
            WARNINGS+=("Invalid YAML in $REL_PATH")
        fi
    fi
fi

# Validate theme JSON
if [[ "$REL_PATH" =~ ^home/\.config/theme/themes/.*\.json$ ]]; then
    if [[ -x "$REPO_ROOT/bin/validate-themes" ]]; then
        if ! "$REPO_ROOT/bin/validate-themes" 2>/dev/null; then
            WARNINGS+=("Theme validation failed for $REL_PATH")
        fi
    fi
fi

# Output result
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    # Join warnings with newlines
    MSG=$(printf '%s\n' "${WARNINGS[@]}")
    jq -n --arg msg "$MSG" '{"ok":true, "message": ("Lint warnings:\n" + $msg)}'
else
    echo '{"ok":true}'
fi
