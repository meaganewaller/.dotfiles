# Decision: Extract Template Logic into TemplateContext PORO

**Date:** 2026-03-02
**Status:** Accepted
**Context:** gusto-database_pull

## Summary

Extracted all ERB template conditional logic into a `TemplateContext` PORO class to achieve full SimpleCov branch coverage and improve separation of concerns.

## Options Considered

### 1. Continue Testing ERB Directly (Rejected)
- Keep existing tests that render ERB with instance variables
- SimpleCov cannot instrument ERB template branches

**Rejected because:** Branch coverage showed 0% even with functional tests. Coverage metrics are a project requirement.

### 2. Extract to TemplateContext PORO (Chosen)
- Move all conditionals to Ruby methods (`render_storage_active?`, `active_databases`, etc.)
- Template becomes simple iteration and method calls
- Full SimpleCov coverage of all decision logic

**Chosen because:** Ruby code is fully instrumentable. Separation of concerns improves maintainability.

### 3. Nested Class Inside InstallGenerator (Rejected)
- Define `TemplateContext` inside `InstallGenerator < Rails::Generators::Base`
- Keeps related code together

**Rejected because:** Requires Rails::Generators to be loaded when requiring the file, breaking isolated spec loading.

## Tradeoffs

| Aspect | Benefit | Cost |
|--------|---------|------|
| Standalone namespace | Can require without Rails::Generators | Module path doesn't match file path |
| 10-parameter constructor | Explicit, typed with Sorbet | Rubocop `ParameterLists` disabled |
| Query method duplication | Clear intent (`configure_storage?` vs `render_storage_active?`) | Slight redundancy |
| Spec file location | Follows generator directory convention | Rubocop `SpecFilePathFormat` disabled |

## Principles Applied

- **Simplifying For Change** - Logic in Ruby is easier to modify than embedded ERB
- **Making Principled Choices** - Coverage requirement drove architecture decision
- **Norming On Conventions** - Followed existing PORO patterns (like `WhereClauseContext`)

## Implementation

Files created:
- `lib/generators/gusto/database_pull/install/template_context.rb` (~20 methods)
- `spec/generators/gusto/database_pull/template_context_spec.rb` (95 test cases)

Files modified:
- `install_generator.rb` - builds `@context` in `create_initializer`
- `database_pull.rb.erb` - uses `@context.method_name` instead of direct conditionals
- `install_generator_spec.rb` - added `build_context` helper
- `railtie_spec.rb` - uses `TemplateContext` for template rendering

## Revisit If

- Template grows significantly more complex (consider splitting into multiple context objects)
- Other generators need similar logic extraction (extract a shared pattern/base class)
- Sorbet strict typing causes issues with the 10-parameter constructor (consider a builder or config struct)
- Coverage requirements change (may no longer need this indirection)

## Reversal Cost

**Medium** - Would require reverting template to use direct instance variables and updating all specs that render templates. Logic would need to move back to generator or template.
