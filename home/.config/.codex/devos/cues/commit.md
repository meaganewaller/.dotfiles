# Commit / Push Cue

## Trigger
- User asks about commit, push, amend, rebase, squash, merge, changelog, or versioning.
- Planned command includes `git commit` or `git push`.

## Guidance
- Prefer conventional commits: `type(scope): message`.
- Keep commit subject <= 72 chars; add body when rationale is non-obvious.
- Keep commits atomic and independently revertible.
- Before push, run relevant tests and pull/rebase latest branch state.
