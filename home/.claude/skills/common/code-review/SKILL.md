# Code Review Skill

This skill should be used when the user asks to "review this code", "check this implementation", "what's wrong with this code", "review my changes", "code review", or when examining code for quality issues.

## Trigger Phrases
- "review this code"
- "code review"
- "check this implementation"
- "what's wrong here"
- "review my changes"
- "is this code okay"
- "look at this code"

## Methodology

### 1. Understand Context First
Before reviewing, establish:
- What is this code supposed to do?
- What's the broader system context?
- Are there existing patterns in the codebase to follow?

### 2. Review Dimensions

Review code across these dimensions, in priority order:

#### Correctness (Critical)
- Does the code do what it claims to do?
- Are edge cases handled?
- Are error conditions handled appropriately?
- Are there race conditions or concurrency issues?

#### Security (Critical)
- Input validation present?
- SQL injection, XSS, command injection vulnerabilities?
- Secrets/credentials properly handled?
- Authorization checks in place?

#### Performance (Important)
- N+1 queries or unnecessary database calls?
- Unbounded loops or recursion?
- Memory leaks or excessive allocation?
- Missing indexes for queries?

#### Maintainability (Important)
- Is the code readable?
- Are names descriptive?
- Is complexity appropriate?
- Are there opportunities to simplify?

#### Testing (Important)
- Is the code testable?
- Are there tests for critical paths?
- Are edge cases tested?

### 3. Feedback Format

Structure feedback as:

```markdown
## Summary
[1-2 sentence overall assessment]

## Critical Issues
[Must fix before merge]

## Suggestions
[Would improve but not blocking]

## Questions
[Clarifications needed]

## Positive Notes
[What's done well - important for learning]
```

### 4. Review Checklist

Use this checklist mentally:

**Correctness**
- [ ] Logic is sound
- [ ] Edge cases handled
- [ ] Error handling appropriate
- [ ] Types are correct

**Security**
- [ ] Input validated
- [ ] No injection vulnerabilities
- [ ] Auth/authz in place
- [ ] Secrets not exposed

**Performance**
- [ ] No N+1 queries
- [ ] Bounded operations
- [ ] Efficient algorithms
- [ ] Appropriate caching

**Style**
- [ ] Follows project conventions
- [ ] Names are clear
- [ ] Comments where needed
- [ ] No dead code

## Anti-patterns to Avoid

1. **Nitpicking**: Don't comment on every style preference
2. **Vague feedback**: "This could be better" - say how
3. **Missing the forest**: Don't miss critical bugs while focusing on style
4. **No positive feedback**: Always acknowledge what's done well

## Example Review

```markdown
## Summary
Solid implementation of the caching layer. One security issue to address before merge.

## Critical Issues

### SQL Injection Vulnerability
`cache_key` is interpolated directly into the query at line 45:
```ruby
query = "SELECT * FROM cache WHERE key = '#{cache_key}'"
```
Use parameterized queries instead:
```ruby
query = "SELECT * FROM cache WHERE key = ?"
db.execute(query, cache_key)
```

## Suggestions

### Consider TTL Configuration
The 1-hour TTL is hardcoded (line 23). Consider making this configurable:
```ruby
TTL = ENV.fetch('CACHE_TTL_SECONDS', 3600).to_i
```

### Add Logging for Cache Misses
Would help debugging in production. Low priority.

## Questions
- Is there a reason we're not using Redis here? (Not blocking, just curious)

## Positive Notes
- Clean separation of concerns with the `CacheStrategy` interface
- Good error handling for connection failures
- Tests cover the main paths well
```

## When NOT to Use

- For simple typo fixes (just fix them)
- When user wants implementation help (use mental-model or debug-session)
- For PR reviews with multiple commits (use pr-review when available)
