# Env / Secrets Cue

## Trigger
- Editing `.env`, `.env.local`, `.env.example`, or discussing secrets/tokens/credentials.

## Guidance
- Never commit real secrets.
- Use placeholders in `.env.example`.
- If adding a new env var, update `.env.example` and relevant setup docs.
- Prefer runtime injection/secret manager over checked-in values.
