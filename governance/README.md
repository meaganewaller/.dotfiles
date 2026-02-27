# Governance System

Policy traceability for AI-assisted development workflows.

## Purpose

Answer the question: **"How do you know your agents are following policy?"**

The answer: Policies are in the code, the code traces back to policies, and you can verify the chain with a bash script.

## How It Works

1. **Policies** (`policies/`) - Human-readable documents explaining *why* we do things
2. **Cues** (`home/.claude/cues/`) - Agent instructions with `provenance:` metadata linking to policies
3. **Tooling** (`bin/`) - CLI to trace, verify, and audit the policy-cue relationship

The cue system already strips YAML frontmatter at runtime via `cue_content()` in `match-cues.sh`. This means provenance metadata adds **zero tokens to agent context** - it's "debug symbols for compiled policy."

## Quick Start

```bash
# Coverage report (default)
dotfiles governance

# Trace a specific cue
dotfiles governance --trace commit

# Find cues implementing a control
dotfiles governance --control ENG-COMMIT-001

# Find cues without provenance
dotfiles governance --gaps

# Lint provenance integrity
dotfiles governance --lint

# Machine-readable output
dotfiles governance --json
```

## Directory Structure

```
governance/
├── README.md                 # This file
├── policies/                 # Human-readable policy documents
│   ├── code-lifecycle.md     # Commit practices, change management
│   ├── secrets-management.md # Credentials handling
│   └── data-migrations.md    # Migration safety
├── controls/                 # Optional control framework mappings
│   └── custom-controls.yaml  # Engineering standards definitions
└── bin/
    ├── governance.sh         # Unified CLI (main entrypoint)
    ├── provenance-scan.py    # Scan cues, generate manifest
    └── provenance-verify.sh  # Validate structural integrity
```

## Cue Provenance Format

Cues can include a `provenance:` block in their YAML frontmatter:

```yaml
---
pattern: commit|push
scope: agent
provenance:
  policy:
    - uri: governance/policies/code-lifecycle.md
      type: governance-doc
  controls:
    - id: ENG-COMMIT-001
      name: Structured Change Records
      framework_ref: NIST SP 800-53 CM-3  # Optional external reference
      justifications:
        - Conventional commit types classify changes
        - Atomic commits enable independent review
  verified: 2026-02-26
  rationale: >
    Why this cue implements these policies/controls.
---
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `policy` | No | List of policy documents this cue implements |
| `policy[].uri` | Yes | Path to policy document (relative to repo root) |
| `policy[].type` | No | Document type (default: `governance-doc`) |
| `controls` | No | List of controls this cue enforces |
| `controls[].id` | Yes | Control identifier (e.g., `ENG-COMMIT-001`) |
| `controls[].name` | Yes | Human-readable control name |
| `controls[].framework_ref` | No | External standard reference (NIST, OWASP, etc.) |
| `controls[].justifications` | Yes | How this cue satisfies the control |
| `verified` | No | Date provenance was last reviewed (ISO format) |
| `rationale` | No | Free-text explanation of the mapping |

## Control ID Convention

Custom engineering controls use the format: `ENG-{DOMAIN}-{NNN}`

| Domain | Description |
|--------|-------------|
| `COMMIT` | Version control, change management |
| `SECRETS` | Credentials, API keys, sensitive data |
| `MIGRATE` | Database migrations, schema changes |
| `TEST` | Testing requirements, coverage |
| `REVIEW` | Code review, PR practices |

## CLI Modes

| Mode | Description |
|------|-------------|
| (default) | Coverage report showing provenance statistics |
| `--trace <cue>` | Full chain for one cue: policy → control → justifications |
| `--control <id>` | All cues implementing a specific control |
| `--policy <file>` | All cues deriving from a policy document |
| `--gaps` | Cues without any provenance metadata |
| `--stale <days>` | Cues with old `verified` dates (default: 90) |
| `--matrix` | Flat CSV for auditors |
| `--lint` | Validate structural integrity |
| `--json` | Machine-readable JSON output |

## Integration

- **CI**: Add `dotfiles governance --lint` to your workflow
- **dotfiles doctor**: Includes governance health checks
- **Pre-commit**: Optional hook to require provenance on new cues

## Philosophy

This system is **descriptive, not prescriptive**. It documents existing practices rather than enforcing new ones. The goal is auditability: when someone asks "why does your AI do X?", you can trace from behavior → cue → policy → rationale.
