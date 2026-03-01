---
files: \.env$|\.env\.local$|\.env\.example$
scope: agent, subagent
description: Environment variables, secrets, API keys, and configuration management
vocabulary: secret password token credential apikey api_key env environment config
provenance:
  policy:
    - uri: home/.config/.codex/devos/governance/policies/secrets-management.md
      type: governance-doc
  controls:
    - id: ENG-SECRETS-001
      name: No Committed Secrets
      justifications:
        - Secrets in git history are effectively permanent.
        - Secret exposure risks immediate credential abuse.
  verified: 2026-03-01
  rationale: >
    Keeping secrets out of version control and documenting required env vars
    reduces exposure risk and onboarding friction.
---

# Env / Secrets Cue

- Never commit real secrets.
- Use placeholders in `.env.example`.
- When adding new env vars, update setup docs.
- Prefer runtime injection or a secret manager.
