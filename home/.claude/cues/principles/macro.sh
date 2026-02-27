#!/usr/bin/env bash
# Suggests relevant career matrix behaviors based on context
set -euo pipefail

# Read the query from environment or stdin
QUERY="${CUE_QUERY:-}"
if [[ -z "$QUERY" ]]; then
  QUERY=$(cat 2>/dev/null || echo "")
fi

QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')

# Collect relevant behaviors
BEHAVIORS=()

# Architecture/design decisions
if echo "$QUERY_LOWER" | grep -qE 'architect|design|structure|pattern|api|interface|module|service|extract|layer'; then
  BEHAVIORS+=("**Planning Your Approach:** Validate with colleagues, raise obstacles early, share progress continuously.")
  BEHAVIORS+=("**Making Principled Choices:** Show your work—explain trade-offs, constraints, and risks that weighed in the balance.")
fi

# Debugging/investigation
if echo "$QUERY_LOWER" | grep -qE 'debug|error|fail|broke|broken|fix|issue|bug|unexpected|wrong|investigate'; then
  BEHAVIORS+=("**Uncovering Root Causes:** Interrogate the system directly. Use debuggers, REPLs, stack traces before reaching for Google.")
fi

# Refactoring
if echo "$QUERY_LOWER" | grep -qE 'refactor|clean|simplify|technical debt|legacy|complex|complicated'; then
  BEHAVIORS+=("**Simplifying For Change:** \"Make the change easy, then make the easy change.\" Refactor before introducing significant changes.")
  BEHAVIORS+=("**Norming On Conventions:** Even if a design is \"bad\", it may be easy to remediate if it's consistently bad.")
fi

# Testing
if echo "$QUERY_LOWER" | grep -qE 'test|spec|coverage|rspec|jest|assert'; then
  BEHAVIORS+=("**Testing With Purpose:** Tests should minimally specify behavior, express intent clearly, and only fail for useful reasons.")
fi

# Tooling/conventions
if echo "$QUERY_LOWER" | grep -qE 'tool|config|setup|convention|standard|format|lint|hook'; then
  BEHAVIORS+=("**Maintaining Your Tools:** Automate repetitive tasks, share tips, stay open to others' preferences for collaboration.")
  BEHAVIORS+=("**Norming On Conventions:** Weigh \"better ways\" against the costs of diverging from the norm.")
fi

# Communication/feedback
if echo "$QUERY_LOWER" | grep -qE 'communicate|feedback|review|present|explain|document|share'; then
  BEHAVIORS+=("**Communicating With Empathy:** Pair message with appropriate medium. Consider others' incentives and constraints.")
  BEHAVIORS+=("**Developing Thought Leadership:** Learn in the open by sharing discoveries, experiences, and insights.")
fi

# Scale/performance
if echo "$QUERY_LOWER" | grep -qE 'scale|performance|optimize|slow|fast|efficient|bottleneck'; then
  BEHAVIORS+=("**Optimizing For Scale:** Address growing pains—early architecture decisions, CI/CD slowness, shared codebase friction.")
fi

# Generic decision language (fallback)
if [[ ${#BEHAVIORS[@]} -eq 0 ]] && echo "$QUERY_LOWER" | grep -qE 'should|decide|choice|option|approach|versus|vs'; then
  BEHAVIORS+=("**Making Principled Choices:** Gather perspectives, weigh trade-offs, incorporate constraints (budget, maintenance capability).")
  BEHAVIORS+=("**Planning Your Approach:** Validate approach with colleagues, raise concerns when you foresee obstacles.")
fi

# Output if we found relevant behaviors
if [[ ${#BEHAVIORS[@]} -gt 0 ]]; then
  echo ""
  echo "**Relevant behaviors for this context:**"
  echo ""
  for behavior in "${BEHAVIORS[@]}"; do
    echo "- $behavior"
  done
fi
