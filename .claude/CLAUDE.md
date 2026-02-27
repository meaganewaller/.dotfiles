# Dotfiles Project

This is a dotfiles repository that manages personal development environment configuration, with a heavy focus on Claude Code integration ("Dev OS").

## Project Structure

```
.dotfiles/
├── home/                      # Files symlinked to $HOME
│   ├── .claude/               # Claude Code configuration (→ ~/.claude)
│   │   ├── hooks/             # Event-driven scripts
│   │   ├── cues/              # Contextual guidance injection
│   │   ├── skills/            # Reusable skill definitions
│   │   ├── governance/        # Policy traceability system
│   │   ├── principles/        # Engineering principles reference
│   │   └── docs/              # Structured documentation
│   ├── .config/               # XDG config files
│   ├── .local/bin/            # Personal scripts
│   └── .*                     # Dotfiles (.zshrc, .gitconfig, etc.)
│
├── bin/                       # Dotfiles management scripts
│   └── link-dotfiles          # Symlink manager
│
├── test/                      # BATS test suite
│   ├── hooks/                 # Hook contract tests
│   └── run-tests.sh           # Test runner
│
└── ARCHITECTURE.md            # System overview
```

## Key Conventions

### Hook Development

- Hooks live in `home/.claude/hooks/common/` organized by event
- Source `validate-path.sh` for utilities and health monitoring
- Use `hook_register "hook-name"` for observability
- Exit 0 for success; non-zero or JSON `{"ok":false}` to block
- Test hooks with BATS in `test/hooks/`

### Cue Development

- Cues live in `home/.claude/cues/<name>/cue.md`
- YAML frontmatter defines triggers (`pattern:`, `commands:`, `files:`)
- Use `scope: agent`, `scope: subagent`, or both
- Add `provenance:` block for governance traceability
- Optional `macro.sh` for dynamic content injection

### Documentation

- ADRs in `home/.claude/docs/architecture/` (use ADR cue for format)
- Follow single-source-of-truth principle (ADR-0001)
- Blog drafts in `home/.claude/docs/blog-drafts/`

### Testing

```bash
./test/run-tests.sh           # Run all tests
bats test/hooks/              # Run hook tests only
```

### Linking Changes

After modifying files in `home/`, run:
```bash
./bin/link-dotfiles
```

## Principles to Apply

When working on this project, consider:

- **Norming On Conventions**: Follow existing patterns in hooks, cues, skills
- **Simplifying For Change**: Hooks should be small and focused
- **Making Principled Choices**: Document tradeoffs in ADRs for significant decisions
- **Maintaining Your Tools**: This IS the tool maintenance project

See `home/.claude/principles/career-matrix.md` for full reference.

## Common Tasks

### Adding a New Hook

1. Create script in appropriate `home/.claude/hooks/common/<Event>/` directory
2. Source `validate-path.sh` and call `hook_register`
3. Wire in `home/.claude/settings/common/hooks.jsonc`
4. Add BATS test in `test/hooks/`

### Adding a New Cue

1. Create `home/.claude/cues/<name>/cue.md` with frontmatter
2. Add `provenance:` block linking to governance policy
3. Optional: create `macro.sh` for dynamic content
4. Test with `match-cues.sh` and `show-cue.sh`

### Creating an ADR

Mention "ADR" in your prompt to trigger the ADR cue, or:
1. Create `home/.claude/docs/architecture/NNNN-title.md`
2. Use standard template (status, context, decision, consequences, alternatives)
3. Update `README.md` index

### Updating Governance

1. Add/update policy in `home/.claude/governance/policies/`
2. Reference policy URI in relevant cue `provenance:` blocks
3. Run `governance.sh --lint` to verify

## Files to Know

| File | Purpose |
|------|---------|
| `home/.claude/hooks/common/validate-path.sh` | Shared utilities for all hooks |
| `home/.claude/settings/common/hooks.jsonc` | Hook wiring configuration |
| `home/.claude/hooks/README.md` | Comprehensive hook documentation |
| `ARCHITECTURE.md` | High-level system overview |

## Quality Checks

Before committing:
- `shellcheck` passes on all `.sh` files
- BATS tests pass
- No hardcoded paths (use `$HOME`, `$CLAUDE_HOME`, etc.)
