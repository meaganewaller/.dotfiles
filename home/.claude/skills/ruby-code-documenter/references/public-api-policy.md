# Public API Policy (Ruby / Rails)

This policy defines what counts as **public API** for documentation coverage, stability guarantees, and review standards.

If “public” is undefined, your docs coverage becomes a guilt economy.

---

## Goals

- Define what we *promise* to keep stable
- Focus documentation effort where it matters
- Prevent internal refactors from becoming breaking changes
- Make coverage metrics meaningful

---

## Definitions

### Public API (Must Document, Must Keep Stable)

Public API is any interface intended to be called by:
- external clients (mobile/web/partners)
- other services
- other teams
- other domains inside the app that are not tightly coupled

Public API must:
- be documented
- have tests
- have stable semantics
- have a deprecation path for changes

### Internal API (Document Only If Sharp)

Internal API is code used only within a local area of the codebase,
where refactors are expected and callers can be updated together.

Internal API should:
- avoid over-documentation
- be kept readable instead
- be documented only when tricky

### Private Helpers (Do Not Document)

Private helpers are implementation details:
- private methods
- tiny one-liners
- glue code local to a class

Document only if:
- behavior is surprising, or
- failure modes are easy to trigger

---

## Rails: What Counts as Public API

### 1) HTTP Endpoints (Always Public)
- Any controller action reachable via routes
- Any internal API endpoint used by frontends/services
- Must be documented (OpenAPI/rswag + short inline comment when helpful)
- Must include auth, params, status codes, and error shapes

### 2) Serializers / Response Schemas (Public When Exposed)
Public if their output is consumed by:
- browsers/mobile clients
- partner integrations
- external services

Document:
- computed fields
- privacy rules
- relationship inclusion strategy
- breaking changes policy (versioning)

### 3) Service Objects (Public When Cross-Domain or Widely Used)
Public if:
- called from multiple controllers or background jobs
- used by multiple domains/features
- used by external integration pipelines
- considered “the official way” to perform an operation

Examples:
- `app/services/payments/*`
- `app/services/households/*`
- any service referenced by multiple top-level entry points

Must document:
- inputs/outputs
- side effects
- failure modes
- idempotency and retries
- required permissions / scoping assumptions

### 4) Jobs / Workers (Public When Enqueued Widely)
Public if:
- enqueued from multiple places
- part of a stable workflow (billing, sync, exports)
- interacts with external systems

Must document:
- idempotency
- retries/backoff assumptions
- rate limits / external constraints
- expected record state and locks

### 5) Libraries in `app/lib` (Usually Public)
Assume public unless explicitly marked otherwise.

Use:
- `@api private` for internal-only libs
- place internal libs under `app/lib/internal/` if you want extra clarity

### 6) Models (Public-ish, But Not Always)
Models are often “domain core” but not necessarily public API.

Document models when:
- they encode important business rules or invariants
- validations/callbacks are meaningful and non-obvious
- they’re used as a contract boundary (e.g., shared with external integrations)

Avoid documenting:
- pure persistence models with no behavior beyond basic validations

---

## Gems / Libraries: What Counts as Public API

Public API includes:
- the documented module/class surface
- anything in the gem’s README
- anything in `lib/<gem_name>.rb` requiring and exposing entry points

Guidelines:
- If it’s in the README, it’s public forever (or until deprecation).
- Prefer a single stable entry point module and keep internals behind it.

---

## Explicit Markers

Use these conventions to avoid ambiguity:

### YARD
- `@api public` (optional)
- `@api private` (recommended for internal-only surfaces)

### Directory structure
- `app/lib/internal/` = internal utilities
- `app/services/internal/` = internal services

### Method naming
- `call` / `call!` is part of public service contract
- `!` indicates “raises on failure” (document what it raises)

---

## Documentation Coverage Rules

Count towards coverage:
- controllers (public endpoints)
- public service objects
- public jobs
- public libs
- public serializers

Do NOT count:
- specs
- generated files
- trivial accessors
- obvious private helpers

---

## Deprecation Policy (Short Version)

Breaking changes to public API require:
- versioning (API v2) **or**
- explicit deprecation window (warn, dual support, remove)

Documentation must include:
- deprecation notice
- removal timeline
- migration steps

---

## Quick Decision Checklist

Ask:
1. Is this callable by something outside this file/class?
2. Is it used in more than one feature/domain?
3. Would changing it break a client or workflow?
4. Is it a stable “official path” to do a thing?

If yes → it’s public. Document it.
