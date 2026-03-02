# Decision: Generator Test Coverage Strategy

**Date:** 2026-03-02
**Status:** Accepted
**Context:** gusto-database_pull

## Summary

Added generator invocation tests to achieve SimpleCov branch coverage for ERB template conditionals, complementing existing direct ERB rendering tests.

## Options Considered

### 1. Only Add Direct ERB Template Tests (Rejected)
- Fast execution, isolated, easy to set up
- Full control over template variables

**Rejected because:** Direct ERB rendering doesn't go through SimpleCov instrumentation, so branches show 0 coverage even when tested.

### 2. Add Generator Invocation Tests (Chosen)
- Uses `described_class.start()` which SimpleCov tracks
- Requires temp directories, YAML files, environment setup
- Some branches need stubs to trigger

**Chosen because:** SimpleCov branch coverage is a project requirement. Generator invocation tests prove the template works end-to-end.

### 3. Modify Generator CLI Options (Rejected)
- Add `--inactive-databases` flag
- Would enable testing without stubs

**Rejected because:** Adds production code complexity solely for testing purposes. Stubbing is sufficient.

## Tradeoffs

| Aspect | Benefit | Cost |
|--------|---------|------|
| Generator invocation tests | Real SimpleCov coverage | Slower, more setup |
| Stubbing `detect_databases` | No production code changes | Less integrated test |
| ENV manipulation for REDIS_URL | Tests real behavior | Coupling to environment |
| Multiple test approaches | Both speed and coverage | Maintenance of two styles |

## Principles Applied

- **Making Principled Choices** - Chose generator tests because coverage metrics are required
- **Norming On Conventions** - Followed existing test patterns (temp dirs, YAML setup)
- **Simplifying For Change** - Used stubs rather than adding CLI options

## Implementation

Added 3 generator invocation tests:
1. `with REDIS_URL environment variable set` - covers `@redis_url.present?` true branch (line 154-159)
2. `with ArDoc files present` - covers `@use_ar_doc` true branch (line 226-229)
3. `with inactive database via stubbed prompt` - covers `db[:active]` false branch (line 30-37)

## Reversal Cost

**Low** - Tests can be removed without affecting production code.
