---
name: refactor-safely
description: This skill should be used when planning a refactor, asking "how do I safely change this?", "what's the safest way to restructure?", or before touching legacy code, renaming abstractions, or extracting modules. Creates staged refactor plans with validation checkpoints and rollback strategies.
argument-hint: code, module, or area to refactor
context: fork
agent: Plan
---

# Refactor Safely

Create a safe staged refactor plan with checkpoints and rollback strategy.

**Principle:** Optimize for safety over speed. Prefer reversible moves.

## Refactor Target

$ARGUMENTS

---

## Step 1: Assess Safety Preconditions

Before touching code, verify:

### Test Coverage

| Coverage Level | Safety | Action |
|----------------|--------|--------|
| >80% on target code | High | Proceed with confidence |
| 50-80% | Medium | Add characterization tests first |
| <50% | Low | Write tests before refactoring |
| 0% (untested legacy) | Critical | Write approval tests first |

```bash
# Check coverage for target files
# (tool-specific: lcov, simplecov, coverage.py, etc.)
```

### Characterization Tests

For untested code, write tests that capture current behavior:

```
1. Call the code with representative inputs
2. Record actual outputs (even if "wrong")
3. Assert on those outputs
4. These tests protect against unintended changes
```

### Dependency Mapping

| Question | Impact |
|----------|--------|
| What depends on this? | Downstream breakage risk |
| What does this depend on? | Upstream assumptions |
| Is this called dynamically? | Harder to find usages |
| Is this in a public API? | External compatibility |

---

## Step 2: Choose Refactoring Strategy

### Safe Refactoring Patterns

| Pattern | When to Use | Risk |
|---------|-------------|------|
| **Rename** | Names don't reflect purpose | Low |
| **Extract** | Code does too much | Low |
| **Inline** | Abstraction not earning its keep | Low |
| **Move** | Wrong location/layer | Medium |
| **Replace** | Algorithm/approach change | Medium |
| **Restructure** | Fundamental reorganization | High |

### The Mikado Method (for complex refactors)

```
1. Try the change you want to make
2. If it breaks, revert immediately
3. Note what broke (prerequisite)
4. Repeat on prerequisites until you find one that works
5. Build up from working changes
```

```
Goal: Extract PaymentService
    │
    ├── Prerequisite: Move payment methods from Order
    │       │
    │       └── Prerequisite: Add tests for payment flow
    │
    └── Prerequisite: Define PaymentService interface
```

### Strangler Fig Pattern (for large replacements)

```
┌─────────────────────────────────────────────────┐
│ Phase 1: New code alongside old                 │
│          Old: 100% traffic                      │
├─────────────────────────────────────────────────┤
│ Phase 2: Route some traffic to new              │
│          Old: 90% → New: 10%                    │
├─────────────────────────────────────────────────┤
│ Phase 3: Gradually shift traffic                │
│          Old: 10% → New: 90%                    │
├─────────────────────────────────────────────────┤
│ Phase 4: Remove old code                        │
│          New: 100%                              │
└─────────────────────────────────────────────────┘
```

---

## Step 3: Plan Atomic Commits

### What Makes a Commit Atomic?

| Atomic | Not Atomic |
|--------|------------|
| Single logical change | Multiple unrelated changes |
| Tests pass before and after | Tests broken mid-sequence |
| Can be reverted independently | Revert breaks other things |
| Self-contained diff | Requires other commits to make sense |

### Commit Sequence Patterns

#### Rename Refactor
```
1. Add alias/deprecation pointing old → new
2. Update all callers to use new name
3. Remove old name
```

#### Extract Refactor
```
1. Copy code to new location
2. New location calls/delegates to old
3. Update callers to use new location
4. Move logic from old to new
5. Remove old code
```

#### Move Refactor
```
1. Create new file with re-export from old
2. Update imports to new location
3. Move implementation to new file
4. Remove re-export, delete old file
```

### Commit Message Convention

```
refactor(scope): [step X/N] description

Part of: [link to refactor plan/issue]
Safe to revert: yes
Tests: passing
```

---

## Step 4: Define Validation Checkpoints

### After Each Commit

| Check | Command | Must Pass |
|-------|---------|-----------|
| Tests | `./run_tests.sh` | Yes |
| Types | `tsc --noEmit` / `srb tc` | Yes |
| Lint | `eslint` / `rubocop` | Yes |
| Build | `make build` | Yes |

### At Phase Boundaries

| Check | Purpose |
|-------|---------|
| Manual smoke test | Verify key flows work |
| Review diff so far | Ensure direction is right |
| Run full test suite | Catch integration issues |
| Check metrics/logs | No new errors in staging |

### Before Completing

| Check | Purpose |
|-------|---------|
| All TODOs resolved | No cleanup left behind |
| Documentation updated | README, comments current |
| No dead code | Old paths removed |
| Performance check | No regression |

---

## Step 5: Establish Rollback Strategy

### Rollback Levels

| Level | When | How |
|-------|------|-----|
| **Single commit** | Last change broke something | `git revert HEAD` |
| **Phase** | Direction was wrong | `git revert HEAD~N..HEAD` |
| **Full refactor** | Need to abandon | Revert PR or reset branch |

### Rollback Readiness Checklist

- [ ] Each commit is independently revertable
- [ ] No data migrations that can't be undone
- [ ] Feature flag can disable new code path
- [ ] Old code still exists until fully validated
- [ ] Deployment can be rolled back quickly

### Safe Rollback Patterns

#### Keep Old Code Until Validated
```
# Phase 1: Both paths exist
if feature_flag_enabled?(:new_payment_flow)
  NewPaymentService.process(order)
else
  order.process_payment  # old path
end

# Phase 2: After validation, remove old path
NewPaymentService.process(order)
```

#### Database Rollback Safety
```
# Safe: Additive changes
- Add new column (nullable)
- Add new table
- Add new index

# Unsafe: Destructive changes (defer until end)
- Drop column
- Drop table
- Rename column
```

---

## Step 6: Define Done

### Completion Criteria

| Criterion | Verified |
|-----------|----------|
| All planned changes complete | [ ] |
| Tests pass (including new tests) | [ ] |
| No increase in tech debt | [ ] |
| Old code removed | [ ] |
| Documentation updated | [ ] |
| Team informed of changes | [ ] |
| Monitoring confirms stability | [ ] |

### Success Metrics

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| Test coverage | X% | Y% | ≥X% |
| Cyclomatic complexity | X | Y | ≤X |
| Lines of code | X | Y | Context-dependent |
| Build time | Xs | Ys | ≤X |

---

## Output Format

### Refactor Plan: [Target]

#### Safety Assessment

| Precondition | Status | Action Needed |
|--------------|--------|---------------|
| Test coverage | X% | [if <80%, write tests first] |
| Dependencies mapped | Yes/No | [list dependents] |
| Rollback possible | Yes/No | [blockers if no] |

#### Strategy

**Pattern:** [Rename/Extract/Move/Strangler/Mikado]

**Rationale:** [Why this approach]

#### Staged Plan

| Phase | Commits | Validation | Rollback |
|-------|---------|------------|----------|
| 1 | [list] | [checks] | [how] |
| 2 | [list] | [checks] | [how] |
| 3 | [list] | [checks] | [how] |

#### Commit Sequence

```
[ ] Commit 1: [description]
    - Changes: [files]
    - Validation: [tests to run]

[ ] Commit 2: [description]
    - Changes: [files]
    - Validation: [tests to run]

[ ] Commit 3: [description]
    - Changes: [files]
    - Validation: [tests to run]
```

#### Rollback Plan

| Scenario | Action |
|----------|--------|
| Single commit fails | `git revert [sha]` |
| Phase fails | [specific steps] |
| Full abort | [specific steps] |

#### Definition of Done

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

#### Estimated Effort

| Phase | Time | Risk |
|-------|------|------|
| 1 | [estimate] | Low/Med/High |
| 2 | [estimate] | Low/Med/High |
| Total | [estimate] | |
