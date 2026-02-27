# Decision: Governance System Implementation

**Date:** 2026-02-27
**Status:** Accepted
**Context:** dotfiles

## Summary

Implemented a policy traceability system that answers "How do you know your agents are following policy?" by extending the existing cue system with provenance metadata.

## Options Considered

### 1. Create Separate "Ways" System (Rejected)
- New directory structure parallel to cues
- Dedicated matching and loading infrastructure
- Cleaner separation of concerns

**Rejected because:** Would duplicate existing cue infrastructure. The cue system already strips YAML frontmatter at runtime, so provenance metadata adds zero tokens to agent context.

### 2. Extend Existing Cue System (Chosen)
- Add `provenance:` block to cue YAML frontmatter
- Leverage existing frontmatter stripping (zero runtime overhead)
- Build governance tooling to scan and verify provenance

**Chosen because:** Purely additive change. Existing infrastructure handles frontmatter, so governance becomes "debug symbols for compiled policy."

### 3. External Policy Database (Rejected)
- Store policy mappings in separate database/JSON
- Link to cues by ID
- Query via API

**Rejected because:** Adds complexity without benefit. Co-locating provenance with cues keeps the relationship obvious and maintainable.

## Tradeoffs

| Aspect | Benefit | Cost |
|--------|---------|------|
| Zero runtime overhead | Frontmatter stripped before agent sees it | Policy info not available to agent at runtime |
| Co-located metadata | Easy to maintain, obvious relationships | Cue files become longer |
| Custom control IDs | Tailored to our practices | Not directly auditable against external frameworks |
| Python for scanning | Stdlib only, no dependencies | Another language in the toolchain |

## Principles Applied

- **Convention over configuration** - Provenance format follows existing frontmatter conventions
- **Progressive enhancement** - Cues work without provenance; governance is opt-in
- **Measurement-driven design** - Coverage metrics reveal actual adoption
- **Self-contained artifacts** - Each cue carries its own provenance

## Implementation

Created:
- `governance/` directory with policies, controls, and bin/
- `governance.sh` CLI with trace, control, gaps, lint modes
- `provenance-scan.py` for manifest generation
- `provenance-verify.sh` for integrity validation
- 3 policy documents (code-lifecycle, secrets-management, data-migrations)
- 9 control definitions across 3 domains

Modified:
- 3 cues with provenance blocks (commit, env, migration)
- dotfiles CLI with governance subcommand
- dotfiles doctor with governance health checks

## Risks Accepted

1. **Provenance staleness** - Verified dates may drift without regular review (mitigated by --stale flag)
2. **Incomplete coverage** - Not all cues have provenance yet (mitigated by --gaps flag)
3. **Custom control framework** - Our ENG-* controls aren't externally recognized (mitigated by optional framework_ref field)

## Reversal Cost

**Medium** - Could remove governance/ directory and provenance blocks from cues without affecting cue functionality. CLI changes would need cleanup.
