# Tradeoff: 2026-02-27

**Branch:** main (dotfiles)
**Context:** Creating project-specific .claude/ directory for dotfiles repo

## What I chose to do

- Created `.claude/CLAUDE.md` with project context, conventions, common tasks
- Added `dotfiles-dev` cue that fires when working on hooks/cues/skills
- Kept existing `settings.local.json` permissions
- Focused CLAUDE.md on "how to work on this project" not "what this project does"

## What I chose NOT to do

- **Duplicate home/.claude documentation** - CLAUDE.md links to it instead
- **Project-specific hooks** - Not needed; global hooks handle dotfiles work fine
- **Extensive cue library** - One cue for dev guidance is sufficient; avoid over-engineering
- **Automated quality checks in CLAUDE.md** - Listed as checklist; enforcement via existing hooks

## Why

Project CLAUDE.md should reduce friction for future sessions working on dotfiles. It answers "how do I add a hook?" without requiring exploration. The dotfiles-dev cue provides just-in-time reminders without flooding context.

## Revisit if

- Repeated friction points emerge (add to CLAUDE.md or create cue)
- Project-specific permissions needed (update settings.local.json)
- Common mistakes recur (add to checklist or create guard hook)

## Principles Applied

- **Norming On Conventions:** Documents existing patterns for consistency
- **Developing Thought Leadership:** CLAUDE.md teaches future-self and collaborators
- **Simplifying For Change:** Single source of truth; links not duplication
