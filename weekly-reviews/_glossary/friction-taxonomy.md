---
layout: glossary-term
term: Friction Taxonomy
short: Hierarchical classification of tool failures
category: analysis
related:
  - friction
  - domain
  - subdomain
aliases:
  - taxonomy
---

A hierarchical classification system for tool failures, enabling pattern detection and skill gap identification.

## Primary Domains

| Domain | Description |
|--------|-------------|
| `state` | File not found, resource limits, conflicts |
| `syntax` | Parse errors, encoding issues |
| `type` | Type mismatches, inference failures |
| `dependency` | Missing packages, version conflicts |
| `permission` | Access denied, auth failures |
| `network` | Connection, timeout, SSL errors |
| `config` | Missing env vars, misconfiguration |
| `testing` | Test failures, assertions |
| `build` | Compilation, bundling errors |

## Subdomain Examples

- `state:file-not-found` - Read/edit targets missing file
- `state:resource-limit` - File too large, timeout exceeded
- `dependency:ruby-bundler` - Bundler resolution failure
- `type:typescript` - TypeScript compiler error

## Usage

The taxonomy enables:

- Aggregating friction by category
- Identifying recurring patterns
- Targeting deliberate practice
- Escalating repeated issues
