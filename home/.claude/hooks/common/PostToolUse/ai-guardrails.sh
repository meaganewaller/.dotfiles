#!/usr/bin/env bash
# PostToolUse (Write|Edit): Detect common AI-assisted development pitfalls
#
# Non-blocking hook that provides guidance via additionalContext:
# - Untested generated code (JS/TS/Ruby)
# - Generic placeholders (TODO, FIXME, example values)
# - Hallucinated dependencies (package.json, Gemfile)
# - Large unstructured files (>300 lines)
#
# Ruby support:
# - Work projects: rspec (spec/) + rubocop
# - Personal projects: minitest (test/) + standardrb
set -uo pipefail

INPUT=$(cat) || exit 0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../validate-path.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/validate-path.sh"
hook_register "ai-guardrails"
hook_set_context "$INPUT"

# Skip guardrails in exploration mode — reduce friction when prototyping
if is_mode "exploration"; then
  hook_success
  exit 0
fi

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[[ -z "$TOOL" ]] && exit 0

# Only process Write and Edit
case "$TOOL" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -z "$FILE_PATH" ]] && exit 0

# Get content for Write operations
CONTENT=""
if [[ "$TOOL" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null)
fi

FILENAME=$(basename "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
DIR=$(dirname "$FILE_PATH")
CWD=$(echo "$INPUT" | jq -r '.cwd // "."' 2>/dev/null)

# ============================================================================
# PROJECT DETECTION
# ============================================================================

# Detect Ruby test framework (rspec vs minitest)
detect_ruby_test_framework() {
    local project_root="${CWD:-.}"

    # Check for spec directory (rspec)
    if [[ -d "$project_root/spec" ]]; then
        echo "rspec"
        return
    fi

    # Check for test directory (minitest)
    if [[ -d "$project_root/test" ]]; then
        echo "minitest"
        return
    fi

    # Check Gemfile for explicit framework
    if [[ -f "$project_root/Gemfile" ]]; then
        if grep -q "rspec" "$project_root/Gemfile" 2>/dev/null; then
            echo "rspec"
            return
        fi
        if grep -q "minitest" "$project_root/Gemfile" 2>/dev/null; then
            echo "minitest"
            return
        fi
    fi

    echo "unknown"
}

# Detect Ruby linter (rubocop vs standardrb)
detect_ruby_linter() {
    local project_root="${CWD:-.}"

    # Check for .standard.yml (standardrb)
    if [[ -f "$project_root/.standard.yml" ]]; then
        echo "standardrb"
        return
    fi

    # Check for .rubocop.yml (rubocop)
    if [[ -f "$project_root/.rubocop.yml" ]]; then
        echo "rubocop"
        return
    fi

    # Check Gemfile
    if [[ -f "$project_root/Gemfile" ]]; then
        if grep -q "standard" "$project_root/Gemfile" 2>/dev/null; then
            echo "standardrb"
            return
        fi
        if grep -q "rubocop" "$project_root/Gemfile" 2>/dev/null; then
            echo "rubocop"
            return
        fi
    fi

    echo "unknown"
}

MESSAGES=()

# ============================================================================
# Detector 1: Untested Generated Code
# ============================================================================

if [[ "$TOOL" == "Write" ]]; then
    # JavaScript/TypeScript files
    if echo "$EXTENSION" | grep -qE '^(ts|tsx|js|jsx)$'; then
        # Skip test files, config files, type declarations
        if ! echo "$FILENAME" | grep -qE '\.(test|spec|stories|config|d)\.(ts|tsx|js|jsx)$' && \
           ! echo "$FILENAME" | grep -qE '^(index|env|next-env|jest|vitest|playwright|eslint|prettier)'; then
            BASENAME="${FILENAME%.*}"
            TEST_EXISTS=false
            for TEST_SUFFIX in ".test.ts" ".test.tsx" ".spec.ts" ".spec.tsx" ".test.js" ".test.jsx"; do
                if [[ -f "${DIR}/${BASENAME}${TEST_SUFFIX}" ]] || \
                   [[ -f "${DIR}/__tests__/${BASENAME}${TEST_SUFFIX}" ]]; then
                    TEST_EXISTS=true
                    break
                fi
            done
            if [[ "$TEST_EXISTS" == "false" ]]; then
                MESSAGES+=("New source file '${FILENAME}' has no corresponding test. Consider adding '${BASENAME}.test.${EXTENSION}'.")
            fi
        fi
    fi

    # Ruby files
    if [[ "$EXTENSION" == "rb" ]]; then
        # Skip test/spec files themselves
        if ! echo "$FILE_PATH" | grep -qE '(_test|_spec)\.rb$' && \
           ! echo "$FILE_PATH" | grep -qE '/(test|spec)/'; then

            BASENAME="${FILENAME%.rb}"
            TEST_EXISTS=false
            RUBY_FRAMEWORK=$(detect_ruby_test_framework)

            case "$RUBY_FRAMEWORK" in
                rspec)
                    # Check spec directory
                    # app/models/user.rb -> spec/models/user_spec.rb
                    RELATIVE_PATH="${FILE_PATH#"$CWD"/}"
                    RELATIVE_PATH="${RELATIVE_PATH#app/}"
                    SPEC_PATH="${CWD}/spec/${RELATIVE_PATH%.rb}_spec.rb"
                    if [[ -f "$SPEC_PATH" ]] || [[ -f "${DIR}/${BASENAME}_spec.rb" ]]; then
                        TEST_EXISTS=true
                    fi
                    if [[ "$TEST_EXISTS" == "false" ]]; then
                        MESSAGES+=("New Ruby file '${FILENAME}' has no spec. Consider adding '${BASENAME}_spec.rb' in spec/.")
                    fi
                    ;;
                minitest)
                    # Check test directory
                    # lib/parser.rb -> test/test_parser.rb or test/parser_test.rb
                    if [[ -f "${CWD}/test/test_${BASENAME}.rb" ]] || \
                       [[ -f "${CWD}/test/${BASENAME}_test.rb" ]] || \
                       [[ -f "${DIR}/${BASENAME}_test.rb" ]]; then
                        TEST_EXISTS=true
                    fi
                    if [[ "$TEST_EXISTS" == "false" ]]; then
                        MESSAGES+=("New Ruby file '${FILENAME}' has no test. Consider adding '${BASENAME}_test.rb' in test/.")
                    fi
                    ;;
            esac
        fi
    fi
fi

# ============================================================================
# Detector 2: Generic Placeholders
# ============================================================================

if [[ -n "$CONTENT" ]]; then
    PLACEHOLDER_COUNT=0
    PLACEHOLDER_TYPES=()

    if echo "$CONTENT" | grep -qiE '\bTODO\b'; then
        PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + 1))
        PLACEHOLDER_TYPES+=("TODO")
    fi
    if echo "$CONTENT" | grep -qiE '\bFIXME\b'; then
        PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + 1))
        PLACEHOLDER_TYPES+=("FIXME")
    fi
    if echo "$CONTENT" | grep -qiE '\blorem ipsum\b'; then
        PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + 1))
        PLACEHOLDER_TYPES+=("lorem ipsum")
    fi
    if echo "$CONTENT" | grep -qE 'example\.com|your-api-key|changeme|password123|REPLACE_ME|xxx|YOUR_'; then
        PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + 1))
        PLACEHOLDER_TYPES+=("placeholder values")
    fi
    # Ruby-specific placeholders
    if echo "$CONTENT" | grep -qE 'raise NotImplementedError|fail "not implemented"'; then
        PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + 1))
        PLACEHOLDER_TYPES+=("NotImplementedError")
    fi

    if [[ "$PLACEHOLDER_COUNT" -ge 2 ]]; then
        TYPES_STR=$(IFS=', '; echo "${PLACEHOLDER_TYPES[*]}")
        MESSAGES+=("File contains ${PLACEHOLDER_COUNT} placeholder types (${TYPES_STR}). Verify all values are complete before committing.")
    fi
fi

# ============================================================================
# Detector 3: Hallucinated Dependencies
# ============================================================================

if [[ "$TOOL" == "Write" ]]; then
    case "$FILENAME" in
        package.json)
            MESSAGES+=("package.json written. Verify dependencies exist: 'npm info <package>' for unfamiliar packages.")
            ;;
        Gemfile)
            RUBY_LINTER=$(detect_ruby_linter)
            LINT_CMD="bundle exec rubocop"
            [[ "$RUBY_LINTER" == "standardrb" ]] && LINT_CMD="bundle exec standardrb"
            MESSAGES+=("Gemfile written. Verify gems exist on rubygems.org. Run 'bundle install' then '${LINT_CMD}' to check.")
            ;;
        *.gemspec)
            MESSAGES+=("Gemspec written. Verify all dependencies are published on rubygems.org.")
            ;;
        Cargo.toml)
            MESSAGES+=("Cargo.toml written. Verify crates exist: 'cargo search <crate>' for unfamiliar dependencies.")
            ;;
        requirements.txt|pyproject.toml)
            MESSAGES+=("Python dependencies written. Verify packages exist on PyPI before installing.")
            ;;
    esac
fi

# ============================================================================
# Detector 4: Large Unstructured Files
# ============================================================================

if [[ "$TOOL" == "Write" ]] && [[ -n "$CONTENT" ]]; then
    LINE_COUNT=$(echo "$CONTENT" | wc -l | tr -d ' ')
    if [[ "$LINE_COUNT" -gt 300 ]]; then
        # Additional check: does it have any class/module/function definitions?
        STRUCTURE_COUNT=0
        if echo "$CONTENT" | grep -qE '^\s*(class|module|def|function|const|interface|type)\s+\w'; then
            STRUCTURE_COUNT=$(echo "$CONTENT" | grep -cE '^\s*(class|module|def|function|const|interface|type)\s+\w' || echo 0)
        fi

        if [[ "$STRUCTURE_COUNT" -lt 3 ]]; then
            MESSAGES+=("File is ${LINE_COUNT} lines with minimal structure. Consider breaking into smaller, focused modules.")
        elif [[ "$LINE_COUNT" -gt 500 ]]; then
            MESSAGES+=("File is ${LINE_COUNT} lines. Even with good structure, consider if this could be split into separate concerns.")
        fi
    fi
fi

# ============================================================================
# Detector 5: Ruby-specific patterns
# ============================================================================

if [[ "$EXTENSION" == "rb" ]] && [[ -n "$CONTENT" ]]; then
    # Detect potential method complexity
    if echo "$CONTENT" | grep -qE '^\s+def \w+.*\n(.*\n){30,}^\s+end'; then
        MESSAGES+=("Ruby file contains long methods (>30 lines). Consider extracting smaller, focused methods.")
    fi

    # Detect missing frozen_string_literal
    if ! echo "$CONTENT" | head -5 | grep -q 'frozen_string_literal'; then
        # Only warn for new files, not edits
        if [[ "$TOOL" == "Write" ]]; then
            RUBY_LINTER=$(detect_ruby_linter)
            if [[ "$RUBY_LINTER" != "unknown" ]]; then
                MESSAGES+=("Consider adding '# frozen_string_literal: true' magic comment for performance.")
            fi
        fi
    fi
fi

# ============================================================================
# Output
# ============================================================================

if [[ ${#MESSAGES[@]} -gt 0 ]]; then
    # Emit telemetry
    safe_emit "ai_guardrails_triggered" "$(jq -n \
        --arg file "$FILE_PATH" \
        --arg tool "$TOOL" \
        --argjson count "${#MESSAGES[@]}" \
        '{file: $file, tool: $tool, warning_count: $count}')" 2>/dev/null || true

    GUIDANCE=$(printf "**AI Guardrails:**\n")
    for msg in "${MESSAGES[@]}"; do
        GUIDANCE="${GUIDANCE}- ${msg}\n"
    done

    jq -nc --arg msg "$GUIDANCE" '{hookSpecificOutput: {additionalContext: $msg}}'
fi

hook_success
exit 0
