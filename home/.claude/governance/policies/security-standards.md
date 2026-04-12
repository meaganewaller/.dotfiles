# Security Standards Policy

## Purpose

Establish security practices for building systems that protect user data, prevent unauthorized access, and resist common attack vectors.

## Principles

### 1. Defense in Depth

Layer multiple security controls rather than relying on a single mechanism.

**Why:** Layered defense:
- Provides redundancy when one control fails
- Increases attacker cost
- Catches different attack vectors

### 2. Least Privilege

Grant only the minimum permissions required for each operation.

**Why:** Minimal permissions:
- Limit blast radius of compromises
- Reduce accidental damage potential
- Simplify access auditing

### 3. Input Validation

Validate and sanitize all external input at system boundaries.

**Why:** Input validation:
- Prevents injection attacks (SQL, XSS, command)
- Ensures data integrity
- Documents expected formats

### 4. Secure Defaults

Systems should be secure by default, requiring explicit action to reduce security.

**Why:** Secure defaults:
- Protect against misconfiguration
- Guide developers toward safe patterns
- Reduce security review burden

### 5. Audit Trail

Log security-relevant events for later analysis.

**Why:** Audit trails:
- Enable incident investigation
- Support compliance requirements
- Detect anomalous patterns

## Controls Implemented

| Control ID | Description | Framework Ref |
|------------|-------------|---------------|
| SEC-STD-001 | Defense in Depth | NIST SP 800-53 SC-7 |
| SEC-STD-002 | Least Privilege Access | NIST SP 800-53 AC-6 |
| SEC-STD-003 | Input Validation | OWASP ASVS V5 |
| SEC-STD-004 | Secure Default Configuration | CIS Benchmarks |
| SEC-STD-005 | Security Event Logging | NIST SP 800-53 AU-2 |

## Related Cues

- `security-reliability/cue.md` - Triggered on auth/permission code
- `common/security/cue.md` - Triggered on security-sensitive operations
- `env/cue.md` - Triggered on environment/secrets handling
