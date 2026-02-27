# Architecture Decision Records

> **Audience**: Contributors, future-self understanding past decisions

This directory contains Architecture Decision Records (ADRs) for the Claude Code configuration system.

## What is an ADR?

An ADR captures a significant technical decision along with its context and consequences. They provide institutional memory for "why did we do it this way?"

## Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-documentation-layer-architecture.md) | Documentation Layer Architecture | Accepted | 2026-02-26 |

## Status Definitions

- **Proposed** - Under discussion, not yet decided
- **Accepted** - Decision made, should be followed
- **Deprecated** - No longer recommended
- **Superseded** - Replaced by a newer ADR

## Creating a New ADR

When working with Claude Code, mention "ADR" or "architecture decision" in your prompt to trigger the [ADR cue](../../cues/adr/cue.md), which provides:

- Format template with YAML frontmatter
- When to write (and skip) ADRs
- Status workflow guidance
- Best practices

ADRs use sequential numbering: `NNNN-short-kebab-title.md`
