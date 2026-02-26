---
# When editing env or config files, show this cue.
files: \.env$|\.env\.local$|\.env\.example$
scope: agent
---

# Env / secrets cue

- **Never** put real secrets (API keys, passwords) in `.env` or commit them. Use `.env.example` with placeholders and document required vars.
- If you add a new env var, update `.env.example` and any README or runbook that lists configuration.
