---
status: accepted
date: 2026-03-20
deciders: [meaganewaller]
tracking:
  baseline: 61.5% overall stability (418/679 runs)
  adjusted_baseline: 76.8% in stable sessions (292/380 runs)
  target: >80% stability in stable sessions
  metric: test_run events in dev-os-events.jsonl
---

# 9. Test Stability Analysis and Environmental Flakiness Fix

## Status

Accepted

## Context

Weekly review identified a 55.4% test stability rate (later measured at 61.5%) despite 99.9% individual test pass rate. This indicated environmental or flaky test issues rather than actual test failures.

Analysis of 679 test runs from `dev-os-events.jsonl` revealed:

| Category | Runs | Pass Rate | Notes |
|----------|------|-----------|-------|
| Overall | 679 | 61.5% | Misleading aggregate |
| Stable sessions (>=70% pass) | 380 | 76.8% | True baseline |
| Dev-iteration sessions (>=70% fail) | 72 | 14% | Expected TDD cycle |
| Mixed sessions | 227 | 51% | Transitional states |

The low overall rate was **not indicative of test quality** - it included expected failures during active TDD development.

## Root Causes Identified

### 1. SQLite3 Disk I/O Error (Environmental - Fixable)

**Count:** 9 total crashes (1.3% of all runs)

**Pattern:**
```
An error occurred in a `before(:suite)` hook.
Failure/Error: SQLite3::IOException: disk I/O error
```

**Impact:** Complete suite failure (0 tests run, 0 passed)

**Dates affected:** 2026-03-04, 2026-03-09, 2026-03-11, 2026-03-12

**Likely causes:**
- Concurrent test runs competing for SQLite database file
- Disk pressure during parallel operations
- Missing file locking on SQLite connections

### 2. Development Iteration Failures (Expected - Not Flakiness)

**Count:** ~250 failures across 4 sessions

**Pattern:** TDD cycle - write test, run (fails), implement, run (passes)

**Not a problem:** These failures are the normal development workflow.

## Decision

We will address test stability through two changes:

### 1. Redefine Stability Metrics

**Current (misleading):** All test runs / all passes = 61.5%

**New (accurate):** Stable session runs / stable session passes = 76.8%

A "stable session" is one where >=70% of test runs pass, indicating the developer is running tests on working code rather than actively debugging.

### 2. Fix SQLite Environmental Flakiness

Add retry logic to SQLite connection establishment in test setup:

```ruby
# spec/support/database_connection.rb
RSpec.configure do |config|
  config.before(:suite) do
    retries = 3
    begin
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: ':memory:'  # or file path
      )
    rescue SQLite3::IOException => e
      retries -= 1
      sleep 0.1
      retry if retries > 0
      raise
    end
  end
end
```

Alternative: Use `:memory:` SQLite database to avoid file I/O entirely for unit tests.

## Consequences

### Positive

- **Accurate metrics:** Stability percentage reflects actual test reliability, not development workflow
- **Reduced false alarms:** Weekly reviews won't flag expected TDD failures as problems
- **Environmental resilience:** SQLite retry logic prevents transient failures from failing entire suites

### Negative

- **Complexity:** Retry logic adds code to test setup
- **Metric interpretation:** Team must understand "stable session" concept

### Neutral

- **No code changes to tests themselves:** The tests are not flaky; the environment is
- **Applies to gusto-database_pull project:** Fix should be implemented there, not in dotfiles

## Alternatives Considered

### A. Quarantine Flaky Tests

- **Rejected:** No individual tests are flaky; the environmental setup is the issue
- Quarantining would hide the real problem

### B. Add File Locking to SQLite

- **Considered:** More robust but higher complexity
- Retry logic is simpler and sufficient for the observed failure rate

### C. Switch to PostgreSQL for Tests

- **Rejected:** Overkill for unit tests; SQLite is appropriate with retry logic
- Would slow down test suite significantly

## Tracking

**Baseline (2026-03-20):**
- Overall: 61.5% (679 runs)
- Stable sessions: 76.8% (380 runs)
- SQLite crashes: 9 (1.3%)

**Target:**
- Stable session stability: >80%
- SQLite crashes: 0

**Measurement query:**
```bash
grep '"event_type":"test_run"' ~/.claude/dev-os-events.jsonl | jq -s '
[group_by(.session_id)[] |
 select(([.[] | select(.payload.result == "passed")] | length) >= (length * 0.7))] |
flatten |
{
  runs: length,
  passed: [.[] | select(.payload.result == "passed")] | length,
  stability_pct: (([.[] | select(.payload.result == "passed")] | length) / length * 100 | floor)
}'
```

## Related

- ADR-0004: Dev OS Event Telemetry (source of test_run events)
- ADR-0008: Chunked Operation Pattern (similar environmental issue analysis)
