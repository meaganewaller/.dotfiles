# Tradeoff: Weekly Reviews Jekyll Site Migration

**Branch:** main
**Files:** weekly-reviews/, home/.claude/skills/common/weekly-review/scripts/*.sh
**Source:** manual-capture

## Decision Summary

Moved the weekly-reviews Jekyll site from a standalone repository (`~/github/meaganewaller/weekly-reviews`) into the dotfiles repository (`~/.dotfiles/weekly-reviews`), consolidating all Dev OS infrastructure into a single repo.

## What Was Chosen

Embed the Jekyll site directly in the dotfiles repo at `weekly-reviews/`, updating all `JEKYLL_ROOT` defaults in the weekly review scripts to reference the new location.

Benefits:
- Single source of truth for all Dev OS infrastructure (hooks, cues, skills, AND the review site)
- Atomic commits across skill scripts and Jekyll templates
- Simplified deployment (one repo to clone/sync)
- Version history stays with the system it documents

## Alternatives Considered

- **Keep as separate repo**: Cleaner separation but requires coordinating changes across repos when skill output format changes
- **Git submodule**: Maintains separate history but adds submodule complexity and sync issues
- **Symlink from dotfiles**: Would keep Jekyll in separate repo but link templates; fragile and confusing

## Trade-offs

- **Larger dotfiles repo** vs **single-repo simplicity**: Acceptable since weekly-reviews is small (~50 files) and directly related to dotfiles functionality
- **Coupled versioning** vs **independent releases**: Actually a benefit since Jekyll templates must match skill output format
- **Longer clone times** vs **immediate availability**: Negligible impact, worth the convenience

## Principles Applied

- Single Source of Truth: Dev OS config and its documentation site now live together
- Simplifying For Change: Template changes and script changes can happen in one commit
- Maintaining Your Tools: The weekly review site IS a tool, not separate documentation

## Revisit If

- Weekly-reviews grows significantly (hundreds of posts, many assets)
- Need to deploy Jekyll site independently of dotfiles changes
- Multiple contributors need to work on Jekyll site without full dotfiles access
