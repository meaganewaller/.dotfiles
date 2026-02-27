---
# When user prompt or bash command matches, show this cue.
pattern: commit|push|amend
commands: git\s+(commit|push)
scope: agent, subagent
description: Git commit workflow, version control, and change management
vocabulary: commit push amend rebase squash merge changelog version
provenance:
  policy:
    - uri: governance/policies/code-lifecycle.md
      type: governance-doc
  controls:
    - id: ENG-COMMIT-001
      name: Structured Change Records
      framework_ref: NIST SP 800-53 CM-3
      justifications:
        - Conventional commit types classify changes by nature
        - Atomic commits make each change independently reviewable
    - id: ENG-COMMIT-002
      name: Atomic Change Units
      justifications:
        - Single logical change per commit enables clean bisection
        - Independent review and reversion of each change
    - id: ENG-COMMIT-003
      name: Pre-Push Verification
      justifications:
        - Tests must pass before pushing to shared branches
        - Pull latest to avoid merge conflicts
  verified: 2026-02-26
  rationale: >
    Conventional commits create structured change records supporting
    automated changelog generation and compliance auditing. Atomic
    commits enable independent review and safe rollback.
---

# Commit / push cue

- Prefer **conventional commits**: `type(scope): message` (e.g. `fix(auth): handle expired token`).
- Keep the subject line under 72 characters; add a body if the change needs explanation.
- Before pushing, ensure tests pass and you’ve pulled the latest; avoid force-pushing to shared branches.
