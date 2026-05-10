---
layout: glossary-term
term: Subdomain
short: Specific friction type within a domain
category: analysis
related:
  - friction-taxonomy
  - domain
  - friction
---

A specific type of friction within a domain, providing granular classification for pattern detection.

## Format

Subdomains are written as `domain:subdomain`:

- `state:file-not-found`
- `state:resource-limit`
- `dependency:ruby-bundler`
- `type:typescript`

## Common Subdomains

### State
- `file-not-found` - Target file doesn't exist
- `resource-limit` - File too large, timeout
- `command-failed` - Non-zero exit code
- `conflict` - Merge conflicts, lock files

### Dependency
- `ruby-bundler` - Bundler resolution
- `node-npm` - npm/yarn failures
- `python-module` - Import errors

### Type
- `ruby-sorbet` - Sorbet errors
- `typescript` - TS compiler errors
- `inference` - Type inference failures

## In Weekly Reviews

```
### By Subdomain
- state:file-not-found: 232
- state:resource-limit: 226
- state:command-failed: 41
```
