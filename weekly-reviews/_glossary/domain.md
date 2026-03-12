---
layout: glossary-term
term: Domain
short: Top-level friction category
category: analysis
related:
  - friction-taxonomy
  - subdomain
  - friction
---

A top-level category in the friction taxonomy that groups related error types.

## Domains

- **state** - System state issues (file not found, resource limits)
- **syntax** - Parse and format errors
- **type** - Type system complaints
- **dependency** - Package resolution failures
- **permission** - Access control issues
- **network** - Connection problems
- **config** - Environment and configuration
- **testing** - Test execution failures
- **build** - Compilation errors

## In Weekly Reviews

Domains are aggregated to show where friction concentrates:

```
### By Domain
- state: 511
- dependency: 48
- syntax: 3
```

High concentration in a domain indicates an area for deliberate practice.
