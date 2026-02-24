#!/usr/bin/env bash
set -euo pipefail

# Run tests
if command -v bundle &>/dev/null && [[ -f "Gemfile" ]]; then
  if ! bundle exec rspec >/dev/null 2>&1; then
    echo "Tests are failing. Fix before completing task." >&2
    exit 2
  fi
fi

# Lint (Ruby example)
if command -v bundle &>/dev/null && bundle exec rubocop -V >/dev/null 2>&1; then
  if ! bundle exec rubocop >/dev/null 2>&1; then
    echo "Lint errors detected. Fix before completing task." >&2
    exit 2
  fi
fi

# Reversible migrations check
if [[ -d "db/migrate" ]]; then
  if grep -R "def change" db/migrate >/dev/null 2>&1; then
    # ok
    :
  else
    echo "Migration without reversible change detected." >&2
    exit 2
  fi
fi

# Public API docs (basic heuristic)
if git diff --cached | grep -q "public def"; then
  if ! grep -R "@doc\\|#\\s" app >/dev/null 2>&1; then
    echo "Public API change without documentation." >&2
    exit 2
  fi
fi

PAYLOAD='{"status":"passed"}'
echo "$INPUT" | .claude/hooks/dev-os-emit.sh task_completed "$PAYLOAD"

exit 0
