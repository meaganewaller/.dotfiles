# Secrets Management Policy

## Purpose

Prevent accidental exposure of sensitive credentials while maintaining clear documentation of required configuration.

## Principles

### 1. Never Commit Real Secrets

Never commit actual API keys, passwords, tokens, or other credentials to version control.

**Why:** Once committed, secrets are:
- Visible in git history forever (even after "removal")
- Exposed to anyone with repo access
- Potentially scraped by automated tools
- A compliance and security liability

### 2. Use Environment Variables

Store secrets in environment variables loaded at runtime, not in code.

**Why:** Environment variables:
- Are not version controlled
- Can be rotated without code changes
- Are managed by deployment infrastructure
- Follow the 12-factor app methodology

### 3. Document with .env.example

Maintain a `.env.example` file with placeholder values for all required environment variables.

**Why:** Documentation ensures:
- New developers can onboard quickly
- Required configuration is discoverable
- CI/CD pipelines can be properly configured
- No "works on my machine" mysteries

### 4. Update Documentation

When adding new environment variables, update:
- `.env.example` with placeholder
- README or runbook with description
- Any infrastructure-as-code definitions

**Why:** Synchronized documentation:
- Prevents deployment failures
- Enables self-service setup
- Maintains operational clarity

## Controls Implemented

| Control ID | Description |
|------------|-------------|
| ENG-SECRETS-001 | No Committed Secrets |
| ENG-SECRETS-002 | Environment Variable Storage |
| ENG-SECRETS-003 | Configuration Documentation |

## Related Cues

- `env/cue.md` - Triggered when editing .env files
