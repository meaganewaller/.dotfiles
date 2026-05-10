---
layout: glossary-term
term: Trigger
short: Pattern that causes a cue to fire
category: guidance
related:
  - cue
  - pattern
aliases:
  - triggers
---

A pattern (regex, vocabulary, or semantic) that causes a cue to fire and inject guidance into a Claude Code session.

## Trigger Types

| Type | Field | Matches Against |
|------|-------|-----------------|
| Prompt | `pattern:` | User's prompt text |
| Command | `commands:` | Bash commands |
| File | `files:` | File paths being edited |
| Vocabulary | `vocabulary:` | Keywords in query |
| Semantic | `description:` | Intent similarity |

## Examples

**Prompt trigger:**
```yaml
pattern: commit|push|amend
```
Fires when user types "commit my changes"

**Command trigger:**
```yaml
commands: git\s+(commit|push|rebase)
```
Fires when Claude runs `git commit -m "..."`

**File trigger:**
```yaml
files: \.env$|\.env\.local$
```
Fires when Claude edits `.env.local`

## Matching Priority

1. **Regex match** - Exact pattern match
2. **Vocabulary match** - Any keyword present
3. **Semantic match** - Gzip NCD similarity (threshold: 0.65)

## Testing

```bash
~/.claude/hooks/common/match-cues.sh prompt "your test prompt"
~/.claude/hooks/common/match-cues.sh bash "git push"
~/.claude/hooks/common/match-cues.sh file ".env"
```
