# Troubleshooting

> **Audience**: Operators debugging issues

Common issues and solutions for the Claude Code configuration.

## Settings Issues

### Settings not updating

```bash
# Re-run installer
mise run claude:refresh

# Check merged output
cat ~/.claude/settings.json | jq .

# Verify JSONC syntax (look for parse errors)
node -e "require('fs').readFileSync('settings/common/base.jsonc', 'utf8')"
```

### Profile not applied

```bash
# Check current profile
echo $DOTFILES_PROFILE

# Set explicitly
export DOTFILES_PROFILE=work

# Re-run installer
mise run claude:refresh
```

### Merge conflicts

If settings have unexpected values:

```bash
# Check what files are being merged
ls -la settings/common/*.jsonc settings/$DOTFILES_PROFILE/*.jsonc

# Preview merge without applying
mise run claude:dry-run
```

## Hook Issues

### Hooks not firing

```bash
# Check hook is executable
ls -la ~/.claude/hooks/PostToolUse/

# Verify hook is in settings
jq '.hooks.PostToolUse' ~/.claude/settings.json

# Check for syntax errors
bash -n ~/.claude/hooks/common/PostToolUse/my-hook.sh
```

### Hook errors

```bash
# Check hook health
~/.claude/hooks/common/hook-health.sh --failures

# Test hook manually
echo '{"tool_name": "Write"}' | ~/.claude/hooks/common/PostToolUse/impact-extractor.sh

# Check exit code
echo $?
```

### Hook blocking unexpectedly

```bash
# For Stop hooks, check what's blocking
~/.claude/hooks/common/PostToolUse/hard-stop-test-blocker.sh < /dev/null

# Check pending tradeoffs
ls ~/.claude/pending-tradeoffs/

# Clear if needed (understand why first!)
rm ~/.claude/pending-tradeoffs/*
```

## Event Logging Issues

### Events not logging

```bash
# Check event file exists and is writable
ls -la ~/.claude/dev-os-events.jsonl

# Check recent events
tail -5 ~/.claude/dev-os-events.jsonl

# Verify JSON validity
tail -1 ~/.claude/dev-os-events.jsonl | jq .
```

### Friction log empty

```bash
# Check friction log
tail -5 ~/.claude/skill-friction-log.jsonl

# Verify skill-gap-detector is running
jq '.hooks.PostToolUseFailure' ~/.claude/settings.json
```

### Log files too large

```bash
# Check sizes
du -h ~/.claude/*.jsonl

# Rotate logs (keep last 1000 lines)
tail -1000 ~/.claude/dev-os-events.jsonl > ~/.claude/dev-os-events.jsonl.tmp
mv ~/.claude/dev-os-events.jsonl.tmp ~/.claude/dev-os-events.jsonl
```

## Cue Issues

### Cue not matching

```bash
# Test matching directly
bash ~/.claude/hooks/common/match-cues.sh prompt "your test prompt"

# Check cue frontmatter
head -20 ~/.claude/cues/my-cue/cue.md

# Verify regex
echo "test string" | grep -E 'your|pattern'
```

### Cue firing multiple times

```bash
# Check marker file
ls /tmp/.claude-devos-cue-*

# Clear markers (will allow cues to fire again)
rm /tmp/.claude-devos-cue-*
```

### Macro not executing

```bash
# Check macro is executable
ls -la ~/.claude/cues/my-cue/macro.sh

# Test macro directly
SESSION_ID=test CUE_DIR=~/.claude/cues/my-cue ~/.claude/cues/my-cue/macro.sh
```

## Skill Issues

### Skill not appearing

```bash
# Check skill file exists
ls -la ~/.claude/skills/common/my-skill/SKILL.md

# Verify frontmatter
head -10 ~/.claude/skills/common/my-skill/SKILL.md

# Refresh configuration
mise run claude:refresh
```

### Weekly review fails

```bash
# Check dependencies
which jq python3

# Make scripts executable
chmod +x ~/.claude/skills/weekly-review/scripts/*.sh
chmod +x ~/.claude/skills/weekly-review/scripts/*.py

# Test aggregation script
~/.claude/skills/weekly-review/scripts/aggregate.sh
```

## Symlink Issues

### Symlinks broken

```bash
# Check symlink status
ls -la ~/.claude

# Re-link
mise run claude:refresh

# Or manually
./home/.claude/install.sh --profile $DOTFILES_PROFILE
```

### Conflict with existing files

```bash
# Check what's at the path
ls -la ~/.claude/hooks

# Backup and re-link
mv ~/.claude/hooks ~/.claude/hooks.backup
mise run claude:refresh
```

## Governance Issues

### Governance scan fails

```bash
# Check Python is available
which python3

# Test scanner directly
python3 ~/.claude/governance/bin/provenance-scan.py

# Check for YAML parse errors
head -50 ~/.claude/cues/my-cue/cue.md
```

### Missing provenance

```bash
# Find cues without provenance
dotfiles governance --gaps

# Lint all provenance
dotfiles governance --lint
```

## Getting Help

### Collect diagnostic info

```bash
# System info
echo "Profile: $DOTFILES_PROFILE"
echo "Shell: $SHELL"
uname -a

# Check installation
ls -la ~/.claude/
jq '.hooks | keys' ~/.claude/settings.json

# Recent errors
~/.claude/hooks/common/hook-health.sh --failures
```

### Common environment issues

| Issue | Check | Fix |
|-------|-------|-----|
| `jq: command not found` | `which jq` | `brew install jq` |
| `python3: command not found` | `which python3` | Install via mise or brew |
| `permission denied` | `ls -la script.sh` | `chmod +x script.sh` |
| `CLAUDE_PROJECT_DIR not set` | Running outside Claude Code | Use in Claude Code session |

## Related Documentation

- [Overview](hooks-and-cues/overview.md) - System architecture
- [Writing Hooks](hooks-and-cues/writing-hooks.md) - Hook development
- [Writing Cues](hooks-and-cues/writing-cues.md) - Cue development
