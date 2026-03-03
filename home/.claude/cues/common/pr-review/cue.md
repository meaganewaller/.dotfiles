---
pattern: \bpr\b|pull.?request|code.?review|review|merge|approve|request.?changes
commands: gh pr|git push|git merge
files: \.github/pull_request_template\.md|\.github/PULL_REQUEST_TEMPLATE/.*
scope: agent, subagent
description: Pull request and code review best practices
vocabulary: review pr merge approve changes feedback diff comments
provenance:
  policy:
    - uri: home/.claude/governance/policies/code-lifecycle.md
      type: governance-doc
  controls:
    - id: ENG-PR-001
      name: Meaningful PR Descriptions
      justifications:
        - Reviewers need context to provide good feedback
        - Future archaeologists need to understand why changes were made
    - id: ENG-PR-002
      name: Focused Review Scope
      justifications:
        - Large PRs get superficial reviews
        - Small PRs get merged faster with better feedback
  verified: 2026-03-03
  rationale: Structured PR practices improve review quality and knowledge transfer
---

# Pull Request Guidelines

## Creating PRs

### Title
- Use conventional commit format: `type(scope): description`
- Keep under 72 characters
- Be specific: "Fix auth timeout" not "Fix bug"

### Description
Include:
- **What**: Summary of changes (1-3 bullets)
- **Why**: Context and motivation
- **How**: Approach taken (if non-obvious)
- **Test plan**: How to verify the change

### Size
- Aim for <400 lines changed
- Split large changes into stacked PRs
- One logical change per PR

## Reviewing PRs

### Before Reviewing
- [ ] Read the PR description fully
- [ ] Understand the context/ticket
- [ ] Check CI status

### Review Focus Areas

**Correctness**
- Does the code do what it claims?
- Are edge cases handled?
- Are there obvious bugs?

**Design**
- Does it fit the existing architecture?
- Is the abstraction level appropriate?
- Are there simpler alternatives?

**Maintainability**
- Is it easy to understand?
- Will it be easy to modify?
- Are there tests for key paths?

**Security**
- Input validation present?
- No secrets in code?
- Authorization checked?

### Feedback Style
- Be specific: "Line 42: this loop could be O(n^2)" not "slow"
- Distinguish blocking vs suggestions: prefix with "nit:" or "suggestion:"
- Ask questions: "What happens if X is null?"
- Praise good work: "Nice refactor of the auth flow"

### Approval Criteria
- [ ] Code is correct and handles edge cases
- [ ] Tests are present and meaningful
- [ ] No security concerns
- [ ] Meets project conventions

## Common Anti-patterns

- **Rubber-stamping**: Approving without reading
- **Nitpicking**: Blocking on style preferences
- **Drive-by**: Comments without context
- **Scope creep**: Requesting unrelated changes
