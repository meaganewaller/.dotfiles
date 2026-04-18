#!/usr/bin/env bats
# Tests for profile validation in install and link-dotfiles scripts

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export DOTFILES_ROOT="$BATS_TEST_DIRNAME/.."
  source "$DOTFILES_ROOT/lib/common.sh"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================================
# validate_profile
# ============================================================================

@test "validate_profile accepts 'work'" {
  run validate_profile "work"
  [[ "$status" -eq 0 ]]
}

@test "validate_profile accepts 'personal'" {
  run validate_profile "personal"
  [[ "$status" -eq 0 ]]
}

@test "validate_profile accepts 'server'" {
  run validate_profile "server"
  [[ "$status" -eq 0 ]]
}

@test "validate_profile accepts 'container'" {
  run validate_profile "container"
  [[ "$status" -eq 0 ]]
}

@test "validate_profile rejects unknown profile" {
  run validate_profile "typo"
  [[ "$status" -ne 0 ]]
  [[ "$output" =~ "Unknown profile" ]]
  [[ "$output" =~ "typo" ]]
}

@test "validate_profile rejects empty profile" {
  run validate_profile ""
  [[ "$status" -ne 0 ]]
  [[ "$output" =~ "No profile specified" ]]
}

@test "validate_profile lists valid profiles in error message" {
  run validate_profile "bogus"
  [[ "$output" =~ "work" ]]
  [[ "$output" =~ "personal" ]]
  [[ "$output" =~ "server" ]]
  [[ "$output" =~ "container" ]]
}

# ============================================================================
# link-dotfiles integration
# ============================================================================

@test "link-dotfiles rejects invalid profile with --dry-run" {
  run "$DOTFILES_ROOT/bin/link-dotfiles" --profile invalid --dry-run
  [[ "$status" -ne 0 ]]
  [[ "$output" =~ "Unknown profile" ]]
}

@test "link-dotfiles accepts valid profile with --dry-run" {
  run "$DOTFILES_ROOT/bin/link-dotfiles" --profile work --dry-run
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ "Would link" ]]
}
