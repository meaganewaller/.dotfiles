---
status: accepted
date: 2026-02-26
deciders: [meaganewaller]
---

# 1. Documentation Layer Architecture

## Status

Accepted

## Context

The `home/.claude/` directory has grown to include hooks, cues, skills, governance, agents, and various documentation. Currently, `README.md` serves as both landing page and comprehensive documentation, making it unwieldy. Documentation is scattered across multiple locations with unclear audience boundaries.

Different consumers need different views:
- **New users** need orientation and quick start
- **Contributors** need architecture understanding and extension guides
- **Operators** need troubleshooting and configuration reference
- **Auditors** need policy traceability and governance chain

Content duplication across files leads to drift. When the same concept is explained in multiple places, updates miss some locations.

## Decision

We will restructure documentation into explicit layers with single-source-of-truth content.

### Layer Structure

```
home/.claude/
├── README.md                    # Landing page only (orientation, links)
│
├── docs/                        # Structured documentation
│   ├── architecture/            # ADRs (this directory)
│   │   ├── 0001-*.md
│   │   └── README.md            # ADR index
│   ├── hooks-and-cues/          # Hook system docs
│   │   ├── overview.md          # How hooks/cues work
│   │   ├── writing-hooks.md     # Extension guide
│   │   └── writing-cues.md      # Cue authoring guide
│   ├── skills/                  # Skill system docs
│   │   └── writing-skills.md    # Skill authoring guide
│   └── troubleshooting.md       # Common issues and solutions
│
├── governance/                  # Policy layer (unchanged)
│   ├── policies/*.md            # Human-readable policies
│   └── bin/                     # Governance tooling
│
├── cues/*/cue.md               # Injected context (unchanged)
├── hooks/                       # Hook implementations (unchanged)
└── skills/                      # Skill implementations (unchanged)
```

### Audience Matrix

| Layer | Primary Audience | Content Type |
|-------|------------------|--------------|
| `README.md` | New users | Orientation, quick links |
| `docs/architecture/` | Contributors, future-self | Decisions, rationale |
| `docs/hooks-and-cues/` | Contributors | How-to, extension |
| `docs/troubleshooting.md` | Operators | Problem → solution |
| `governance/policies/` | Auditors, compliance | Policy source |
| `cues/*/cue.md` | Agent (runtime) | Injected directives |

### Content Ownership Rules

1. **Single source of truth**: Each concept lives in exactly one file
2. **Link, don't duplicate**: Other layers reference via relative links
3. **Audience-appropriate depth**: Landing page summarizes, docs elaborate
4. **Implementation stays with code**: Hook/cue behavior docs live near implementations

### Migration Path

1. Extract detailed sections from `README.md` into `docs/` files
2. Replace extracted content with links and brief summaries
3. Update cross-references to point to canonical locations
4. Add audience indicators to each doc file

## Consequences

### Positive

- Clear entry point for new users (README is approachable)
- Reduced duplication and drift
- Explicit audience targeting improves relevance
- ADR location established for future decisions
- Easier to maintain smaller, focused documents

### Negative

- More files to navigate
- Links can break if files move
- Initial migration effort required
- Contributors must learn where content belongs

### Neutral

- Governance and cue locations unchanged (no migration needed there)
- Existing symlink strategy continues to work

## Alternatives Considered

### Alternative A: Keep Everything in README.md

**Pros**: Single file, no navigation needed
**Cons**: Growing unwieldy, mixed audiences, hard to find specific info
**Why rejected**: Doesn't scale; already experiencing pain

### Alternative B: Audience-Based Top-Level Directories

```
home/.claude/
├── for-users/
├── for-contributors/
├── for-operators/
```

**Pros**: Very clear audience targeting
**Cons**: Same content needed by multiple audiences would duplicate; awkward structure
**Why rejected**: Content-based organization with audience metadata is more flexible

### Alternative C: Single docs/ Flat Directory

```
home/.claude/docs/
├── hooks.md
├── cues.md
├── skills.md
├── architecture.md
```

**Pros**: Simple, flat
**Cons**: No room for growth, ADRs don't fit cleanly, mixes reference and decision content
**Why rejected**: Subdirectories provide better organization for growing content
