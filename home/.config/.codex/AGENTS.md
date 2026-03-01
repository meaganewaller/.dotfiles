# Codex DevOS Core

## Intent
Codex should operate with a DevOS mindset: explicit decisions, traceable tradeoffs, and policy-aware execution.

## Core Rules
- Prefer reversible changes and validate before broad edits.
- Keep rationale explicit when selecting among alternatives.
- Treat Codex runtime/auth/state files as local machine state, not repo-managed config.

## Cue Injection (Codex)
When a trigger matches, load the corresponding cue and follow it:
- commit/push/amend/rebase language or `git commit|push`: `~/.config/.codex/devos/cues/commit/cue.md`
- env/secrets/config language or `.env*` files: `~/.config/.codex/devos/cues/env/cue.md`
- migration/schema/database language or migration paths: `~/.config/.codex/devos/cues/migration/cue.md`
- decision/tradeoff language: `~/.config/.codex/devos/cues/principles/cue.md`

## Decision Journal
For non-trivial tradeoffs, add a journal entry in:
- `~/.config/.codex/devos/decision-journal/`

CLI:
- `codex-tradeoff "one-line summary"`
- `codex-tradeoff` (interactive template)

## Source of Truth
- Repo-managed DevOS assets: `~/.config/.codex/devos/`
