# Codex DevOS Governance

Policy provenance tooling for Codex cue guidance.

## Commands

```bash
# Coverage report
dotfiles codex-governance

# Missing provenance
dotfiles codex-governance --gaps

# Integrity validation
dotfiles codex-governance --lint

# JSON output
dotfiles codex-governance --json
```

## Scope

- Cue roots: `~/.config/.codex/devos/cues` and dotfiles Codex cues.
- Policies/controls: `~/.config/.codex/devos/governance/{policies,controls}`.
