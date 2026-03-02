---
pattern: auth|authentication|authorization|password|credential|secret|token|api.?key|encrypt|decrypt|hash|salt|jwt|oauth|session|cookie|csrf|xss|injection|sanitize|escape|permission|access.?control|rbac|security
files: .*auth.*|.*security.*|.*credential.*|.*secret.*|.*crypto.*|.*password.*|\.env.*|.*config/secrets.*
commands: openssl|gpg|ssh-keygen|vault
scope: agent, subagent
description: Security-sensitive code requires extra care
vocabulary: authentication authorization encryption hashing secrets credentials tokens permissions vulnerabilities
provenance:
  policy:
    - uri: home/.claude/governance/policies/security.md
      type: governance-doc
  controls:
    - id: SEC-001
      name: No Secrets in Code
      framework_ref: OWASP ASVS V2.10
      justifications:
        - Secrets in code end up in version control
        - Use environment variables or secret managers
    - id: SEC-002
      name: Input Validation
      framework_ref: OWASP ASVS V5.1
      justifications:
        - Never trust user input
        - Validate, sanitize, and escape appropriately
    - id: SEC-003
      name: Principle of Least Privilege
      framework_ref: NIST SP 800-53 AC-6
      justifications:
        - Grant minimum necessary permissions
        - Prefer deny-by-default
---

# Security Guidelines

## Critical Reminders

**STOP and think before:**
- Handling passwords or credentials
- Processing user input
- Making authorization decisions
- Storing sensitive data
- Implementing authentication

## Common Vulnerabilities to Avoid

### SQL Injection
```ruby
# BAD - Interpolated user input
query = "SELECT * FROM users WHERE id = #{params[:id]}"

# GOOD - Parameterized query
User.where(id: params[:id])
```

### XSS (Cross-Site Scripting)
```javascript
// BAD - Unescaped user content
element.innerHTML = userInput;

// GOOD - Escaped or sanitized
element.textContent = userInput;
// or use a sanitization library
```

### Command Injection
```ruby
# BAD - User input in shell command
system("ls #{user_provided_path}")

# GOOD - Use array form or escape
system("ls", user_provided_path)
```

## Secrets Management

**Never commit secrets to version control:**
- API keys
- Database passwords
- Private keys
- Tokens

**Use instead:**
- Environment variables
- Secret managers (Vault, AWS Secrets Manager)
- Encrypted config files (with key stored separately)

```bash
# Good: Environment variable
DATABASE_URL="${DATABASE_URL}"

# Bad: Hardcoded in code
DATABASE_URL="postgres://user:password@host/db"
```

## Password Handling

- **Never store plaintext passwords**
- Use bcrypt, argon2, or scrypt for hashing
- Use sufficient work factor (cost)
- Add unique salt per password

```ruby
# Good: Using bcrypt
BCrypt::Password.create(password)

# Bad: Simple hash
Digest::SHA256.hexdigest(password)
```

## Authentication Checklist

- [ ] Passwords hashed with strong algorithm
- [ ] Rate limiting on login attempts
- [ ] Account lockout after failed attempts
- [ ] Secure session management
- [ ] HTTPS enforced
- [ ] Secure cookie flags set (HttpOnly, Secure, SameSite)

## Authorization Checklist

- [ ] Check permissions on every request
- [ ] Validate user owns the resource
- [ ] Don't rely on client-side checks alone
- [ ] Log authorization failures
- [ ] Default to deny

## Code Review Focus

When reviewing security-sensitive code, verify:
1. Input validation is present
2. Output encoding/escaping is applied
3. Authentication is checked before authorization
4. Errors don't leak sensitive information
5. Logging doesn't include secrets
6. Dependencies are up to date

## When in Doubt

- Ask a security-focused team member
- Consult OWASP guidelines
- Use well-tested libraries over custom implementations
- Err on the side of caution
