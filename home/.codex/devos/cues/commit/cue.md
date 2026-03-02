---
pattern: commit|push|amend
commands: git\s+(commit|push)
scope: agent, subagent
description: Git commit workflow, version control, and change management
vocabulary: commit push amend rebase squash merge changelog version
provenance:
  policy:
    - uri: home/.config/.codex/devos/governance/policies/code-lifecycle.md
      type: governance-doc
  controls:
    - id: ENG-COMMIT-001
      name: Structured Change Records
      justifications:
        - Conventional commit types classify changes by nature.
        - Atomic commits make each change independently reviewable.
  verified: 2026-03-01
  rationale: >
    Conventional commits and atomic change units improve reviewability,
    rollback safety, and change traceability.
---

# Commit / Push Cue

- Prefer conventional commits: `type(scope): message`.
- Keep commit subjects short and add rationale in the body when needed.
- Keep commits atomic and independently reversible.
- Before push, run relevant tests and sync latest branch state.
