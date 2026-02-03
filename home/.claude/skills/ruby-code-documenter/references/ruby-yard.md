# Ruby Documentation with YARD

YARD is the default documentation standard for Ruby codebases in this project.

## Goals

- Document **public API** clearly and tersely.
- Document **behavior**, **invariants**, **side effects**, and **failure modes**.
- Avoid “commenting the obvious.”

## What to Document

### Always document
- Public classes/modules
- Public methods on services, libraries, jobs, and controllers (public surface)
- Non-obvious logic (edge cases, ordering, idempotency)
- Side effects:
  - database writes
  - HTTP calls
  - background job enqueues
  - cache writes
  - file system changes

### Usually skip
- Trivial readers/writers (`attr_reader`, `attr_accessor`) unless semantics matter
- Methods that mirror the name (e.g., `enabled?` returning boolean) with no nuance
- Private helpers (unless extremely tricky)

## Standard Tags

### `@param`
Use `@param name [Type] description`.

- Prefer standard Ruby types: `String`, `Integer`, `Hash`, `Array<Foo>`.
- For keyword args, document each keyword explicitly.

### `@return`
Use `@return [Type] description`.
- Be explicit about `nil` and `false` cases.

### `@raise`
Use `@raise [ErrorClass] when ...`.

### `@example`
Include runnable-ish examples. If it hits external systems, stub or indicate “pseudo”.

### `@see`
Point to related classes/modules, specs, or docs.

### `@api`
Mark private surfaces clearly:
- `@api private`
- `@api public` (use sparingly; mostly implied)

## Canonical Examples

### Simple method
```ruby
# Generates a stable external identifier for a household.
#
# @param household_id [String] UUID for the household
# @return [String] stable external identifier
# @raise [ArgumentError] if household_id is blank
def external_id_for(household_id)
  raise ArgumentError, "household_id required" if household_id.to_s.empty?
  "hsh_#{household_id.delete("-")}"
end
````

### Method with side effects

```ruby
# Syncs the user to the external CRM.
#
# Side effects:
# - writes `crm_contact_id` to the database
# - performs an HTTP request to CRM
#
# @param user [User] the user to sync
# @return [String] CRM contact id
# @raise [CRM::Error] if CRM request fails
def sync!(user)
  contact_id = crm_client.upsert_contact(user)
  user.update!(crm_contact_id: contact_id)
  contact_id
end
```

### Keyword args + nil/false

```ruby
# Computes the next billing date.
#
# @param start_date [Date] billing start date
# @param interval [Symbol] billing interval (:monthly, :weekly)
# @param anchor_day [Integer, nil] day-of-month anchor; nil uses start_date.day
# @return [Date, nil] next billing date, or nil if interval unsupported
def next_billing_date(start_date:, interval:, anchor_day: nil)
  # ...
end
```

## Types: Be Honest

Ruby is dynamic. Don’t invent types to feel good.

* Prefer concrete types where true.
* Use unions where needed: `[String, nil]`.
* Use duck-typed descriptions where appropriate:

  * `#responds to #call` in prose, or `#call -> Result`

## Documentation Tone

* Use declarative sentences.
* Keep it short.
* If behavior is subtle, write one good example instead of 5 paragraphs.

## Local Commands

* Generate docs: `bundle exec yard doc`
* Stats: `bundle exec yard stats --list-undoc`

````
