---
# When user prompt or bash command matches, show this cue.
pattern: commit|push|amend
commands: git\s+(commit|push)
scope: agent
---

# Commit / push cue

- Prefer **conventional commits**: `type(scope): message` (e.g. `fix(auth): handle expired token`).
- Keep the subject line under 72 characters; add a body if the change needs explanation.
- Before pushing, ensure tests pass and you’ve pulled the latest; avoid force-pushing to shared branches.
