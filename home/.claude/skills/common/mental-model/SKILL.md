---
name: mental-model
description: This skill should be used before modifying unfamiliar code, when asking "how does this work?", "what would break if I change this?", "help me understand this system", or when onboarding to a new codebase. Builds comprehensive mental model with data flow, invariants, and change impact analysis.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# Mental Model Builder

Build a comprehensive mental model of a system before modifying it.

## Target System

$ARGUMENTS

---

## Exploration Methodology

### Phase 1: Orientation (Bird's Eye View)

**Goal:** Understand boundaries and entry points.

#### File Structure Scan
```bash
# Find main entry points
Glob: **/main.* **/index.* **/app.* **/*_controller.* **/server.*

# Find configuration
Glob: **/*.config.* **/config/**/* **/.env*

# Find tests (reveal intended behavior)
Glob: **/*_test.* **/*_spec.* **/test_*.* **/__tests__/**
```

#### Questions to Answer
- [ ] What's the entry point?
- [ ] What are the external boundaries (APIs, DBs, queues)?
- [ ] What's the deployment unit?

---

### Phase 2: Core Abstractions

**Goal:** Identify the key concepts and their relationships.

#### Discovery Patterns
```bash
# Find class/module definitions
Grep: "^class |^module |^interface |^type |^struct "

# Find main domain objects (often in models/ or domain/)
Glob: **/models/**/* **/domain/**/* **/entities/**/*

# Find service layer
Glob: **/services/**/* **/use_cases/**/* **/interactors/**/*
```

#### Document Each Abstraction

| Abstraction | Responsibility | Key Methods | Collaborators |
|-------------|---------------|-------------|---------------|
| [Name] | [Single sentence] | [Public API] | [What it talks to] |

#### Abstraction Diagram

```
┌─────────────┐     ┌─────────────┐
│ Abstraction │────▶│ Abstraction │
│     A       │     │     B       │
└─────────────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│ Abstraction │
│     C       │
└─────────────┘
```

---

### Phase 3: Data Flow

**Goal:** Trace how data moves through the system.

#### Flow Types to Map

| Flow Type | What to Trace |
|-----------|---------------|
| **Request** | External input → processing → response |
| **Event** | Trigger → handlers → side effects |
| **Background** | Job enqueue → processing → completion |
| **Data mutation** | Input → validation → transformation → persistence |

#### Discovery Patterns
```bash
# Find data entry points
Grep: "params\[|request\.|body\.|payload"

# Find persistence
Grep: "\.save|\.create|\.update|\.insert|\.write"

# Find external calls
Grep: "HTTP\.|fetch\(|client\.|api\."
```

#### Data Flow Diagram

```
[Input] ──▶ [Validation] ──▶ [Transform] ──▶ [Persist] ──▶ [Output]
                │                               │
                ▼                               ▼
           [Reject]                        [Side Effect]
```

---

### Phase 4: Invariants

**Goal:** Identify rules that must always be true.

#### Types of Invariants

| Type | Example | How to Find |
|------|---------|-------------|
| **Data** | "User must have email" | Validations, NOT NULL constraints |
| **State** | "Order can't ship if unpaid" | State machine guards, conditionals |
| **Relationship** | "Invoice belongs to one customer" | Foreign keys, association validations |
| **Timing** | "Created before updated" | Timestamp checks, sequencing |

#### Discovery Patterns
```bash
# Find validations
Grep: "validates|validate|assert|raise.*if|throw.*if"

# Find guards/preconditions
Grep: "unless|guard|require\(|precondition"

# Find constraints
Grep: "NOT NULL|UNIQUE|CHECK|FOREIGN KEY"
```

#### Document Invariants

| Invariant | Enforced Where | What Breaks If Violated |
|-----------|----------------|------------------------|
| [Rule] | [Location] | [Consequence] |

---

### Phase 5: Lifecycle

**Goal:** Understand how entities are created, change, and die.

#### State Machine (if applicable)

```
┌─────────┐    create    ┌─────────┐    activate    ┌─────────┐
│  None   │─────────────▶│ Pending │──────────────▶│ Active  │
└─────────┘              └─────────┘               └─────────┘
                              │                        │
                              │ reject                 │ cancel
                              ▼                        ▼
                         ┌─────────┐              ┌─────────┐
                         │Rejected │              │Cancelled│
                         └─────────┘              └─────────┘
```

#### Lifecycle Questions

- [ ] How is it created? (factory, constructor, API)
- [ ] What triggers state changes?
- [ ] What are the terminal states?
- [ ] Is there cleanup/garbage collection?
- [ ] What happens on failure mid-lifecycle?

---

### Phase 6: Extension Points

**Goal:** Identify where the system is designed to be extended.

| Extension Type | Pattern | Example |
|----------------|---------|---------|
| **Plugin** | Registry + interface | `register_handler(:type, MyHandler)` |
| **Hook** | Callback/event | `after_create :send_notification` |
| **Strategy** | Injected behavior | `Processor.new(strategy: CustomStrategy)` |
| **Configuration** | External values | `config.feature_enabled = true` |
| **Inheritance** | Base class | `class MyWorker < BaseWorker` |

#### Discovery Patterns
```bash
# Find hooks/callbacks
Grep: "after_|before_|on_|hook|callback|subscribe|listen"

# Find registries
Grep: "register|registry|plugin|handler"

# Find dependency injection
Grep: "inject|provide|@inject|constructor.*service"
```

---

### Phase 7: Common Pitfalls

**Goal:** Identify where previous developers have struggled.

#### Discovery Patterns
```bash
# Find TODOs and FIXMEs
Grep: "TODO|FIXME|HACK|XXX|WORKAROUND"

# Find commented-out code (often indicates confusion)
Grep: "^\\s*#.*def |^\\s*//.*function"

# Find error handling (reveals failure modes)
Grep: "rescue|catch|except|on_error"
```

#### Pitfall Categories

| Category | Warning Signs |
|----------|---------------|
| **Concurrency** | Locks, mutexes, "thread-safe" comments |
| **Performance** | N+1 queries, loops over large data |
| **Error handling** | Swallowed exceptions, generic rescues |
| **State** | Mutable globals, singletons, caches |
| **Timing** | Sleep calls, polling loops, race conditions |

---

## Change Impact Analysis

### For Any Proposed Change, Analyze:

#### Direct Impact
| Question | Analysis |
|----------|----------|
| What files change? | [list] |
| What tests cover this? | [list] |
| What invariants could break? | [list] |

#### Indirect Impact
| Question | Analysis |
|----------|----------|
| What depends on this? (downstream) | [list] |
| What does this depend on? (upstream) | [list] |
| What caches/denormalizations exist? | [list] |

#### Risk Assessment

```
┌─────────────────────────────────────────┐
│ Change: [description]                   │
├─────────────────────────────────────────┤
│ Direct impact:     [Low/Med/High]       │
│ Indirect impact:   [Low/Med/High]       │
│ Invariant risk:    [Low/Med/High]       │
│ Rollback ease:     [Easy/Medium/Hard]   │
├─────────────────────────────────────────┤
│ Overall risk:      [Low/Med/High]       │
└─────────────────────────────────────────┘
```

---

## Output Format

### System Overview

[2-3 sentence summary of what this system does]

### Core Abstractions

| Abstraction | Responsibility | Key Collaborators |
|-------------|----------------|-------------------|
| [name] | [purpose] | [dependencies] |

[Diagram]

### Data Flow

[Flow diagram with narrative explanation]

### Key Invariants

| Invariant | Enforced By | Violation Impact |
|-----------|-------------|------------------|
| [rule] | [mechanism] | [consequence] |

### Lifecycle

[State diagram if applicable, or lifecycle narrative]

### Extension Points

| Point | Type | How to Extend |
|-------|------|---------------|
| [name] | [pattern] | [instructions] |

### Known Pitfalls

| Pitfall | Location | Mitigation |
|---------|----------|------------|
| [issue] | [where] | [how to avoid] |

### Change Impact: "If I change X..."

| Change | Breaks | Requires |
|--------|--------|----------|
| [component] | [dependencies] | [updates needed] |
