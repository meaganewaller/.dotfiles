#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Dotfiles Test Suite ===${NC}"
echo

# Track failures
FAILED=0

# ============================================================================
# 1. Shell Script Syntax Check
# ============================================================================
echo -e "${YELLOW}[1/5] Checking shell script syntax...${NC}"

SYNTAX_ERRORS=0
while IFS= read -r -d '' script; do
  if ! bash -n "$script" 2>/dev/null; then
    echo -e "${RED}  ✗ Syntax error: $script${NC}"
    ((SYNTAX_ERRORS++))
  fi
done < <(find "$DOTFILES_ROOT" -name "*.sh" -not -path "*/.git/*" -print0)

if [[ $SYNTAX_ERRORS -eq 0 ]]; then
  echo -e "${GREEN}  ✓ All shell scripts have valid syntax${NC}"
else
  echo -e "${RED}  ✗ $SYNTAX_ERRORS scripts have syntax errors${NC}"
  ((FAILED++))
fi
echo

# ============================================================================
# 2. Shellcheck Linting
# ============================================================================
echo -e "${YELLOW}[2/5] Running shellcheck...${NC}"

if command -v shellcheck &>/dev/null; then
  LINT_WARNINGS=0

  # Check hook scripts with stricter settings
  while IFS= read -r -d '' script; do
    if ! shellcheck -S warning "$script" 2>/dev/null; then
      ((LINT_WARNINGS++))
    fi
  done < <(find "$DOTFILES_ROOT/home/.claude/hooks" -name "*.sh" -print0 2>/dev/null)

  if [[ $LINT_WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}  ✓ No shellcheck warnings${NC}"
  else
    echo -e "${YELLOW}  ⚠ $LINT_WARNINGS files have shellcheck warnings${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ shellcheck not installed, skipping${NC}"
fi
echo

# ============================================================================
# 3. JSON Validation
# ============================================================================
echo -e "${YELLOW}[3/5] Validating JSON files...${NC}"

JSON_ERRORS=0
while IFS= read -r -d '' json_file; do
  if ! python3 -m json.tool "$json_file" >/dev/null 2>&1; then
    echo -e "${RED}  ✗ Invalid JSON: $json_file${NC}"
    ((JSON_ERRORS++))
  fi
done < <(find "$DOTFILES_ROOT" -name "*.json" -not -path "*/.git/*" -not -path "*/node_modules/*" -print0)

if [[ $JSON_ERRORS -eq 0 ]]; then
  echo -e "${GREEN}  ✓ All JSON files are valid${NC}"
else
  echo -e "${RED}  ✗ $JSON_ERRORS JSON files are invalid${NC}"
  ((FAILED++))
fi
echo

# ============================================================================
# 4. BATS Tests (if available)
# ============================================================================
echo -e "${YELLOW}[4/5] Running BATS tests...${NC}"

if command -v bats &>/dev/null; then
  if [[ -d "$SCRIPT_DIR/hooks" ]]; then
    if bats "$SCRIPT_DIR/hooks/"*.bats; then
      echo -e "${GREEN}  ✓ All BATS tests passed${NC}"
    else
      echo -e "${RED}  ✗ Some BATS tests failed${NC}"
      ((FAILED++))
    fi
  else
    echo -e "${YELLOW}  ⚠ No BATS test files found${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ BATS not installed, skipping unit tests${NC}"
  echo "     Install with: brew install bats-core"
fi
echo

# ============================================================================
# 5. Python Tests (if pytest available)
# ============================================================================
echo -e "${YELLOW}[5/5] Running Python tests...${NC}"

if command -v pytest &>/dev/null; then
  if [[ -d "$SCRIPT_DIR/python" ]]; then
    if pytest "$SCRIPT_DIR/python" -v; then
      echo -e "${GREEN}  ✓ All Python tests passed${NC}"
    else
      echo -e "${RED}  ✗ Some Python tests failed${NC}"
      ((FAILED++))
    fi
  else
    echo -e "${YELLOW}  ⚠ No Python test files found${NC}"
  fi
else
  echo -e "${YELLOW}  ⚠ pytest not installed, skipping Python tests${NC}"
fi
echo

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}=== Summary ===${NC}"
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}$FAILED test suite(s) failed${NC}"
  exit 1
fi
