---
name: template-context
description: This skill should be used when the user asks about "testing Rails generators", "ERB coverage", "template branch coverage", "SimpleCov showing 0%", "untestable template logic", or when building Rails generators with conditional ERB templates. Guides extraction of template conditionals into testable POROs.
argument-hint: template file or generator with conditional logic
---

# TemplateContext Pattern

Extract ERB template conditionals into a testable Plain Old Ruby Object (PORO) to achieve full branch coverage.

## Input

$ARGUMENTS

## When to Apply

**Use this pattern when:**
- Template has 3+ conditional branches (`<% if %>`, `<% unless %>`, ternaries)
- Coverage metrics are a project requirement
- You need to unit test template decision logic in isolation

**Skip this pattern when:**
- Template is purely static or has trivial conditionals (1-2 branches)
- Coverage isn't measured or required
- Prototype/throwaway code

## Problem

ERB templates compile at runtime. Coverage tools like SimpleCov cannot instrument template branches:

```erb
<%# SimpleCov sees NONE of these branches %>
<% if storage_active? %>
  config.active_storage.service = :<%= storage_service %>
<% end %>

<% databases.each do |db| %>
  <% if db[:replica] %>
    replica: true
  <% end %>
<% end %>
```

Result: 0% branch coverage even when all paths are exercised by functional tests.

## Solution

Extract all conditional logic to a **TemplateContext** class:

1. **Decisions live in Ruby** - fully instrumentable
2. **Template becomes declarative** - just calls methods and iterates
3. **Unit tests cover all branches** - fast, isolated

## Implementation Steps

### Step 1: Identify Template Conditionals

Grep your template for decision points:

```bash
grep -E '<%.*if|<%.*unless|<%.*\?' template.erb
```

List each conditional and what it decides.

### Step 2: Create the Context Class

```ruby
# lib/generators/my_generator/template_context.rb
module MyGenerator
  class TemplateContext
    def initialize(config)
      @config = config
    end

    # Predicate for each conditional
    def render_storage_section?
      @config[:storage_enabled] && @config[:storage_service].present?
    end

    # Computed data for iteration
    def active_databases
      @config[:databases].select { |db| db[:enabled] }
    end

    def replica_databases
      active_databases.select { |db| db[:replica] }
    end

    # Simple accessors
    def storage_service
      @config[:storage_service]
    end
  end
end
```

**Naming conventions:**
- Predicates: `render_X?`, `show_X?`, `include_X?`
- Collections: plural nouns (`active_databases`, `enabled_features`)
- Scalars: match config key names

### Step 3: Update the Template

Replace inline conditionals with method calls:

```erb
<%# BEFORE: logic in template %>
<% if @storage_enabled && @storage_service.present? %>

<%# AFTER: logic in context %>
<% if ctx.render_storage_section? %>
```

Pass context to template:

```ruby
# In generator
def create_config
  ctx = TemplateContext.new(options)
  template "config.erb", "config/app.rb", ctx: ctx
end
```

### Step 4: Write Unit Tests

```ruby
# spec/lib/generators/my_generator/template_context_spec.rb
RSpec.describe MyGenerator::TemplateContext do
  describe "#render_storage_section?" do
    context "when storage enabled with service" do
      let(:ctx) { described_class.new(storage_enabled: true, storage_service: :local) }

      it "returns true" do
        expect(ctx.render_storage_section?).to be true
      end
    end

    context "when storage disabled" do
      let(:ctx) { described_class.new(storage_enabled: false, storage_service: :local) }

      it "returns false" do
        expect(ctx.render_storage_section?).to be false
      end
    end

    context "when no storage service" do
      let(:ctx) { described_class.new(storage_enabled: true, storage_service: nil) }

      it "returns false" do
        expect(ctx.render_storage_section?).to be false
      end
    end
  end
end
```

### Step 5: Verify Coverage

Run SimpleCov and confirm branch coverage for the context class:

```bash
bundle exec rspec spec/lib/generators/my_generator/template_context_spec.rb
open coverage/index.html
```

## Output Checklist

After applying this pattern, verify:

- [ ] All template `<% if/unless %>` replaced with `ctx.method?` calls
- [ ] TemplateContext has a spec file
- [ ] SimpleCov shows 100% branch coverage on context class
- [ ] Template only does iteration and method calls (no logic)

## File Structure

```
lib/generators/my_generator/
├── my_generator.rb           # Generator class
├── template_context.rb       # PORO with all decisions
└── templates/
    └── config.erb            # Declarative template

spec/lib/generators/my_generator/
├── my_generator_spec.rb      # Integration tests
└── template_context_spec.rb  # Unit tests for branches
```

## Tradeoffs

| Benefit | Cost |
|---------|------|
| Full branch coverage | Extra file to maintain |
| Isolated unit tests | Indirection (context + template) |
| Faster test feedback | Must discipline: logic in context only |
| Documents config surface | — |

## References

- ADR: `~/.claude/docs/architecture/0007-template-context-pattern.md`
- Related pattern: Presenter (similar extraction for view logic)
- Origin: gusto-database_pull generator coverage problem (2026-03-02)
