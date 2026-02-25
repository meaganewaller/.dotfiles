---
name: api-conventions
description: This skill should be used when designing APIs, reviewing API interfaces, asking "how should this endpoint work?", "what should this return?", "how do I handle errors?", or when building REST endpoints, GraphQL schemas, service interfaces, or CLI tools. Provides general principles for well-designed APIs.
---

# API Design Conventions

General principles for designing clear, maintainable, and robust APIs across all interface types.

## Core Principles

### 1. Explicit Over Implicit

APIs should do exactly what they say—nothing more, nothing less.

| Principle | Good | Bad |
|-----------|------|-----|
| **No magic defaults** | Require caller to specify behavior | Silently apply "sensible" defaults |
| **No side effects** | `getUser()` only retrieves | `getUser()` also logs analytics |
| **No hidden state** | Pass all needed context | Rely on global/ambient state |
| **No automatic coercion** | Reject invalid types | Silently convert `"123"` to `123` |

### 2. Validate at the Boundary

All input validation happens at the API entry point, not deep in the call stack.

```
┌─────────────────────────────────────────────────────┐
│                    API Boundary                      │
│  ┌───────────────────────────────────────────────┐  │
│  │  1. Parse input (syntax)                      │  │
│  │  2. Validate types (structure)                │  │
│  │  3. Validate business rules (semantics)       │  │
│  │  4. Authorize (permission)                    │  │
│  └───────────────────────────────────────────────┘  │
│                         │                            │
│                         ▼                            │
│              ┌─────────────────────┐                │
│              │  Internal code      │                │
│              │  trusts all input   │                │
│              │  (already validated)│                │
│              └─────────────────────┘                │
└─────────────────────────────────────────────────────┘
```

**Benefits:**
- Errors surface early with clear context
- Internal code stays simple (no defensive checks everywhere)
- Single place to audit validation logic

### 3. Structured Error Responses

Errors are data, not strings. Always return machine-parseable error information.

**Required fields:**
| Field | Purpose |
|-------|---------|
| `code` | Machine-readable identifier (e.g., `VALIDATION_ERROR`, `NOT_FOUND`) |
| `message` | Human-readable description |
| `field` | Which input caused the error (if applicable) |

**Optional fields:**
| Field | Purpose |
|-------|---------|
| `details` | Array of sub-errors for batch validation |
| `hint` | Actionable suggestion for fixing |
| `docs_url` | Link to relevant documentation |

**Example structure:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      {"field": "email", "code": "INVALID_FORMAT", "message": "Must be valid email"},
      {"field": "age", "code": "OUT_OF_RANGE", "message": "Must be between 0 and 150"}
    ]
  }
}
```

### 4. Backwards Compatibility

Never break existing clients.

**Safe changes (additive):**
- Adding new optional fields to responses
- Adding new optional parameters
- Adding new endpoints
- Adding new enum values (if clients handle unknown values)

**Breaking changes (avoid):**
- Removing fields from responses
- Renaming fields
- Changing field types
- Making optional parameters required
- Changing the meaning of existing values

**When breaking changes are unavoidable:**
1. Version the API explicitly (`/v2/users`)
2. Maintain old version for deprecation period
3. Provide migration guide
4. Log usage of deprecated endpoints to track migration

### 5. Consistent Naming

| Convention | Rule | Example |
|------------|------|---------|
| **Resources** | Plural nouns | `/users`, `/orders` |
| **Actions** | Verb prefix for non-CRUD | `/users/123/activate` |
| **Casing** | Pick one, use everywhere | `snake_case` or `camelCase` |
| **Booleans** | Predicate form | `is_active`, `has_children`, `can_edit` |
| **Timestamps** | Suffix with `_at` | `created_at`, `updated_at` |
| **Counts** | Suffix with `_count` | `items_count`, `error_count` |

---

## REST API Conventions

### HTTP Methods

| Method | Purpose | Idempotent | Safe |
|--------|---------|------------|------|
| `GET` | Retrieve resource(s) | Yes | Yes |
| `POST` | Create resource | No | No |
| `PUT` | Replace entire resource | Yes | No |
| `PATCH` | Partial update | Yes | No |
| `DELETE` | Remove resource | Yes | No |

### Status Codes

| Range | Meaning | Common Codes |
|-------|---------|--------------|
| `2xx` | Success | `200 OK`, `201 Created`, `204 No Content` |
| `4xx` | Client error | `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity` |
| `5xx` | Server error | `500 Internal Server Error`, `503 Service Unavailable` |

**Use `422` (not `400`) for validation errors** — the request was syntactically valid but semantically incorrect.

### Pagination

Always paginate list endpoints. Return metadata:

```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 25,
    "total_count": 142,
    "total_pages": 6
  }
}
```

Or use cursor-based for large datasets:

```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTIzfQ==",
    "has_more": true
  }
}
```

---

## GraphQL Conventions

### Schema Design

- **Nullable by default** — only mark fields `!` (non-null) when you're certain they'll always exist
- **Connections for lists** — use Relay-style connections for paginated data
- **Input types for mutations** — wrap mutation arguments in an `input` object
- **Payload types for mutations** — return a dedicated payload type, not the raw entity

### Error Handling

Use the `errors` field for operational errors, not validation:

```graphql
type CreateUserPayload {
  user: User
  errors: [UserError!]!
}

type UserError {
  field: String
  code: String!
  message: String!
}
```

### Naming

| Element | Convention | Example |
|---------|------------|---------|
| Queries | Noun or `get` prefix | `user`, `users`, `getUser` |
| Mutations | Verb + noun | `createUser`, `updateOrder`, `cancelSubscription` |
| Subscriptions | `on` + event | `onUserCreated`, `onOrderUpdated` |

---

## CLI Tool Conventions

### Arguments and Flags

| Element | When to Use | Example |
|---------|-------------|---------|
| **Positional args** | Required primary input | `mytool <filename>` |
| **Flags** | Optional modifiers | `--verbose`, `--output=json` |
| **Short flags** | Common options | `-v`, `-o json` |

### Output Formats

Support multiple output formats:

| Format | Flag | Use Case |
|--------|------|----------|
| Human | (default) | Interactive terminal use |
| JSON | `--json` | Scripting and piping |
| Quiet | `--quiet` | CI/CD, suppress non-errors |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Invalid usage / bad arguments |
| `64-78` | BSD-standard specific errors |

### Help Text

Every command must support `--help` with:
- One-line description
- Usage pattern
- All flags with descriptions
- Examples

---

## Service Interface Conventions

### Method Design

- **Single responsibility** — one method does one thing
- **Verb + noun naming** — `createUser`, `findOrdersByCustomer`
- **Return what was created/modified** — don't make caller re-fetch

### Parameter Objects

For methods with 3+ parameters, use a parameter object:

```ruby
# Bad
def create_user(name, email, role, team_id, send_welcome_email)

# Good
def create_user(params)
  # params: { name:, email:, role:, team_id:, send_welcome_email: }
```

### Fail Fast

Raise/return errors immediately when preconditions aren't met. Don't partially execute then fail.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Instead |
|--------------|---------|---------|
| **God endpoint** | One endpoint does everything based on params | Split into focused endpoints |
| **Stringly typed** | Passing behavior as string flags | Use typed enums or separate methods |
| **Chatty API** | Many calls needed for one operation | Add batch/composite endpoints |
| **Leaky abstraction** | Exposing internal IDs or implementation | Use stable external identifiers |
| **Optimistic naming** | `getUserSafe`, `createUserV2Final` | Version properly or rename cleanly |
