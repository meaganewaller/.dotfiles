# Rails Documentation Guidelines

This project uses Rails conventions and documents around:
- Models (domain rules)
- Controllers (API behavior)
- Services/Jobs (business workflows)
- Serializers (response schema)

## Rails “Public API” Definition

### Consider public:
- Controllers and endpoints
- Service objects in app/services used across domains
- Library code in app/lib used broadly
- Jobs invoked by multiple features
- Serializers used for external APIs

### Consider internal:
- Concerns used only inside one model/controller
- Private methods, callbacks helpers, internal query objects
- Test helpers

Document public surfaces fully; document internal only when “sharp.”

## Models

Document:
- Purpose and responsibility
- Key invariants (validation rules)
- State transitions / status meaning
- Non-obvious callbacks and their side effects
- Associations only if semantics matter (not boilerplate)

Example:
```ruby
# Represents a household membership with role-based access.
#
# Invariants:
# - role must be one of ROLES
# - revoked memberships are not considered active
#
# @see Household
class HouseholdMembership < ApplicationRecord
  # ...
end
````

### Callback rule

If a callback has side effects, it must be documented near the callback.
If the callback is “pure normalization,” keep it minimal.

## Controllers

Document per endpoint:

* What it does (business purpose)
* Auth requirements (who can call)
* Params (path/query/body) and validation expectations
* Response shape (serializer)
* Status codes and error cases

Keep controller docs short. Push detail into OpenAPI/rswag docs when used.

## Services

Service docs must include:

* Inputs
* Outputs
* Side effects
* Failure modes
* Idempotency and retries if relevant

Prefer a standard interface:

* `call` (non-bang) returns Result-ish object
* `call!` raises on failure

If your code doesn’t use that, still document what the method *actually* does.

## Jobs

Jobs must document:

* Expected idempotency
* Retry behavior assumptions
* External calls and rate limiting constraints
* Required records/permissions

## Serializers

Document:

* Attributes that are non-obvious or computed
* Relationships and inclusion strategy
* Any privacy/security constraints (fields excluded for certain roles)

## Don’t Do This

* Don’t narrate Rails boilerplate.
* Don’t document what a line of code already says.
* Don’t duplicate OpenAPI text verbatim into controller comments if rswag exists.
