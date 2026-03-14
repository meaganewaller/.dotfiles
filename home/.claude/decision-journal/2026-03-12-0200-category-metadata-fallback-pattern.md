# Tradeoff: Category Metadata Fallback Pattern

**Branch:** main
**Files:** `_includes/menus/menu-nav.html`, `_layouts/archive.html`, `_data/meta.yml`
**Source:** auto-capture

## Decision Summary

Implemented a three-tier fallback system for category metadata that uses a centralized YAML data file with graceful degradation to derived display names, avoiding the need for custom Jekyll plugins while maintaining backward compatibility with categories that lack explicit metadata.

## What Was Chosen

- Category metadata stored in `_data/meta.yml` with optional `label` and `description` fields
- Templates check `site.data.meta[category]` and guard with `{% if meta %}` conditionals
- Fallback to slugified category name (replace dashes with spaces) when metadata is unavailable
- Navigation menu sorts categories by post count (descending) using a clever Liquid hack: zero-padded count + pipe delimiter, then extract top 3
- Archive layout uses `meta.label` for heading, `meta.description` for description, or auto-generates "N posts in category-name"

## Alternatives Considered

1. **Custom Jekyll Plugin**: Could handle sorting, metadata enrichment in Ruby, and provide native data access
   - Pros: More powerful, cleaner template code, easier to extend
   - Cons: Requires plugin setup/maintenance, adds Ruby dependency, slower build time, less portable

2. **Frontmatter Metadata**: Store metadata in each category's frontmatter or _config.yml categories array
   - Pros: Co-located with category definition, no separate data file
   - Cons: Harder to manage at scale, mixing concerns, jekyll-archives plugin may not expose this cleanly

3. **All-or-nothing Metadata**: Require metadata for all categories, no fallback
   - Pros: Simpler template logic, explicit structure
   - Cons: Breaks when new categories added without metadata, requires discipline

## Trade-offs

- **Simplicity vs Expressiveness**: The Liquid sorting trick (zero-padded count + delimiter) is non-obvious. Alternative was delegating to plugin (more expressive but adds complexity).
- **Template Complexity vs Plugin Maintenance**: Template code is slightly verbose with multiple conditionals, but avoids maintaining a custom plugin.
- **Centralized Data vs Distributed Config**: Centralizing in `_data/meta.yml` makes metadata changes easier to track in version control but adds a single source of truth that must be kept in sync.
- **Build Time vs Flexibility**: All sorting happens at build time (fast rendering), but changing category order requires rebuild.

## Principles Applied

- **Fail Gracefully**: Categories without metadata still display with auto-generated labels/descriptions
- **No Custom Code When Possible**: Use templating capabilities rather than custom plugins (lower maintenance burden)
- **Explicit Configuration**: Metadata in separate data file makes configuration intent clear
- **Separation of Concerns**: Display logic (labels, descriptions) separated from post organization (categories)

## Revisit If

- Navigation becomes larger than 3 categories and sorting rules change frequently
- New metadata fields (icons, colors, etc.) are needed for categories
- Performance becomes an issue with many categories (though Jekyll build time is unlikely bottleneck)
- Team needs to add categories frequently without touching templates
