---
status: accepted
date: 2026-03-05
deciders: [meaganewaller]
context: gusto-database_pull
---

# 7. TemplateContext Pattern for Testable ERB Templates

## Status

Accepted

## Context

Rails generators often use ERB templates with conditional logic to produce different output based on configuration. When testing these generators, SimpleCov (and most Ruby coverage tools) cannot instrument ERB template branches because ERB is compiled at runtime, not parsed as Ruby source.

This creates a coverage gap: functional tests that render templates and verify output work correctly, but branch coverage reports show 0% for the conditional paths within templates—even when all branches are exercised.

Example problematic pattern:

```erb
<% if storage_active? %>
  config.active_storage.service = :<%= storage_service %>
<% end %>

<% databases.each do |db| %>
  <% if db[:replica] %>
    replica: true
  <% end %>
<% end %>
```

The conditionals `storage_active?`, `db[:replica]`, etc. are invisible to coverage tools.

## Decision

We will extract all ERB template conditional logic into a **TemplateContext PORO** (Plain Old Ruby Object) that:

1. Encapsulates all decision-making in pure Ruby methods
2. Receives configuration as constructor arguments
3. Exposes predicate methods and data accessors for the template
4. Keeps templates as simple iteration and method calls

### Pattern Structure

```ruby
# lib/generators/my_generator/template_context.rb
class MyGenerator::TemplateContext
  def initialize(config)
    @config = config
  end

  # Predicate methods for conditionals
  def render_storage_active?
    @config[:storage_enabled] && @config[:storage_service].present?
  end

  # Data accessors for iteration
  def active_databases
    @config[:databases].select { |db| db[:enabled] }
  end

  def replica_databases
    active_databases.select { |db| db[:replica] }
  end
end
```

```erb
<%# Template becomes declarative %>
<% if ctx.render_storage_active? %>
  config.active_storage.service = :<%= ctx.storage_service %>
<% end %>

<% ctx.active_databases.each do |db| %>
  ...
<% end %>
```

### Testing the Context

```ruby
RSpec.describe MyGenerator::TemplateContext do
  describe "#render_storage_active?" do
    it "returns true when storage enabled with service" do
      ctx = described_class.new(storage_enabled: true, storage_service: :local)
      expect(ctx.render_storage_active?).to be true
    end

    it "returns false when storage disabled" do
      ctx = described_class.new(storage_enabled: false, storage_service: :local)
      expect(ctx.render_storage_active?).to be false
    end
  end
end
```

SimpleCov now instruments every branch because decisions are Ruby methods.

## Consequences

### Positive

- Full branch coverage of all template decision logic
- Clear separation of concerns: context decides, template renders
- Easier to test edge cases (no need to render full templates)
- Template becomes easier to read (declarative, not procedural)
- Context class documents the template's configuration surface

### Negative

- Additional file and class to maintain
- Indirection: must look at context to understand template behavior
- Requires discipline to keep logic in context, not template

### Neutral

- Pattern applies to any templating system (ERB, Haml, Slim)
- Context can be nested class or standalone—prefer standalone for test isolation

## When to Apply

**Use this pattern when:**
- Template has 3+ conditional branches
- Coverage metrics are a project requirement
- Template logic is complex enough to warrant unit testing

**Skip this pattern when:**
- Template is purely static or has trivial conditionals
- Coverage isn't measured or required
- Template is throwaway/prototype code

## Alternatives Considered

### Alternative A: Test ERB Directly with Output Assertions

Render templates with various inputs and assert on output strings.

**Pros:** No additional abstraction; tests what users see
**Cons:** SimpleCov shows 0% branch coverage; tests are brittle to formatting changes
**Why rejected:** Coverage metrics are a project requirement; direct testing still valuable as integration test

### Alternative B: Nested Class Inside Generator

Define `TemplateContext` as a nested class within the generator.

**Pros:** Keeps related code together; single file
**Cons:** Requires Rails generators to be loaded when requiring the file, breaking isolated spec loading
**Why rejected:** Isolated specs are faster and more reliable

### Alternative C: Helper Module Mixed Into Generator

Extract methods to a module included by the generator.

**Pros:** Methods available in generator context without explicit passing
**Cons:** Still not easily testable in isolation; tight coupling
**Why rejected:** PORO is more testable and explicit about dependencies

## References

- Origin: gusto-database_pull generator coverage problem (2026-03-02)
- Related: Rails generator testing patterns
- See also: Presenter pattern (similar extraction for view logic)
- **Skill:** `~/.claude/skills/template-context/SKILL.md` - implementation guide
