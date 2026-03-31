---
pattern: api|endpoint|route|controller|breaking.?change|deprecat|versio
files:
  - controllers?/
  - routes?\.
  - api/
  - endpoints?/
  - graphql/
  - schema\.
  - openapi
  - swagger
commands: curl|http|swagger|openapi
scope: agent, subagent
description: API design, versioning, and breaking change management
vocabulary: api endpoint route controller breaking deprecate version schema response request
provenance:
  policy:
    - uri: home/.claude/governance/policies/api-standards.md
      type: governance-doc
  controls:
    - id: ENG-API-001
      name: Naming Conventions
      justifications:
        - Consistent naming across endpoints
        - RESTful resource naming when applicable
    - id: ENG-API-002
      name: Version Management
      justifications:
        - Breaking changes require version bump
        - Clear migration path documented
    - id: ENG-API-003
      name: Breaking Change Protocol
      justifications:
        - Deprecation warnings before removal
        - Sunset period for breaking changes
    - id: ENG-API-005
      name: Error Schema Standards
      justifications:
        - Consistent error response format
        - Actionable error messages
  verified: 2026-03-31
  rationale: >
    APIs are contracts with consumers. Breaking changes without proper
    versioning and migration paths cause integration failures and erode
    trust. Consistent design reduces learning curve.
---

# API Design Cue

## Breaking Change Checklist

Before making breaking changes:

```
[ ] Is this truly necessary, or can it be additive?
[ ] Version bumped appropriately?
[ ] Deprecation warning added to old endpoint/field?
[ ] Migration guide documented?
[ ] Consumers notified (if external)?
```

## Design Principles

- **Nouns for resources**: `/users`, `/orders` not `/getUsers`
- **HTTP verbs for actions**: GET read, POST create, PUT/PATCH update, DELETE remove
- **Consistent casing**: Pick one (snake_case, camelCase) and stick with it
- **Meaningful status codes**: 201 for created, 404 for not found, 422 for validation errors

## Breaking vs Non-Breaking

**Breaking (requires version bump):**
- Removing endpoints or fields
- Changing field types
- Renaming without alias
- Changing authentication requirements

**Non-Breaking (safe to add):**
- New optional fields
- New endpoints
- New optional parameters
- Expanded enum values (if consumers handle unknown)

## Error Response Pattern

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Human readable description",
    "details": [
      {"field": "email", "message": "must be valid email format"}
    ]
  }
}
```
