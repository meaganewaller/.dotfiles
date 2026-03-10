---
# Triggers when discussing architecture decisions, design patterns, or trade-offs
pattern: (^|[^a-zA-Z])adr([^a-zA-Z]|$)|architect|decision|design.?pattern|technical.?choice|trade.?off
files: docs/architecture/.*\.md|adr/.*\.md|decisions?/.*\.md
scope: agent, subagent
macro: prepend
description: Architecture Decision Records (ADRs) for documenting technical choices and their rationale
vocabulary: adr decision architecture tradeoff trade-off design rationale alternatives considered rejected
provenance:
  policy:
    - uri: home/.claude/governance/policies/architecture-decisions.md
      type: governance-doc
  controls:
    - id: ENG-ADR-001
      name: Documented Decision Rationale
      framework_ref: NIST SP 800-53 SA-8
      justifications:
        - ADRs capture the "why" behind technical choices
        - Future developers can understand context without archaeology
    - id: ENG-ADR-002
      name: Alternatives Consideration
      justifications:
        - Documenting rejected alternatives prevents re-litigation
        - Shows due diligence in decision-making process
    - id: ENG-ADR-003
      name: Change History
      framework_ref: ISO 27001 A.12.1.2
      justifications:
        - ADR status transitions create audit trail
        - Superseded decisions point to replacements
  verified: 2026-02-26
  rationale: >
    Architecture Decision Records provide institutional memory for technical
    choices. They reduce decision fatigue by preventing re-litigation of
    settled questions and enable new team members to understand system context.
---

# Architecture Decision Records

Architecture Decision Records (ADRs) capture significant technical decisions with context, alternatives, and rationale.

## When to Write an ADR

Write an ADR when making decisions that:
- Are **hard to reverse** (database choice, API contract, framework selection)
- **Cross team boundaries** (affects multiple services or teams)
- Have **multiple viable alternatives** (the decision isn't obvious)
- Will be **questioned later** ("why did we do it this way?")

Skip ADRs for:
- Obvious choices with one clear option
- Easily reversible decisions
- Implementation details that don't affect architecture

## Tooling

```bash
# Create new ADR (if adr-tools installed)
adr new "Use PostgreSQL for user data"

# List existing ADRs
ls docs/architecture/decisions/ 2>/dev/null || ls adr/ 2>/dev/null

# Link related ADRs
adr link 5 Supersedes 3
```

## Directory Structure

```
docs/architecture/decisions/   # Preferred location
├── 0001-record-architecture-decisions.md
├── 0002-use-postgresql.md
├── 0003-adopt-graphql.md
└── README.md                  # Index with status summary
```

Alternative locations: `adr/`, `docs/adr/`, `decisions/`

## ADR Format

```markdown
---
status: proposed | accepted | deprecated | superseded
date: YYYY-MM-DD
deciders: [names or teams]
consulted: [stakeholders asked for input]
informed: [stakeholders who need to know]
supersedes: [ADR-NNNN if replacing]
superseded_by: [ADR-NNNN if replaced]
---

# N. Title (short imperative phrase)

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR-NNNN](link)

## Context

What is the issue that we're seeing that is motivating this decision or change?
What forces are at play (technical, business, organizational)?

## Decision

What is the change that we're proposing and/or doing?
State in full sentences, with active voice: "We will..."

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- Benefit 1
- Benefit 2

### Negative
- Drawback 1 (and mitigation if any)

### Neutral
- Side effect that is neither good nor bad

## Alternatives Considered

### Alternative A
- Pros
- Cons
- Why rejected

### Alternative B
- Pros
- Cons
- Why rejected
```

## Status Workflow

```
proposed → accepted → [deprecated | superseded]
    ↓
 rejected
```

- **Proposed**: Under discussion, not yet decided
- **Accepted**: Decision made, should be followed
- **Deprecated**: No longer recommended, but not replaced
- **Superseded**: Replaced by a newer ADR (link to it)
- **Rejected**: Considered but not adopted (still valuable to record)

## Best Practices

- **Number sequentially** (0001, 0002...) for chronological order
- **Keep titles short** and action-oriented ("Use X for Y")
- **Write for future readers** who lack your current context
- **Update status**, don't delete - history is valuable
- **Link related ADRs** (supersedes, relates-to, depends-on)
- **Include rejection reasons** in alternatives - this is often the most valuable part
