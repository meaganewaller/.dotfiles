## `references/api-docs-rails.md`

```markdown
# Rails API Documentation (REST / JSON)

This project documents APIs using either:
- rswag (spec-driven OpenAPI generation), or
- OpenAPI-first (contract file checked into repo)

Choose ONE strategy per API surface.

## What Every Endpoint Must Document

- Summary / purpose
- Authentication and authorization
- Params:
  - path params
  - query params
  - request body
- Responses:
  - success response shape
  - error response shape(s)
- Status codes:
  - 200/201/204 (success)
  - 400/401/403/404/409/422 (client errors)
  - 429 (rate limits) if applicable
  - 500 (unexpected)

## Error Shape Conventions

Pick a stable structure and stick to it. Example:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Name is required",
    "details": {
      "name": ["can't be blank"]
    }
  }
}
````

Or for JSON:API:

* top-level `errors: [{ status, title, detail, source }]`

Document whichever you actually use.

## Auth

Document:

* auth mechanism (session, JWT, API key, OAuth)
* required scopes/roles
* behavior when missing/invalid
* whether endpoints are accessible cross-household / cross-tenant (usually “no”)

## Pagination

If you paginate, document:

* params (`page`, `per_page`, `cursor`)
* response metadata shape (total, next_cursor, etc.)
* maximum page sizes enforced

## Filtering & Sorting

Document:

* filter params supported
* allowed sort fields and defaults
* whether filtering is AND/OR semantics

## Versioning

If you use `/api/v1`, document:

* how breaking changes are handled
* what “v1” guarantees

## Examples

Examples should reflect real payloads:

* include required fields
* include representative optional fields
* include error responses for common failures (422, 404)

Avoid “toy” examples that never match production.
