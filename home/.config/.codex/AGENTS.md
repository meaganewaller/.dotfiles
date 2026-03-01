# Codex DevOS Core

## Intent
Codex should operate with a DevOS mindset: explicit decisions, traceable tradeoffs, and policy-aware execution.

## Operating Rules
- Prefer reversible changes and validate before broad edits.
- Capture non-obvious tradeoffs in the decision journal.
- Keep governance checks linked to concrete policies.
- Treat Codex runtime/auth/state files as local machine state, not repo-managed config.

## Sources
- DevOS artifacts live under `devos/`.
- This file is repository-managed and safe to version.
