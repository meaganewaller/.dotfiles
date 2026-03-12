---
title: The TemplateContext Pattern for Testable Rails Generators
date: 2026-03-11
layout: post
tags: [ruby, rails, generators, testing, coverage, patterns]
---

# The TemplateContext Pattern: Getting Real Coverage from ERB Templates

Rails generators are powerful. You write one template, and it produces customized configuration files, initializers, or models based on user input. But there's a problem: the moment you add conditional logic to your ERB templates, your coverage metrics become a lie.

## The Coverage Blind Spot

I discovered this while building a database configuration generator. The template had reasonable complexity—conditionals for replica databases, storage services, environment-specific settings. The functional tests were thorough: I rendered templates with every combination of options and verified the output. Everything worked.

Then I checked SimpleCov: **0% branch coverage** on all template logic.

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

The problem is fundamental: ERB templates compile at runtime. SimpleCov instruments Ruby source files, but by the time your template executes, it's already been transformed into Ruby code that SimpleCov never saw. Your conditionals are invisible.

This isn't a SimpleCov bug. It's how ERB works. And it means every `<% if %>` in your templates is a coverage black hole.

## Why This Matters

"Coverage is just a number" is a common dismissal. But branch coverage serves a specific purpose: it tells you which code paths have never been executed by your test suite. When coverage tools report 0% on template logic, you lose that signal entirely.

You might have comprehensive functional tests that exercise every branch. Or you might have gaps. The metrics can't tell you which. That's the real cost—not the number itself, but the loss of a useful feedback mechanism.

For projects where coverage metrics gate deployment or inform risk assessment, invisible template branches create a systematic blind spot.

## The Pattern: Extract Decisions to a PORO

The solution is straightforward: move all conditional logic out of the template and into a Plain Old Ruby Object that SimpleCov can instrument.

**Before:** Logic lives in ERB

```erb
<% if @storage_enabled && @storage_service.present? %>
  config.active_storage.service = :<%= @storage_service %>
<% end %>

<% @databases.each do |db| %>
  <% if db[:enabled] && db[:replica] %>
    <%= db[:name] %>:
      replica: true
  <% end %>
<% end %>
```

**After:** Logic lives in Ruby, template just renders

```ruby
# lib/generators/my_generator/template_context.rb
module MyGenerator
  class TemplateContext
    def initialize(config)
      @config = config
    end

    def render_storage_section?
      @config[:storage_enabled] && @config[:storage_service].present?
    end

    def storage_service
      @config[:storage_service]
    end

    def replica_databases
      @config[:databases].select { |db| db[:enabled] && db[:replica] }
    end
  end
end
```

```erb
<% if ctx.render_storage_section? %>
  config.active_storage.service = :<%= ctx.storage_service %>
<% end %>

<% ctx.replica_databases.each do |db| %>
  <%= db[:name] %>:
    replica: true
<% end %>
```

The template still has `<% if %>` statements, but they're just calling methods. All the actual decision logic—the boolean expressions, the filtering, the null checks—lives in the context class where SimpleCov can see it.

## Testing the Context

With decisions extracted to a PORO, testing becomes trivial:

```ruby
RSpec.describe MyGenerator::TemplateContext do
  describe "#render_storage_section?" do
    it "returns true when storage enabled with service" do
      ctx = described_class.new(storage_enabled: true, storage_service: :local)
      expect(ctx.render_storage_section?).to be true
    end

    it "returns false when storage disabled" do
      ctx = described_class.new(storage_enabled: false, storage_service: :local)
      expect(ctx.render_storage_section?).to be false
    end

    it "returns false when no storage service" do
      ctx = described_class.new(storage_enabled: true, storage_service: nil)
      expect(ctx.render_storage_section?).to be false
    end
  end

  describe "#replica_databases" do
    it "returns only enabled replicas" do
      databases = [
        { name: "primary", enabled: true, replica: false },
        { name: "replica1", enabled: true, replica: true },
        { name: "replica2", enabled: false, replica: true }
      ]
      ctx = described_class.new(databases: databases)

      expect(ctx.replica_databases.map { |db| db[:name] }).to eq(["replica1"])
    end
  end
end
```

These are fast, isolated unit tests. No template rendering, no file system, no Rails generators machinery. SimpleCov reports accurate branch coverage because it's just Ruby methods.

## Wiring It Together

In your generator, create the context and pass it to the template:

```ruby
class MyGenerator < Rails::Generators::Base
  def create_config
    ctx = TemplateContext.new(
      storage_enabled: options[:storage],
      storage_service: options[:storage_service],
      databases: database_config
    )

    template "config.erb", "config/database.yml", ctx: ctx
  end

  private

  def database_config
    # Build database configuration from options
  end
end
```

The template accesses the context via the local variable:

```erb
<%# ctx is passed as a local %>
<% if ctx.render_storage_section? %>
  ...
<% end %>
```

## File Structure

After applying the pattern, your generator directory looks like this:

```
lib/generators/my_generator/
  my_generator.rb           # Generator class
  template_context.rb       # PORO with all decisions
  templates/
    config.erb              # Declarative template

spec/lib/generators/my_generator/
  my_generator_spec.rb      # Integration tests (render + verify output)
  template_context_spec.rb  # Unit tests (branch coverage)
```

The integration tests verify that templates render correctly. The unit tests verify that decision logic handles all cases. Together, they provide both confidence and coverage.

## When to Use This Pattern

**Apply when:**

- Template has 3+ conditional branches
- Coverage metrics are a project requirement or deployment gate
- Template logic is complex enough that you'd want to unit test it anyway

**Skip when:**

- Template is purely static or has trivial conditionals (1-2 branches)
- Coverage isn't measured or gating anything
- Prototype or throwaway code

The pattern has overhead—an extra file, an extra class, indirection between template and logic. That overhead is worth it when coverage matters or when the logic is complex enough to warrant isolation. It's not worth it for a template with a single `<% if Rails.env.production? %>`.

## The Tradeoffs

| Benefit | Cost |
|---------|------|
| Full branch coverage | Extra file to maintain |
| Fast, isolated unit tests | Indirection (context + template) |
| Template becomes declarative | Discipline required: logic in context only |
| Documents config surface | Mental model includes two files |

The pattern trades simplicity (one file) for testability (two files, one testable). If you're already testing your generators thoroughly and coverage metrics matter, this trade is usually worth making.

## Beyond Generators

The pattern applies anywhere you have ERB with conditional logic:

- **Mailer templates** with conditional sections
- **PDF generators** using ERB for markup
- **Config file generators** (Kubernetes manifests, CI configs)
- **Code generators** (scaffolds, boilerplate)

Anywhere you have `<% if %>` in an ERB file that you want coverage on, the TemplateContext pattern applies.

## Conclusion

ERB templates are a coverage blind spot. SimpleCov can't instrument runtime-compiled code, so your template conditionals report 0% branch coverage regardless of how thoroughly you test them.

The TemplateContext pattern solves this by extracting decisions to a PORO:

1. **Decisions live in Ruby** - fully instrumentable by coverage tools
2. **Template becomes declarative** - just method calls and iteration
3. **Unit tests cover all branches** - fast, isolated, measurable

The pattern adds a file and some indirection. In exchange, you get accurate coverage metrics and cleaner separation between "what to render" and "how to render it."

For generators with meaningful conditional logic, that's a trade worth making.

---

*The full pattern implementation is documented in my [dotfiles repository](https://github.com/meaganewaller/.dotfiles) as a Claude Code skill at `home/.claude/skills/common/template-context/SKILL.md`.*
