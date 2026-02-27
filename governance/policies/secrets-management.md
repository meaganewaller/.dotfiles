# Secrets Management Policy

## Purpose

Prevent credential exposure and establish safe practices for handling sensitive configuration.

## Scope

All secrets including API keys, passwords, tokens, certificates, and other credentials.

## Principles

### 1. Never Commit Secrets

Secrets must never be committed to version control.

**Why**: Committed secrets are:
- Permanent in git history (even after deletion)
- Automatically harvested by credential scanners
- Propagated to forks and clones
- Accessible to anyone with repo access

**Implementation**:
- Use `.gitignore` to exclude secret files
- Use pre-commit hooks to detect secrets
- Store secrets in environment variables or secret management systems

### 2. Environment Variable Storage

Secrets should be injected at runtime via environment variables.

**Why**: Environment variables:
- Decouple secrets from code
- Enable rotation without code changes
- Support different values per environment
- Follow 12-factor app principles

**Implementation**:
- Define secrets as environment variables
- Use `.env` files for local development (gitignored)
- Use secret management systems in production

### 3. Configuration Documentation

Required configuration should be documented without exposing actual values.

**Why**: Documentation enables:
- New developers to onboard independently
- Operations to configure deployments
- Auditors to understand requirements

**Implementation**:
- Maintain `.env.example` with placeholder values
- Document required variables in README
- Include descriptions and valid value ranges

### 4. Principle of Least Privilege

Secrets should have minimal required permissions.

**Why**: Least privilege:
- Limits blast radius of compromised credentials
- Enables fine-grained auditing
- Supports compliance requirements

**Implementation**:
- Create service-specific credentials
- Use read-only access when writes aren't needed
- Rotate credentials regularly

## Controls

| Control ID | Name | Description |
|------------|------|-------------|
| ENG-SECRETS-001 | No Committed Secrets | Secrets never in version control |
| ENG-SECRETS-002 | Environment Variable Storage | Runtime injection of secrets |
| ENG-SECRETS-003 | Configuration Documentation | .env.example and README |

## Incident Response

If a secret is accidentally committed:
1. Immediately rotate the compromised credential
2. Use `git filter-branch` or BFG to remove from history
3. Force-push the cleaned history (coordinate with team)
4. Audit for any unauthorized use

## Review Schedule

This policy should be reviewed annually or after security incidents.

---

*Last reviewed: 2026-02-26*
