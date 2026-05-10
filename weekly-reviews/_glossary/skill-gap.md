---
layout: glossary-term
term: Skill Gap
short: Recurring friction pattern indicating practice area
category: analysis
related:
  - friction
  - deliberate-practice
  - escalation
aliases:
  - skill gaps
---

A recurring friction pattern that indicates an area for deliberate practice, detected by analyzing friction logs over time.

## Detection

Skill gaps are identified when:

- Same friction domain appears repeatedly (3+ occurrences)
- Pattern persists across multiple sessions
- Errors cluster around specific tools or file types

## Example

```
Week 1: state:file-not-found (45 occurrences)
Week 2: state:file-not-found (38 occurrences)
Week 3: state:file-not-found (52 occurrences)

→ Skill gap identified: defensive file operations
```

## Response

When a skill gap is identified:

1. **Escalation** - Warning surfaces at session start
2. **Analysis** - Weekly review includes root cause breakdown
3. **Practice plan** - Concrete exercises recommended
4. **Tracking** - Progress measured week-over-week

## Common Skill Gaps

| Pattern | Skill Gap | Practice |
|---------|-----------|----------|
| file-not-found | File existence checks | Guard patterns |
| resource-limit | Chunked operations | Pagination |
| type errors | Type annotations | Strict mode |
