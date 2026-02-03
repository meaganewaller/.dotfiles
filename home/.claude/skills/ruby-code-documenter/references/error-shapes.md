# API Error Shapes (Rails)

This project standardizes API error responses so clients can handle failures predictably.

Pick **one** primary error shape for an API surface and stick to it:
- **A. Simple Error Envelope** (recommended for most Rails JSON APIs)
- **B. JSON:API Errors** (required if you claim JSON:API compliance)

Mixing shapes across endpoints is not “flexible,” it’s just rude.

---

## A. Simple Error Envelope (Recommended)

### Top-level structure

```json
{
  "error": {
    "code": "validation_error",
    "message": "Your request was invalid.",
    "details": { "field": ["message"] },
    "request_id": "abc123",
    "meta": { "anything": "optional" }
  }
}
````

### Fields

* `code` (string, required): stable machine-readable identifier
* `message` (string, required): short human-readable summary
* `details` (object/array, optional): structured info for UI/diagnostics
* `request_id` (string, recommended): correlate logs (Rails request id)
* `meta` (object, optional): extra structured info (rate limit reset, etc.)

### Standard Error Codes

Use these **exact codes** unless you have a strong reason:

| Scenario                      | HTTP | `code`             |
| ----------------------------- | ---- | ------------------ |
| Malformed JSON / bad params   | 400  | `bad_request`      |
| Not authenticated             | 401  | `unauthenticated`  |
| Not authorized                | 403  | `forbidden`        |
| Not found                     | 404  | `not_found`        |
| Conflict (uniqueness / state) | 409  | `conflict`         |
| Validation failed             | 422  | `validation_error` |
| Rate limited                  | 429  | `rate_limited`     |
| Upstream dependency failed    | 502  | `upstream_error`   |
| Unexpected server error       | 500  | `internal_error`   |

### 422 Validation Error

Prefer `details` as a map of field => array of messages:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed.",
    "details": {
      "email": ["can't be blank", "is invalid"],
      "name": ["can't be blank"]
    },
    "request_id": "abc123"
  }
}
```

If errors are nested, include dotted paths:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed.",
    "details": {
      "address.line1": ["can't be blank"]
    }
  }
}
```

### 404 Not Found

```json
{
  "error": {
    "code": "not_found",
    "message": "User not found.",
    "request_id": "abc123"
  }
}
```

### 401 Unauthenticated

```json
{
  "error": {
    "code": "unauthenticated",
    "message": "Authentication required."
  }
}
```

### 403 Forbidden

```json
{
  "error": {
    "code": "forbidden",
    "message": "You do not have access to this resource."
  }
}
```

### 409 Conflict (State / Uniqueness)

```json
{
  "error": {
    "code": "conflict",
    "message": "Cannot cancel an already-paid invoice.",
    "details": {
      "state": ["paid"]
    }
  }
}
```

### 429 Rate Limited

Include retry metadata:

```json
{
  "error": {
    "code": "rate_limited",
    "message": "Too many requests.",
    "meta": {
      "retry_after_seconds": 30
    }
  }
}
```

### 500 / Unexpected Errors

Do not leak internals. Include request_id.

```json
{
  "error": {
    "code": "internal_error",
    "message": "Something went wrong.",
    "request_id": "abc123"
  }
}
```

---

## B. JSON:API Errors (If You Claim JSON:API)

### Required shape

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Invalid Attribute",
      "detail": "Email can't be blank",
      "source": { "pointer": "/data/attributes/email" }
    }
  ]
}
```

### Mapping guide

* `status`: HTTP status as string
* `title`: broad category (“Invalid Attribute”)
* `detail`: specific message
* `source.pointer`: JSON pointer to the offending field

### Example: multiple validation errors

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Invalid Attribute",
      "detail": "Email can't be blank",
      "source": { "pointer": "/data/attributes/email" }
    },
    {
      "status": "422",
      "title": "Invalid Attribute",
      "detail": "Name can't be blank",
      "source": { "pointer": "/data/attributes/name" }
    }
  ]
}
```

---

## Recommendations (Opinionated)

* For Rails JSON APIs, use **Simple Error Envelope** unless you truly need JSON:API.
* Keep `code` stable forever. Changing codes breaks clients.
* Use `request_id` everywhere (and log it).
* Document error shapes in OpenAPI with reusable schemas.
