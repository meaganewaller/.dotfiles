# Governance Compatibility Layer

Canonical governance source now lives at:

- `home/.claude/governance/`

This top-level `governance/` directory is retained as a compatibility shim for older paths and commands.

## What to use

```bash
dotfiles governance
```

This command now runs:

- `home/.claude/governance/bin/governance.sh`

## Notes

- Avoid adding or editing policy content in this compatibility directory.
- Add policies, controls, and tooling updates under `home/.claude/governance/`.
