#!/usr/bin/env bash
set +e

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Must be sourced:"
  echo "  source setup.sh"
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT/lib/env.sh"

setup_path
setup_aliases
setup_flags

echo "Environment loaded."
