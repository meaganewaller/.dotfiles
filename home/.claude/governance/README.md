# Governance System

Policy traceability for Claude agent cues. Answer: "How do you know your agents are following policy?"

**The answer:** Policies are in the code, the code traces back to policies, and you can verify the chain with a bash script.

## How It Works

Your existing cue system strips YAML frontmatter at runtime via `cue_content()` in `match-cues.sh`. This means we can add `provenance:` metadata to cues without affecting agent context (zero tokens, zero latency). The governance layer becomes "debug symbols for compiled policy."

```
cue.md (with provenance)
         │
    ┌────┴────┐
    ▼         ▼
 Agent     Governance
 (body)    (frontmatter)
```

## The Compilation Metaphor

Cues are "compiled policy." A human reads a policy document, interprets it for the agent context, and writes a cue.md file - compressed, directive, stripped of rationale. The guidance that reaches the agent is the object code. The policy document is the source.

| Concept | Software Build | Cue System |
|---------|---------------|------------|
| Source code | `.c` files | Policy documents |
| Compiler | `gcc` | Human authoring process |
| Object code | `.o` files | `cue.md` files |
| Debug symbols | DWARF / PDB | `provenance:` frontmatter block |
| Symbol table | `.map` file | `provenance-manifest.json` |

Debug symbols don't affect program execution but are essential for debugging. Provenance metadata doesn't affect cue injection but is essential for governance auditing.

## The Full Chain

```
Regulatory Framework    (NIST, ISO, OWASP, SOC 2, CIS...)
       ↓
Control Requirement     (NIST SP 800-53 CM-3, OWASP A03:Injection...)
       ↓
Policy Document         (ADR, governance doc, internal standard)
       ↓
Cue File                (cue.md — compiled guidance, context-optimized)
       ↓
Agent Context           (injected at runtime when triggers match)
```

Each layer compresses the one above it. The regulatory framework is hundreds of pages. The control requirement is a paragraph. The policy document is a few pages of interpretation. The cue is 30 lines of directives. The agent sees only the directives - but the full chain is walkable.

## Directory Structure

```
governance/
├── README.md                  # This file
├── policies/                  # Human-readable policy documents
│   ├── code-lifecycle.md      # Commit practices, change management
│   ├── secrets-management.md  # Env vars, credentials handling
│   ├── data-migrations.md     # Migration safety practices
│   └── architecture-decisions.md  # When and how to write ADRs
│
├── controls/                  # Control framework mappings
│   └── custom-controls.yaml   # Your engineering standards
│
└── bin/
    ├── governance.sh          # Unified CLI (main entrypoint)
    ├── provenance-scan.py     # Scan cues, generate manifest
    └── provenance-verify.sh   # Validate structural integrity
```

## Quick Start

```bash
# Via dotfiles CLI (recommended)
dotfiles governance              # Coverage report
dotfiles governance --trace commit
dotfiles governance --gaps
dotfiles governance --lint

# Direct script access
~/.claude/governance/bin/governance.sh
~/.claude/governance/bin/governance.sh --trace commit
```

## Provenance Format

Add a `provenance:` block to cue frontmatter:

```yaml
---
pattern: commit|push|amend
commands: git\s+(commit|push)
scope: agent
provenance:
  policy:
    - uri: home/.claude/governance/policies/code-lifecycle.md
      type: governance-doc
  controls:
    - id: ENG-COMMIT-001
      name: Structured Change Records
      framework_ref: NIST SP 800-53 CM-3    # Optional
      justifications:
        - Conventional commit types classify changes
        - Atomic commits enable independent review
  verified: 2026-02-26
  rationale: >
    Conventional commits create structured change records supporting
    automated changelog generation and compliance auditing.
---
```

## CLI Modes

| Mode | Description |
|------|-------------|
| (default) | Coverage report: cues with/without provenance |
| `--trace <cue>` | End-to-end chain for one cue |
| `--control <id>` | List cues implementing a control |
| `--policy <file>` | List cues deriving from a policy |
| `--gaps` | Show cues missing provenance |
| `--stale <days>` | Show old verified dates (default: 90) |
| `--matrix` | Flat CSV/table for auditors |
| `--lint` | Validate provenance integrity |
| `--json` | Machine-readable output |

## Verification

The `--lint` mode validates:

1. **Policy URIs exist** - All `policy.uri` paths resolve
2. **Justifications present** - All controls have non-empty justifications
3. **Valid dates** - `verified` dates are ISO format and not stale
4. **Rationale present** - Non-empty rationale for each provenance block

## Integration Points

- **dotfiles CLI**: `dotfiles governance` subcommand
- **dotfiles doctor**: Governance health checks (coverage %, stale cues)
- **CI**: `governance lint` job in workflow

## Control Format

Controls use custom engineering IDs with optional mapping to real frameworks:

```yaml
controls:
  - id: ENG-COMMIT-001                    # Your custom ID
    name: Structured Change Records       # Human-readable name
    framework_ref: NIST SP 800-53 CM-3    # Optional: real standard mapping
    justifications:
      - Conventional commit types classify changes
      - Atomic commits enable independent review
```

This keeps daily governance lightweight while maintaining the option to produce compliance-ready documentation when needed.

## Philosophy

- **Zero runtime cost** - Provenance is stripped before agent sees cues
- **Policies as code** - Version-controlled, auditable, diffable
- **Hybrid compliance** - Custom controls for daily work, framework mapping when needed
- **Verification by default** - CI catches gaps and staleness automatically
