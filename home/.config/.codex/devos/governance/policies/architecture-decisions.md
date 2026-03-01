# Architecture Decision Policy

This policy governs the documentation and management of significant technical decisions.

## Purpose

Architecture Decision Records (ADRs) provide institutional memory for technical choices. They:

- Capture the **context and rationale** at decision time
- Document **alternatives considered** and why they were rejected
- Create an **audit trail** of how systems evolved
- Enable **onboarding** without requiring tribal knowledge

## Scope

This policy applies to decisions that:

1. **Are difficult to reverse** - database selections, API contracts, framework choices
2. **Cross organizational boundaries** - affect multiple teams or services
3. **Have significant cost implications** - time, money, or technical debt
4. **Establish precedent** - will guide future similar decisions

## Requirements

### ENG-ADR-001: Documented Decision Rationale

All significant technical decisions must be documented with:

- **Context**: The forces and constraints that shaped the decision
- **Decision**: The choice made, stated clearly
- **Consequences**: Expected positive and negative outcomes

**Rationale**: Future developers need to understand not just *what* was decided, but *why*. This prevents re-litigation of settled questions and helps identify when circumstances have changed enough to warrant revisiting a decision.

### ENG-ADR-002: Alternatives Consideration

Each ADR must document alternatives that were seriously considered:

- At least two alternatives for non-trivial decisions
- Pros and cons for each alternative
- Clear reasoning for why alternatives were rejected

**Rationale**: The rejected alternatives are often the most valuable part of an ADR. They prevent teams from repeatedly proposing the same solutions and demonstrate due diligence in the decision-making process.

### ENG-ADR-003: Change History

ADRs must maintain accurate status and linkage:

- Status must reflect current state (proposed, accepted, deprecated, superseded)
- Superseded ADRs must link to their replacement
- ADRs should not be deleted, only deprecated or superseded

**Rationale**: The evolution of decisions tells a story. Understanding why a previous decision was superseded helps evaluate whether the new decision is appropriate or whether circumstances might warrant a third approach.

## Implementation

### Standard Location

ADRs should be stored in version control alongside the code they govern:

```
docs/architecture/decisions/
├── 0001-record-architecture-decisions.md
├── 0002-use-postgresql-for-user-data.md
└── README.md
```

### Naming Convention

- Sequential numbering: `NNNN-short-title.md`
- Titles should be short, imperative phrases
- Numbers provide chronological ordering

### Review Process

1. ADRs start in `proposed` status
2. Relevant stakeholders are consulted
3. Decision is made (accept or reject)
4. Status is updated; ADR is committed

## Exceptions

ADRs are not required for:

- Obvious choices with single viable options
- Easily reversible implementation details
- Decisions with no lasting architectural impact

## References

- [NIST SP 800-53 SA-8](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final) - Security Engineering Principles
- [ISO 27001 A.12.1.2](https://www.iso.org/standard/27001) - Change Management
- [Michael Nygard's original ADR proposal](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
