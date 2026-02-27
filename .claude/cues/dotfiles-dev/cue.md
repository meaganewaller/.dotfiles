---
pattern: hook|cue|skill|validate-path|hooks\.jsonc|governance
files: home/\.claude/hooks|home/\.claude/cues|home/\.claude/skills
scope: agent
description: Guidance for developing hooks, cues, and skills in this dotfiles project
vocabulary: hook cue skill telemetry event trigger matcher frontmatter macro
---

# Dotfiles Development

You're working on the Claude Code configuration system.

## Quick Reference

**Hooks:** `home/.claude/hooks/common/<Event>/` - source `validate-path.sh`, use `hook_register`

**Cues:** `home/.claude/cues/<name>/cue.md` - YAML frontmatter with `pattern:`, `scope:`, `provenance:`

**Wiring:** `home/.claude/settings/common/hooks.jsonc`

**Tests:** `./test/run-tests.sh` or `bats test/hooks/`

## Checklist

- [ ] ShellCheck passes
- [ ] Hook registered for health monitoring
- [ ] Cue has governance provenance
- [ ] BATS test added for new hooks
- [ ] Run `./bin/link-dotfiles` after changes
