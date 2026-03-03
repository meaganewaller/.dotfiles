# Security Policy

## Purpose

Establish secure coding practices to protect against common vulnerabilities and ensure proper handling of sensitive data.

## Principles

### 1. No Secrets in Code

Never commit secrets, credentials, API keys, or tokens to version control.

**Why:** Secrets in code create:
- Permanent exposure in git history (even after "removal")
- Risk of credential theft by anyone with repo access
- Compliance violations (SOC2, GDPR, HIPAA)
- Blast radius expansion when repos are compromised

**Instead:**
- Use environment variables
- Use secret managers (Vault, AWS Secrets Manager)
- Store encrypted configs with keys managed separately

### 2. Input Validation

Never trust user input. Validate, sanitize, and escape appropriately.

**Why:** Unvalidated input enables:
- SQL injection (database compromise)
- XSS (session hijacking, defacement)
- Command injection (server compromise)
- Path traversal (unauthorized file access)

**Validation approach:**
- Validate type, length, format, and range
- Use allowlists over denylists
- Sanitize for context (HTML, SQL, shell)
- Escape output appropriately

### 3. Principle of Least Privilege

Grant minimum necessary permissions. Default to deny.

**Why:** Excessive permissions:
- Expand blast radius of compromises
- Enable privilege escalation attacks
- Make access auditing difficult
- Violate compliance requirements

**Implementation:**
- Role-based access control (RBAC)
- Time-bounded access grants
- Regular permission audits
- Explicit denies for sensitive operations

### 4. Defense in Depth

Apply multiple layers of security controls.

**Why:** Single points of failure:
- Allow complete compromise when bypassed
- Assume attackers can't reach inner layers
- Miss opportunities to detect attacks

**Layers:**
- Input validation at boundary
- Authentication before authorization
- Parameterized queries in data layer
- Output encoding in view layer
- Logging and monitoring throughout

## Controls Implemented

| Control ID | Description | Framework Reference |
|------------|-------------|---------------------|
| SEC-001 | No Secrets in Code | OWASP ASVS V2.10 |
| SEC-002 | Input Validation | OWASP ASVS V5.1 |
| SEC-003 | Principle of Least Privilege | NIST SP 800-53 AC-6 |

## Related Cues

- `security/cue.md` - Triggered on auth, encryption, and credential operations
