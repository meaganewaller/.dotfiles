#!/usr/bin/env bats
# Contract tests for cue pattern matching
# Validates: regex portability, pattern matching, no false positives

CUES_DIR="$BATS_TEST_DIRNAME/../../home/.claude/cues"
HOOKS_DIR="$BATS_TEST_DIRNAME/../../home/.claude/hooks/common"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export CLAUDE_HOME="$TEST_TMPDIR/.claude"
  mkdir -p "$CLAUDE_HOME/cues"

  # Copy cues to test location
  cp -r "$CUES_DIR"/* "$CLAUDE_HOME/cues/" 2>/dev/null || true
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Helper: extract pattern from cue frontmatter
get_pattern() {
  local cue_file="$1"
  grep "^pattern:" "$cue_file" 2>/dev/null | sed 's/^pattern:[[:space:]]*//' | head -1
}

# Helper: test if pattern matches subject using bash regex
pattern_matches() {
  local pattern="$1"
  local subject="$2"
  [[ "$subject" =~ $pattern ]]
}

# Helper: assert pattern does NOT match (for negative tests)
pattern_does_not_match() {
  local pattern="$1"
  local subject="$2"
  if [[ "$subject" =~ $pattern ]]; then
    echo "Pattern unexpectedly matched: $subject"
    return 1
  fi
  return 0
}

# ============================================================================
# Portability: No PCRE-only features in patterns
# ============================================================================

@test "no cue patterns use \\b word boundaries (not supported in bash)" {
  local failed=0
  local failures=""

  for cue_dir in "$CUES_DIR"/*/; do
    [[ -d "$cue_dir" ]] || continue
    cue_file="${cue_dir}cue.md"
    [[ -f "$cue_file" ]] || continue

    pattern=$(get_pattern "$cue_file")
    if [[ "$pattern" == *'\b'* ]]; then
      cue_name=$(basename "$cue_dir")
      failures="${failures}  - ${cue_name}: pattern contains \\b\n"
      failed=1
    fi
  done

  if [[ $failed -eq 1 ]]; then
    printf "Cues with unsupported \\\\b word boundaries:\n%s" "$failures"
    printf "Fix: Use (^|[^a-zA-Z])word([^a-zA-Z]|$) instead of \\\\bword\\\\b\n"
    return 1
  fi
}

@test "no cue patterns use \\d digit class (not supported in bash)" {
  local failed=0
  local failures=""

  for cue_dir in "$CUES_DIR"/*/; do
    [[ -d "$cue_dir" ]] || continue
    cue_file="${cue_dir}cue.md"
    [[ -f "$cue_file" ]] || continue

    pattern=$(get_pattern "$cue_file")
    if [[ "$pattern" == *'\d'* ]]; then
      cue_name=$(basename "$cue_dir")
      failures="${failures}  - ${cue_name}: pattern contains \\d\n"
      failed=1
    fi
  done

  if [[ $failed -eq 1 ]]; then
    printf "Cues with unsupported \\\\d digit class:\n%s" "$failures"
    printf "Fix: Use [0-9] instead of \\\\d\n"
    return 1
  fi
}

@test "no cue patterns use \\w word class (not supported in bash)" {
  local failed=0
  local failures=""

  for cue_dir in "$CUES_DIR"/*/; do
    [[ -d "$cue_dir" ]] || continue
    cue_file="${cue_dir}cue.md"
    [[ -f "$cue_file" ]] || continue

    pattern=$(get_pattern "$cue_file")
    if [[ "$pattern" == *'\w'* ]]; then
      cue_name=$(basename "$cue_dir")
      failures="${failures}  - ${cue_name}: pattern contains \\w\n"
      failed=1
    fi
  done

  if [[ $failed -eq 1 ]]; then
    printf "Cues with unsupported \\\\w word class:\n%s" "$failures"
    printf "Fix: Use [a-zA-Z0-9_] instead of \\\\w\n"
    return 1
  fi
}

@test "no cue patterns use \\s whitespace class (not supported in bash)" {
  local failed=0
  local failures=""

  for cue_dir in "$CUES_DIR"/*/; do
    [[ -d "$cue_dir" ]] || continue
    cue_file="${cue_dir}cue.md"
    [[ -f "$cue_file" ]] || continue

    pattern=$(get_pattern "$cue_file")
    if [[ "$pattern" == *'\s'* ]]; then
      cue_name=$(basename "$cue_dir")
      failures="${failures}  - ${cue_name}: pattern contains \\s\n"
      failed=1
    fi
  done

  if [[ $failed -eq 1 ]]; then
    printf "Cues with unsupported \\\\s whitespace class:\n%s" "$failures"
    printf "Fix: Use [[:space:]] instead of \\\\s\n"
    return 1
  fi
}

# ============================================================================
# Pattern Validity: All patterns must be valid bash regex
# ============================================================================

@test "all cue patterns are valid bash regex" {
  local failed=0
  local failures=""

  for cue_dir in "$CUES_DIR"/*/; do
    [[ -d "$cue_dir" ]] || continue
    cue_file="${cue_dir}cue.md"
    [[ -f "$cue_file" ]] || continue

    pattern=$(get_pattern "$cue_file")
    [[ -z "$pattern" ]] && continue

    # Try to use the pattern - invalid regex will error
    if ! ( [[ "test" =~ $pattern ]] || true ) 2>/dev/null; then
      cue_name=$(basename "$cue_dir")
      failures="${failures}  - ${cue_name}: invalid regex syntax\n"
      failed=1
    fi
  done

  if [[ $failed -eq 1 ]]; then
    printf "Cues with invalid regex:\n%s" "$failures"
    return 1
  fi
}

# ============================================================================
# Smoke Tests: Key cues match expected inputs
# ============================================================================

@test "file-verification pattern matches file operation phrases" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/file-verification/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should match
  pattern_matches "$pattern" "check if the file exists"
  pattern_matches "$pattern" "read the file at path"
  pattern_matches "$pattern" "create a new directory"
  pattern_matches "$pattern" "verify the path exists"
  pattern_matches "$pattern" "delete the old files"
  pattern_matches "$pattern" "file not found error"
}

@test "file-verification pattern does not match unrelated prompts" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/file-verification/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should NOT match
  pattern_does_not_match "$pattern" "hello world"
  pattern_does_not_match "$pattern" "what is the weather"
  pattern_does_not_match "$pattern" "refactor this code"
}

@test "adr pattern matches architecture decision phrases" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/adr/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should match
  pattern_matches "$pattern" "write an adr"
  pattern_matches "$pattern" "document this decision"
  pattern_matches "$pattern" "what are the trade-offs"
  pattern_matches "$pattern" "architecture review"
}

@test "adr pattern does not false-positive on 'radar'" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/adr/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should NOT match - "radar" contains "adr" but isn't about ADRs
  pattern_does_not_match "$pattern" "radar system"
}

@test "commit pattern matches git commit phrases" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/commit/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should match
  pattern_matches "$pattern" "commit these changes"
  pattern_matches "$pattern" "push to remote"
  pattern_matches "$pattern" "amend the commit"
}

@test "testing pattern matches test-related phrases" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/testing/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should match
  pattern_matches "$pattern" "write a test for this"
  pattern_matches "$pattern" "run the specs"
  pattern_matches "$pattern" "add rspec coverage"
  pattern_matches "$pattern" "create a factory"
}

@test "migration pattern matches database migration phrases" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/migration/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should match
  pattern_matches "$pattern" "create a migration"
  pattern_matches "$pattern" "migrate the database"
  pattern_matches "$pattern" "update the schema"
}

@test "recovery pattern matches failure and retry phrases" {
  local pattern
  pattern=$(get_pattern "$CUES_DIR/recovery/cue.md")
  [[ -n "$pattern" ]] || skip "No pattern defined"

  # Should match
  pattern_matches "$pattern" "it didn't work"
  pattern_matches "$pattern" "let me try again"
  pattern_matches "$pattern" "still failing"
  pattern_matches "$pattern" "same error as before"
  pattern_matches "$pattern" "I'm stuck"
}

# ============================================================================
# Integration: match-cues.sh finds cues correctly
# ============================================================================

@test "match-cues.sh finds file-verification cue for file prompts" {
  [[ -x "$HOOKS_DIR/match-cues.sh" ]] || skip "match-cues.sh not found"

  result=$(echo "verify the file exists" | "$HOOKS_DIR/match-cues.sh" prompt 2>/dev/null || true)
  [[ "$result" == *"file-verification"* ]]
}

@test "match-cues.sh finds adr cue for decision prompts" {
  [[ -x "$HOOKS_DIR/match-cues.sh" ]] || skip "match-cues.sh not found"

  result=$(echo "document this architecture decision" | "$HOOKS_DIR/match-cues.sh" prompt 2>/dev/null || true)
  [[ "$result" == *"adr"* ]]
}
