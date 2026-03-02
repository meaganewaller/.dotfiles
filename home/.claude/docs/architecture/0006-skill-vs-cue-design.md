---
status: accepted
date: 2026-03-02
deciders: [meaganewaller]
---

# 6. Skill vs Cue Design

## Status

Accepted

## Context

Claude Code supports two mechanisms for extending agent behavior:

1. **Skills** - Reusable workflows invoked explicitly via `/skill-name` or the Skill tool
2. **Cues** - Contextual guidance injected automatically based on triggers

Both can influence agent behavior, but they serve different purposes. Without clear guidelines, contributors may:

- Create a skill when a cue would be more appropriate (or vice versa)
- Duplicate logic between skills and cues
- Miss opportunities for automatic guidance by requiring explicit invocation

We need a principled framework for deciding when to use each mechanism.

## Decision

We will use skills for **explicit, multi-step workflows** and cues for **implicit, contextual guidance**.

### Skills

**Definition:** A skill is a packaged workflow that the user explicitly invokes when they want a specific outcome.

**Characteristics:**

| Aspect | Description |
|--------|-------------|
| Invocation | Explicit: `/skill-name` or Skill tool |
| Scope | Can fork context or run inline |
| Output | Structured deliverable (review, analysis, artifact) |
| Duration | Multi-turn, potentially long-running |
| Tools | May have restricted tool access |

**Structure:**

```
home/.claude/skills/common/<skill-name>/
├── SKILL.md          # Workflow definition with YAML frontmatter
└── scripts/          # Supporting scripts (optional)
```

**SKILL.md Format:**

```yaml
---
name: weekly-review
description: Aggregates dev-os-events and produces staff-level insights...
context: fork           # fork | inline
agent: general-purpose  # Agent type for execution
allowed-tools:          # Tool restrictions
  - Read
  - Write
  - Bash(jq *)
---

# Skill Title

Step-by-step workflow instructions...
```

**When to Create a Skill:**

- User needs to explicitly request a workflow
- Output is a structured deliverable (report, review, analysis)
- Workflow has multiple steps that must execute in sequence
- Different users may want different skill variations
- Workflow needs specific tool restrictions

**Examples:**
- `/weekly-review` - Generates weekly engineering review
- `/code-review` - Systematic code review with dimensions
- `/debug-session` - Structured hypothesis-test debugging
- `/root-cause` - 5-Whys analysis for incidents
- `/mental-model` - Deep codebase understanding

### Cues

**Definition:** A cue is contextual guidance injected automatically when trigger conditions are met.

**Characteristics:**

| Aspect | Description |
|--------|-------------|
| Invocation | Automatic based on triggers |
| Scope | Injected into current context |
| Output | Guidance, not deliverables |
| Duration | One-shot injection |
| Triggers | Pattern, file, command matchers |

**Structure:**

```
home/.claude/cues/common/<cue-name>/
├── cue.md            # Guidance with YAML frontmatter
└── macro.sh          # Dynamic content injection (optional)
```

**cue.md Format:**

```yaml
---
pattern: \btest\b|\bspec\b|testing       # Regex for prompt text
files: .*_test\.(rb|go)|.*_spec\.rb      # Regex for file paths
commands: rspec|jest|pytest              # Regex for bash commands
scope: agent, subagent                   # When to inject
description: Testing best practices      # Human-readable purpose
vocabulary: test spec mock stub          # Additional trigger terms
provenance:                              # Governance traceability
  policy:
    - uri: governance/policies/quality.md
---

# Guidance Title

Contextual guidance content...
```

**Trigger Types:**

| Trigger | Fires When | Example |
|---------|------------|---------|
| `pattern` | Prompt matches regex | `\bADR\b` fires on "create an ADR" |
| `files` | File path matches regex | `.*_spec\.rb` fires on spec files |
| `commands` | Bash command matches regex | `rspec` fires on test runs |
| `vocabulary` | Any term appears in context | "mock", "stub", "fixture" |

**When to Create a Cue:**

- Guidance should appear automatically without user asking
- Relevant whenever a certain context is detected
- Content is advisory, not procedural
- Same guidance applies across many situations
- User shouldn't have to remember to ask

**Examples:**
- `testing` - Best practices when working with tests
- `security` - OWASP guidance when handling sensitive data
- `debugging` - Systematic approach when errors occur
- `adr` - Format guidance when writing architecture decisions

### Decision Matrix

| Factor | → Skill | → Cue |
|--------|---------|-------|
| User must ask for it | ✓ | |
| Should happen automatically | | ✓ |
| Multi-step workflow | ✓ | |
| One-shot guidance | | ✓ |
| Produces artifact | ✓ | |
| Shapes behavior | | ✓ |
| Needs tool restrictions | ✓ | |
| Context-dependent trigger | | ✓ |

### Hybrid Patterns

Sometimes skills and cues work together:

1. **Cue promotes skill:** A cue can mention relevant skills
   ```markdown
   # Debugging Cue
   ...
   For structured debugging sessions, consider `/debug-session`.
   ```

2. **Skill references cues:** A skill can note when cues might fire
   ```markdown
   # Code Review Skill
   ...
   Note: The security cue may inject additional guidance for sensitive files.
   ```

3. **Cue captures skill output:** Event telemetry tracks skill invocations
   ```json
   {"event_type": "skill_invoked", "payload": {"skill": "weekly-review"}}
   ```

### Scope Considerations

**Skills:**
- `context: fork` - Runs in separate context (protects main conversation)
- `context: inline` - Runs in current context (shares conversation state)

**Cues:**
- `scope: agent` - Fires in main conversation
- `scope: subagent` - Fires in spawned agents
- `scope: agent, subagent` - Fires in both

## Consequences

### Positive

- Clear mental model for contributors
- Automatic guidance without user cognitive load (cues)
- Explicit workflows when users need them (skills)
- Reduced duplication between the two mechanisms
- Governance traceability through cue provenance

### Negative

- Two systems to learn and maintain
- Edge cases may not fit cleanly into either category
- Cue triggers can fire unexpectedly (false positives)
- Skills require explicit invocation (users may forget)

### Neutral

- Both mechanisms use YAML frontmatter (consistency)
- Both live in `home/.claude/` directory structure
- Both can emit events for telemetry
- Neither replaces the other; they're complementary

## Alternatives Considered

### Alternative A: Skills Only

Everything is a skill; no automatic injection.

**Pros:** Single system, user always in control
**Cons:** Users must remember every skill; no contextual help
**Why rejected:** Automatic guidance is too valuable; users shouldn't need to remember to ask for testing best practices

### Alternative B: Cues Only

Everything is a cue; no explicit invocation.

**Pros:** Single system, everything automatic
**Cons:** No way to request complex workflows; cues aren't designed for multi-step processes
**Why rejected:** Some workflows (weekly review, code review) genuinely need explicit invocation and structured execution

### Alternative C: Merged System with Mode Flag

Single definition file with `mode: skill | cue | both`.

**Pros:** One system to learn, can mark something as both
**Cons:** Conflates different concerns; SKILL.md and cue.md have different structures
**Why rejected:** The structures are different enough that merging creates confusion; better to have clear separation

### Alternative D: Agent-Native Prompts Only

No skills or cues; rely on Claude's base capabilities.

**Pros:** No custom infrastructure to maintain
**Cons:** Lose domain-specific guidance, consistent workflows, governance traceability
**Why rejected:** The whole point of Dev OS is customized developer experience

## References

- `home/.claude/skills/common/` - Skill implementations
- `home/.claude/cues/common/` - Cue implementations
- `home/.claude/hooks/common/match-cues.sh` - Cue matching logic
- `home/.claude/hooks/common/show-cue.sh` - Cue rendering
- `home/.claude/docs/hooks-and-cues/writing-cues.md` - Cue authoring guide
- `home/.claude/docs/skills/writing-skills.md` - Skill authoring guide
