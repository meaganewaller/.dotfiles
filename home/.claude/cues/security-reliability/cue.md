---
# Triggers when working on security-sensitive or reliability-critical code
pattern: auth|login|password|session|token|api.*key|secret|encrypt|permission|role|access.*control|sanitize|escape|inject|xss|csrf|validate.*input|user.*input
commands: rails g.*auth|devise|omniauth|jwt|bcrypt
files: auth|session|login|password|token|permission|controller|api/|middleware
scope: agent, subagent
description: Security and reliability considerations for user-facing and critical code paths
vocabulary: authentication authorization session token password encrypt decrypt permission role access validate sanitize escape injection xss csrf security reliability
provenance:
  policy:
    - uri: home/.claude/governance/policies/security-standards.md
      type: governance-doc
  controls:
    - id: SEC-DESIGN-001
      name: Security at Design Time
      justifications:
        - Security is cheaper to build in than bolt on
        - OWASP Top 10 should be considered during design
    - id: REL-DESIGN-001
      name: Reliability at Design Time
      justifications:
        - Failure modes should be explicit, not discovered in production
        - Error handling is part of the design, not cleanup
  verified: 2026-03-04
  rationale: >
    No security or reliability principles were invoked across 4 active projects.
    These concerns need design-time attention, not just review-time checking.
---

# Security & Reliability Check

When working on auth, user input, or critical paths:

## Quick Security Check

1. **Boundaries** - Is input validated? Is output escaped?
2. **Auth** - Is the endpoint protected? Is authorization checked?
3. **Secrets** - Are credentials in env vars, not code?

## Quick Reliability Check

1. **Failures** - What happens when this fails? Is it handled?
2. **Retries** - Is this operation idempotent? Safe to retry?
3. **Observability** - Can you debug this in production?

See `~/.claude/principles/security-reliability.md` for full guidance.

**Key insight:** Security and reliability are design constraints, not review checklist items.
