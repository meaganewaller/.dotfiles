# Documentation Coverage Report Template (Ruby)

# Documentation Report: {project_name}

## Summary
- **Files analyzed**: 45
- **Methods documented**: 120/150 (80%)
- **Classes/modules documented**: 25/25 (100%)
- **API endpoints documented**: 30/30 (100%)

## Coverage Before/After
- Before: 45%
- After: 92%

## Files Modified

| File | Methods Added | Notes |
|------|---------------|-------|
| app/services/user_sync.rb | 8 | All public methods |
| app/services/auth/token_service.rb | 5 | Added usage examples |
| app/controllers/api/v1/users_controller.rb | 6 | Added endpoint docs |
| app/serializers/user_serializer.rb | 4 | Documented attributes/relationships |


## API Documentation

- **Framework**: Ruby on Rails (API)
- **Strategy (choose one)**:
  - **rswag** (Swagger/OpenAPI from request specs)
  - **OpenAPI-first** (commit openapi.yaml, validate in CI)
  - **Grape** / **roar** / **jsonapi-serializer** docs (if applicable)
- **Swagger UI** (rswag): /api-docs
- **OpenAPI spec** (rswag): /api-docs/v1/swagger.yaml (or .json)

## Documentation Style

- **Ruby**: YARD tags (preferred) or RDoc
  - YARD: `@param`, `@return`, `@raise`, `@example`
  - RDoc: `# :nodoc:` for exclusions, basic narrative docs
- **Rails**:
  - Controllers: endpoint purpose + params + auth + status codes
  - Models: validations, callbacks, invariants, business rules
  - Services/Jobs: inputs/outputs + side effects (DB writes, HTTP calls, enqueue)

## Next Steps

### Recommendations
1. Run `bundle exec yard doc` (or `yard stats`) to verify coverage trends
2. Add RuboCop enforcement for doc style (or a docs gate via yardstick)
3. Add examples for “sharp edges” (side effects, retries, idempotency)
4. Add CI checks for doc coverage and OpenAPI drift

### Missing Documentation
| File | Missing | Priority |
|------|---------|----------|
| app/lib/crypto.rb | 3 methods | High |
| app/helpers/date_helper.rb | 2 methods | Medium |

### CI Integration
```yaml
# Add to CI pipeline
- name: Docs lint / coverage (YARD)
  run: |
    bundle exec yard doc --fail-on-warning
    bundle exec yard stats --list-undoc

- name: API docs (rswag)
  run: bundle exec rake rswag:specs:swaggerize
```

---

## Checklist During Documentation (Ruby)

## Documentation Checklist

### Before Starting
- [ ] Confirmed format preference (YARD vs RDoc)
- [ ] Identified exclusions (spec/, db/schema.rb, vendor/, generated)
- [ ] Detected API doc approach (rswag vs openapi.yaml vs other)

### Methods
- [ ] All **public** methods documented (especially in services/libs)
- [ ] Parameters described (and types implied via Ruby/YARD tags)
- [ ] Return values documented (including nil/false cases)
- [ ] Exceptions documented (`@raise`), including “soft errors” (nil returns)
- [ ] Side effects documented (DB writes, HTTP calls, enqueue, caching)
- [ ] Examples added for complex behavior / tricky inputs

### Classes / Modules
- [ ] Class/module purpose described
- [ ] Public API documented (what callers should use)
- [ ] Important invariants documented (validation rules, state machines)
- [ ] Thread-safety / reentrancy noted when relevant
- [ ] Configuration / dependencies documented (env vars, injected clients)

### Rails API Endpoints
- [ ] Endpoint summary and auth requirements
- [ ] Params documented (path/query/body) + validation expectations
- [ ] Response schemas documented (success + error)
- [ ] Status codes documented (200/201/204/401/403/404/422/500)
- [ ] Examples added for common requests/responses

### Final Checks
- [ ] Ran docs generator (YARD/RDoc)
- [ ] No stale/inaccurate docs (docs match behavior)
- [ ] Coverage report generated and stored (artifact in CI)
- [ ] OpenAPI renders/validates (if applicable)

---

## Framework-Specific Linting / Coverage (Ruby)

# YARD (docs generation)
bundle add yard --group development
bundle exec yard doc
bundle exec yard stats --list-undoc

# Doc coverage gate (optional, stricter)
bundle add yardstick --group development
bundle exec yardstick --verbose --fail-under 90

# Style linting (not docs, but keeps things sane)
bundle add rubocop --group development
bundle exec rubocop

# Rails API docs via rswag
bundle add rswag --group development,test
bundle exec rails g rswag:install
bundle exec rake rswag:specs:swaggerize

**Opinionated take**: for Ruby, **YARD + yardstick** is the closest equivalent to “doc coverage” tooling. For APIs, **rswag** is the practical sweet spot if you already have request specs; otherwise go **OpenAPI-first** and treat it like a contract.

---

## Quick Reference (Ruby)

|Metric|Good|Acceptable|Poor|
|---   |--- |---       |--- |
|Public method coverage |>90%|70–90%|<70%|
|Class/module coverage	|100%|>90%|<90%|
|API endpoint coverage|100%|100%|<100%|
|Example coverage |>50%|30–50%|<30%|
