---
# When editing env or config files, show this cue.
files: \.env$|\.env\.local$|\.env\.example$
scope: agent
provenance:
  policy:
    - uri: home/.claude/governance/policies/secrets-management.md
      type: governance-doc
  controls:
    - id: ENG-SECRETS-001
      name: No Committed Secrets
      justifications:
        - Secrets in git history are permanent and exploitable
        - Automated scanners target committed credentials
    - id: ENG-SECRETS-002
      name: Environment Variable Storage
      justifications:
        - Runtime injection decouples secrets from code
        - Enables rotation without code changes
    - id: ENG-SECRETS-003
      name: Configuration Documentation
      justifications:
        - .env.example documents required variables
        - New developers can onboard without hunting for config
  verified: 2026-02-26
  rationale: >
    Preventing secrets in version control protects against credential
    exposure. Environment variables and documented examples enable
    secure, self-service configuration.
---

# Env / secrets cue

- **Never** put real secrets (API keys, passwords) in `.env` or commit them. Use `.env.example` with placeholders and document required vars.
- If you add a new env var, update `.env.example` and any README or runbook that lists configuration.
