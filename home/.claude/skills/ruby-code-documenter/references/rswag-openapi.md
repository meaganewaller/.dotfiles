## `references/rswag-openapi.md`

```markdown
# rswag + OpenAPI (Rails)

rswag generates OpenAPI/Swagger docs from request specs.

## When to Use rswag

Use rswag when:
- request specs exist or are feasible
- you want docs that track behavior (less drift)
- you’re fine with OpenAPI generation being part of test runs

Use OpenAPI-first when:
- you need a strict contract for multiple clients/SDK generation
- you want reviewable diffs without running specs

## Recommended Setup

- Swagger UI endpoint: `/api-docs`
- Spec output: `swagger/v1/swagger.yaml` (or `.json`)
- Store schemas in one place to avoid duplication.

## Spec Authoring Principles

- One `path` entry per controller action / route
- Reuse schemas via `$ref` where possible
- Document:
  - auth
  - request body
  - success schema
  - error schema(s)

## Example rswag spec skeleton

```ruby
require "swagger_helper"

RSpec.describe "Users API", type: :request do
  path "/api/v1/users/{id}" do
    get "Fetch a user" do
      tags "Users"
      produces "application/json"
      security [bearerAuth: []]

      parameter name: :id, in: :path, type: :string, description: "User ID"

      response "200", "user found" do
        schema "$ref" => "#/components/schemas/User"
        run_test!
      end

      response "404", "not found" do
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
````

## Common Pitfalls

* Specs that don’t assert response bodies → docs lie.
* Inline schemas everywhere → docs become unmaintainable.
* Not documenting 401/403/422 → your clients suffer.

## CI Advice

Run:

* `rspec` (or a subset) + `rake rswag:specs:swaggerize`
* validate generated OpenAPI (optional but recommended)

If OpenAPI is published, treat changes as breaking unless versioned.
