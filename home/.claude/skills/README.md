# Skills Catalog

This directory contains 20 custom Claude Code skills for engineering workflows.

## Quick Reference

| Skill | Purpose | Invocation |
|-------|---------|------------|
| [abstraction-check](#abstraction-check) | Evaluate if abstraction is justified | "should I extract this?" |
| [api-conventions](#api-conventions) | API design principles | "how should this API work?" |
| [assumption-scan](#assumption-scan) | Surface hidden assumptions | "what are we assuming?" |
| [code-review](#code-review) | Review code quality and security | "review this code" |
| [complexity-audit](#complexity-audit) | Find accidental complexity | "why is this hard to change?" |
| [debug-session](#debug-session) | Systematic debugging methodology | "help me debug this" |
| [dependency-evaluator](#dependency-evaluator) | Assess third-party deps | "should we add this library?" |
| [design-review](#design-review) | Review technical designs | "review my approach" |
| [experiment-design](#experiment-design) | Design experiments | "how do I test this idea?" |
| [friction-deep-dive](#friction-deep-dive) | Analyze recurring friction | "why do I keep hitting this?" |
| [impact-narrative](#impact-narrative) | Translate to business impact | "what's the business value?" |
| [mental-model](#mental-model) | Understand before modifying | "how does this work?" |
| [promotion-draft](#promotion-draft) | Prepare promotion packets | "help me write my promo doc" |
| [refactor-safely](#refactor-safely) | Plan safe refactoring | "how do I safely change this?" |
| [risk-audit](#risk-audit) | Audit for failure modes | "what could go wrong?" |
| [root-cause](#root-cause) | 5 Whys analysis | "why did this break?" |
| [standup](#standup) | Daily standup from dev-os events | "/standup", "daily standup" |
| [template-context](#template-context) | Extract template logic to testable PORO | "ERB coverage", "template testing" |
| [tradeoff-memo](#tradeoff-memo) | Document decisions | "document this decision" |
| [weekly-review](#weekly-review) | Weekly engineering review | "/weekly-review" |

---

## Skill Details

### abstraction-check

**Trigger phrases:** "should I extract this?", "is this abstraction worth it?", "am I over-engineering?", "should I DRY this up?"

**What it does:**
- Applies Rule of Three for duplication
- Evaluates if duplication is actually harmful
- Checks for speculative generality
- Assesses cognitive load cost
- Provides decision: keep inline vs extract

**Agent:** Runs inline (no fork)

---

### api-conventions

**Trigger phrases:** "how should this endpoint work?", "what should this return?", "how do I handle errors?"

**What it does:**
- Provides REST, GraphQL, CLI, and service interface conventions
- Documents HTTP methods, status codes, pagination patterns
- Covers error response structure
- Lists naming conventions and anti-patterns

**Agent:** Runs inline (both passive and user-invocable)

---

### assumption-scan

**Trigger phrases:** "what could go wrong?", "what are we assuming?", "where is this fragile?"

**What it does:**
- Identifies 7 assumption types (explicit, implicit, environmental, performance, team, temporal, dependency)
- Scores fragility (likelihood × impact)
- Recommends mitigations

**Agent:** Runs inline

---

### code-review

**Trigger phrases:** "review this code", "code review", "check this implementation", "what's wrong here", "review my changes"

**What it does:**
- Reviews code across dimensions: correctness, security, performance, maintainability, testing
- Structures feedback: critical issues, suggestions, questions, positive notes
- Provides checklist for systematic review
- Avoids anti-patterns (nitpicking, vague feedback, missing critical bugs)

**Agent:** Runs inline

---

### complexity-audit

**Trigger phrases:** "is this module too complex?", "why is this hard to change?", "what's causing coupling?"

**What it does:**
- Detects circular dependencies, cross-layer leakage, god objects
- Finds implicit state and hidden invariants
- Classifies findings: harmless / concerning / dangerous
- Provides grep patterns for detection

**Agent:** Explore (forked, read-only)

---

### dependency-evaluator

**Trigger phrases:** "should we add this library?", "is this dependency safe?", "should we upgrade X?"

**What it does:**
- Research checklist (stars, commits, CVEs, maintainers)
- 7-dimension evaluation (fit, build vs buy, maintenance, bus factor, volatility, security, exit)
- Red flags for auto-rejection
- Decision: adopt / reject / defer / build in-house

**Agent:** Plan (forked)

---

### debug-session

**Trigger phrases:** "help me debug", "why isn't this working", "this is broken", "find the bug", "debug this"

**What it does:**
- Follows debug loop: Observe → Hypothesize → Test → Conclude
- Gathers evidence systematically (errors, logs, context)
- Ranks hypotheses by likelihood, testability, recency
- Provides debugging techniques (binary search, minimal reproduction, diff analysis)
- Documents root cause, fix, and prevention

**Agent:** Runs inline

---

### design-review

**Trigger phrases:** "what's wrong with this design?", "what am I missing?", "review my approach"

**What it does:**
- 8-step review process
- Risk assessment (coupling, complexity, operational, reversibility)
- Layering violation detection
- Scalability and edge case analysis
- Alternative generation

**Agent:** Plan (forked, with Read/Grep/Glob)

---

### experiment-design

**Trigger phrases:** "how do I test this idea?", "will this change help?", "how do I measure success?"

**What it does:**
- Hypothesis formula (falsifiable, specific, time-bound)
- Variable identification (independent, dependent, control)
- Metric selection criteria
- Duration heuristics with sample size estimation
- Rollout and rollback planning

**Agent:** Plan (forked)

---

### friction-deep-dive

**Trigger phrases:** "why do I keep hitting this error?", "how do I get better at X?"

**What it does:**
- Connects to Dev OS friction taxonomy
- Analyzes friction logs for patterns
- Creates 3-session deliberate practice plan
- Tracks progress with baseline metrics

**Agent:** Explore (forked)

---

### impact-narrative

**Trigger phrases:** "how do I explain this to leadership?", "what's the business impact?", "how do I write this for my perf review?"

**What it does:**
- Translates technical work to business outcomes
- Maps to impact types (revenue, cost, risk, velocity, scale, quality)
- Quantification framework
- Promotion-ready bullet formula
- STAR-L framework for narratives

**Agent:** Runs inline

---

### mental-model

**Trigger phrases:** "how does this work?", "what would break if I change this?", "help me understand this system"

**What it does:**
- 7-phase exploration methodology
- Maps core abstractions, data flow, invariants
- Documents lifecycle and extension points
- Identifies common pitfalls
- Change impact analysis

**Agent:** Explore (forked, with Read/Grep/Glob)

---

### promotion-draft

**Trigger phrases:** "am I ready for promotion?", "what does senior/staff look like?", "help me write my promo doc"

**What it does:**
- Level expectations framework (L3→L7)
- Key dimensions by level transition
- Promotion packet structure
- Evidence gathering from git and Dev OS
- Self-assessment checklists

**Agent:** Runs inline

---

### refactor-safely

**Trigger phrases:** "how do I safely change this?", "what's the safest way to restructure?"

**What it does:**
- Safety preconditions (test coverage thresholds)
- Refactoring patterns (Mikado Method, Strangler Fig)
- Atomic commit sequences
- Validation checkpoints
- Rollback strategies by level

**Agent:** Plan (forked)

---

### risk-audit

**Trigger phrases:** "what could go wrong?", "is this safe to ship?", "what are the failure modes?"

**What it does:**
- 5 risk categories (data, availability, security, integration, operational)
- FMEA framework (Severity × Occurrence × Detection = RPN)
- Silent failure detection with grep patterns
- Edge case matrix
- Production readiness checklist

**Agent:** Explore (forked)

---

### root-cause

**Trigger phrases:** "why did this happen?", "what's the root cause?", "why did this break?"

**What it does:**
- Severity classification (SEV1-4)
- Timeline construction with evidence sources
- 5 Whys technique
- Contributing factor matrix
- Detection gap analysis
- Prioritized action items

**Agent:** Explore (forked, with Read/Grep/Glob)

---

### standup

**Trigger phrases:** "standup", "daily standup", "what did I do yesterday", "standup summary", "/standup"

**What it does:**
- Aggregates dev-os events from yesterday
- Generates standup format: Yesterday (completed, sessions, decisions), Today (priorities), Blockers
- Identifies friction patterns and incomplete work
- Sources data from `~/.claude/dev-os-events.jsonl`
- Fetches GitHub PR activity via `gh` CLI (if authenticated):
  - PRs opened/merged yesterday
  - PRs awaiting your review

**Agent:** Runs inline

**Scripts:**
- `aggregate-standup.sh` - Collects daily events and GitHub PR data

---

### template-context

**Trigger phrases:** "testing Rails generators", "ERB coverage", "template branch coverage", "SimpleCov showing 0%", "untestable template logic"

**What it does:**
- Guides extraction of ERB conditionals into a TemplateContext PORO
- Provides implementation steps and code templates
- Ensures SimpleCov can instrument all branch logic
- Documents file structure and naming conventions

**Agent:** Runs inline

**Related:** ADR-0007 (full decision record)

---

### tradeoff-memo

**Trigger phrases:** "why did we choose this?", "document this decision", "what were the tradeoffs?"

**What it does:**
- Staff-level writing characteristics
- Options comparison framework
- Common tradeoff dimensions
- Principles library (engineering, architectural, organizational)
- Dev OS event integration

**Agent:** Runs inline

---

### weekly-review

**Trigger phrases:** "how was my week?", "generate weekly review", "what did I accomplish?", "/weekly-review"

**What it does:**
- Aggregates dev-os-events across ALL projects
- Generates summary.json with metrics
- Renders charts and HTML dashboard
- Fills placeholders with AI synthesis:
  - Executive summary
  - Friction analysis
  - Promotion-ready bullets
  - Precision moves

**Agent:** general-purpose (forked, with full tool access)

**Scripts:**
- `aggregate.sh` - Collects and summarizes events
- `charts.py` - Generates visualizations
- `render_md.sh` - Creates markdown template
- `render_dashboard.py` - Builds HTML dashboard

---

## Directory Structure

```
skills/
└── common/                     # Shared across all profiles
    ├── abstraction-check/
    │   └── SKILL.md
    ├── api-conventions/
    │   └── SKILL.md
    ├── weekly-review/
    │   ├── SKILL.md
    │   ├── CONTRACTS.md        # Interface contracts
    │   └── scripts/
    │       ├── aggregate.sh
    │       ├── charts.py
    │       ├── render_md.sh
    │       └── render_dashboard.py
    └── ... (18 more skills)
```

## Creating a New Skill

1. **Create directory:**
   ```bash
   mkdir -p home/.claude/skills/common/my-skill
   ```

2. **Create SKILL.md:**
   ```markdown
   ---
   name: my-skill
   description: This skill should be used when [trigger phrases]. Does [what it does].
   ---

   # My Skill

   [Skill content with methodology, templates, output format]
   ```

3. **Optional frontmatter fields:**
   ```yaml
   context: fork           # Run in forked context
   agent: Explore          # Use specific agent type
   allowed-tools:          # Restrict available tools
     - Read
     - Grep
   disable-model-invocation: true  # For non-conversational skills
   user-invocable: false   # Passive skill (auto-loaded only)
   ```

4. **Install:**
   ```bash
   mise run claude:refresh
   ```

## Best Practices

### Description Writing

Good descriptions include:
- Trigger phrases ("when asking X", "when doing Y")
- Third-person language ("This skill should be used when...")
- Specific scenarios, not vague purposes

### Content Structure

- Lead with methodology/steps
- Include decision frameworks or flowcharts
- Provide templates for output
- Add examples where helpful

### Progressive Disclosure

For complex skills:
- Keep SKILL.md focused (under 3000 words)
- Put detailed docs in `references/`
- Put code examples in `examples/`
- Put utility scripts in `scripts/`
