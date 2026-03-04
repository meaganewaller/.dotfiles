---
# Triggers when editing shell scripts
pattern: bash|shell|script|hook
commands: bash|sh|chmod.*\+x
files: \.sh$|\.bash$|bin/|hooks/
scope: agent, subagent
description: Shell script best practices for reliability and maintainability
vocabulary: bash shell script hook bin executable shebang
provenance:
  policy:
    - uri: home/.claude/governance/policies/code-standards.md
      type: governance-doc
  controls:
    - id: SHELL-001
      name: Shell Script Standards
      justifications:
        - set -euo pipefail prevents silent failures
        - shellcheck catches common bugs
        - Proper quoting prevents word splitting issues
  verified: 2026-03-04
  rationale: >
    204 shell scripts edited with no file-trigger cues firing.
    Shell scripts need reliability guidance especially in hooks.
---

# Shell Script Checklist

When writing or editing shell scripts:

## Reliability

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined var, pipe failure
```

## Common Pitfalls

- **Quote variables**: `"$VAR"` not `$VAR` (prevents word splitting)
- **Use `[[` not `[`**: `[[ -f "$file" ]]` is safer and more powerful
- **Check commands exist**: `command -v foo >/dev/null` before using
- **Handle empty results**: `|| true` for commands that may return nothing

## Before Committing

- [ ] `shellcheck` passes (or warnings understood)
- [ ] Error cases handled (what if file doesn't exist?)
- [ ] Exit codes are meaningful (0 = success)

See project hooks for examples: `home/.claude/hooks/common/`
