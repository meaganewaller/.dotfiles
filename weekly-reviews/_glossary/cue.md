---
layout: glossary-term
term: Cue
short: Context-aware guidance injected on trigger match
category: guidance
related:
  - hook
  - trigger
  - pattern
aliases:
  - cues
---

Context-aware guidance injected into Claude Code sessions when triggers match. Cues are "compiled policy" - governance documents compressed into agent directives.

## Trigger Types

| Type | Field | Example |
|------|-------|---------|
| Prompt | `pattern:` | `commit\|push\|amend` |
| Command | `commands:` | `git\s+(commit\|push)` |
| File | `files:` | `\.env$\|\.env\.local$` |

## Cue Format

```yaml
---
pattern: commit|push
scope: agent
description: Git commit workflow
vocabulary: commit push amend rebase
---

# Commit Cue

- Use conventional commit format
- Sign commits with GPG
- Keep commits atomic
```

## Matching Priority

1. **Regex match** - pattern/commands/files fields
2. **Vocabulary match** - Keywords in vocabulary field
3. **Semantic match** - Similarity to description

## Once-Per-Session

Each cue fires at most once per session to avoid repetition.
