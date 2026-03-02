# Decision: Template Test Coverage Strategy

**Date:** 2026-03-02
**Status:** Accepted
**Context:** gusto-database_pull

## Summary

Added comprehensive test coverage for the install generator template (`database_pull.rb.erb`) using direct ERB rendering rather than full generator invocation.

## Options Considered

### 1. Add to "generator with --skip-prompts" block (Rejected)
- Tests full generator flow with filesystem setup
- Exercises variable auto-detection logic
- Slower execution, more setup required

**Rejected because:** The generator invocation tests already cover variable derivation. Template branch coverage is better served by fast, isolated tests.

### 2. Extend "template rendering" block (Chosen)
- Direct ERB rendering with controlled variables
- Fast execution, isolated from filesystem
- Matches existing pattern in the spec file

**Chosen because:** Follows established conventions, provides fast feedback, and cleanly separates concerns (generator logic vs template rendering).

### 3. Separate template_spec.rb file (Rejected)
- Would separate template tests from generator tests
- Cleaner file organization

**Rejected because:** Fragments related tests unnecessarily. Template and generator are tightly coupled.

## Tradeoffs

| Aspect | Benefit | Cost |
|--------|---------|------|
| Direct ERB rendering | Fast, isolated, easy variable control | Doesn't test generator's auto-detection |
| 17 new tests | Complete branch coverage | Increased maintenance burden |
| Comprehensive assertions | Each section fully verified | Slightly less granular failure diagnosis |

## Principles Applied

- **Norming On Conventions** - Extended existing spec pattern rather than introducing new structure
- **Making Principled Choices** - Chose speed/isolation over redundant integration coverage
- **Simplifying For Change** - One test per template section for clear ownership

## Implementation

Added 17 tests covering:
- Sanitization section example comments
- Webhooks configuration comments
- Validation section (production/staging boot-time)
- File system sink for non-production
- Background job TODO comments and TTL config
- Registry example comments (direct, indirect, polymorphic, full_table)
- AWS region interpolation
- All skipped section variants
- File header pragmas
- Full integration (all features enabled/disabled)

## Reversal Cost

**Low** - Tests can be removed or reorganized without affecting gem functionality.
