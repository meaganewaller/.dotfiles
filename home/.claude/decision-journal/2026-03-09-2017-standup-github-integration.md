# Tradeoff: 2026-03-09

**Branch:** main
**Files:** home/.claude/skills/common/standup/scripts/aggregate-standup.sh
**Source:** manual-capture

## Decision Summary

Added GitHub PR integration to the standup skill using the `gh` CLI, with graceful degradation when unavailable.

## What Was Chosen

Optional `gh` CLI integration that:
- Checks for `gh` availability and authentication before making calls
- Fetches PRs opened yesterday, merged yesterday, and pending reviews
- Silently skips GitHub data if `gh` is missing or unauthenticated
- Passes JSON data to Python for consistent output formatting

## Alternatives Considered

- **Require gh CLI**: Simpler code but breaks standup for users without gh
- **GitHub API directly**: More control but requires token management, adds curl/auth complexity
- **Separate gh-standup.sh script**: Cleaner separation but fragments the standup experience
- **GraphQL API**: More efficient (single request) but more complex query construction

## Trade-offs

- **Optional dependency** vs **guaranteed PR data**: Chose graceful degradation to keep standup useful even without gh
- **Three sequential gh calls** vs **single combined query**: Sequential is simpler to understand and debug, minor latency cost
- **Search query date filtering** vs **list + filter**: Search queries work across repos, list is limited to current repo
- **Inline data fetching** vs **cached data**: Real-time is more accurate but slower; no caching for simplicity

## Principles Applied

- Simplifying For Change: Single script remains self-contained
- Making Principled Choices: Graceful degradation over hard requirements
- Norming On Conventions: Follows existing standup script patterns

## Revisit If

- `gh` CLI calls become too slow (>5 seconds) - consider caching or parallel calls
- Need PR data from specific repos only - add repo filtering
- Users want PR comments/review status - would need additional API calls
- GitHub rate limiting becomes an issue - add caching layer
