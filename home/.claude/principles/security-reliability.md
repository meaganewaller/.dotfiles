# Security and Reliability Principles

Actionable guidance for building secure, reliable systems. Apply these during design, not just review.

## Security Mindset

### Core Insight

**Security is a design constraint, not a cleanup task.** Bolt-on security is expensive and often incomplete. Consider threats during modeling, not after implementation.

### Input Boundaries

Every system boundary is a potential attack surface:

- **User input** - Forms, URLs, file uploads, API parameters
- **External APIs** - Responses may be malformed or malicious
- **Database queries** - Interpolated values enable injection
- **File paths** - User-controlled paths enable traversal
- **Deserialization** - Untrusted data can execute code

**Principle:** Validate at ingress, sanitize at egress. Never trust data that crosses a boundary.

### Authentication & Authorization

| Question | Why It Matters |
|----------|----------------|
| Who is the caller? | Authentication establishes identity |
| What can they access? | Authorization gates resources |
| Is the session valid? | Sessions can be stolen or expired |
| Is the action idempotent? | Replay attacks exploit non-idempotent actions |

**Common gaps:**
- Checking auth on the page but not the API
- Authorizing the resource but not the action
- Trusting client-side state for permissions

### Secrets Management

- **Never** commit secrets (API keys, passwords, tokens)
- **Never** log secrets (even accidentally via request dumps)
- **Never** expose secrets in error messages
- **Always** use environment variables or secret managers
- **Always** rotate credentials periodically

### OWASP Top 10 Quick Check

Before shipping user-facing code, consider:

1. **Injection** - Are queries parameterized?
2. **Broken Auth** - Is session management secure?
3. **Sensitive Data** - Is PII encrypted at rest and in transit?
4. **XXE** - Are XML parsers configured safely?
5. **Broken Access Control** - Can users access others' data?
6. **Misconfiguration** - Are defaults secure?
7. **XSS** - Is output escaped?
8. **Insecure Deserialization** - Is untrusted data handled safely?
9. **Known Vulnerabilities** - Are dependencies up to date?
10. **Insufficient Logging** - Can you detect and investigate incidents?

---

## Reliability Mindset

### Core Insight

**Reliability is about failure modes, not happy paths.** Systems fail. The question is: do they fail gracefully?

### Failure Categories

| Category | Example | Mitigation |
|----------|---------|------------|
| **Transient** | Network blip, timeout | Retry with backoff |
| **Persistent** | Service down, bad config | Circuit breaker, fallback |
| **Data** | Corrupt input, schema mismatch | Validation, dead-letter queue |
| **Resource** | OOM, disk full, connection exhaustion | Limits, monitoring, cleanup |

### Error Handling Hierarchy

1. **Prevent** - Validate inputs, check preconditions
2. **Handle** - Catch specific errors, take corrective action
3. **Contain** - Prevent cascading failures (circuit breakers)
4. **Report** - Log with context for debugging
5. **Recover** - Graceful degradation, retry strategies

**Anti-pattern:** Catching all exceptions and swallowing them silently.

### Idempotency

Operations that can be safely retried:
- **Idempotent:** GET, PUT (replace), DELETE (if already gone)
- **Not idempotent:** POST (create), increment, append

For non-idempotent operations:
- Use idempotency keys
- Check for existing records before creating
- Make operations atomic where possible

### Observability

Can you answer these questions about your system?

- **What happened?** (logs with context)
- **When did it happen?** (timestamps, correlation IDs)
- **How often?** (metrics, counters)
- **What was affected?** (user IDs, request IDs)
- **Why?** (stack traces, state dumps)

---

## Quick Reference

### Before handling user input:
- [ ] Input validated against expected format
- [ ] Output escaped for context (HTML, SQL, shell)
- [ ] Error messages don't leak internal details

### Before adding authentication:
- [ ] Sessions are server-side or cryptographically signed
- [ ] Passwords hashed with bcrypt/argon2 (not MD5/SHA1)
- [ ] Sensitive actions require re-authentication

### Before adding authorization:
- [ ] Every endpoint checks permissions
- [ ] Authorization is on the resource AND the action
- [ ] Default deny, explicit allow

### Before deploying:
- [ ] No secrets in code or logs
- [ ] Dependencies scanned for vulnerabilities
- [ ] Error handling tested (not just happy path)

### Before calling external services:
- [ ] Timeouts configured
- [ ] Retries with exponential backoff
- [ ] Circuit breaker for persistent failures
- [ ] Response validation (don't trust external data)

---

## Signals This Applies

Invoke these principles when working on:
- User authentication or authorization
- Form handling or file uploads
- API endpoints (especially public ones)
- Database queries with user input
- External service integrations
- Error handling or logging
- Session management
- Credential or secret handling
