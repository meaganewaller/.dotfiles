# Dev OS Telemetry Architecture

Visual guide to how development activity becomes weekly insights.

---

## The Big Picture

Your coding activity flows through three stages:

```mermaid
flowchart LR
    A[Daily Work] --> B[Event Capture]
    B --> C[Weekly Review]
    C --> D[Actionable Insights]
```

---

## Part 1: Event Capture

### How Events Are Created

Every tool use triggers a hook that emits an event:

```mermaid
flowchart LR
    A[You edit a file] --> B[PostToolUse hook]
    B --> C[dev-os-emit.sh]
    C --> D[(events.jsonl)]
```

### The Central Event Stream

All events flow to one file:

```mermaid
flowchart TB
    H1[impact-extractor] --> E[(dev-os-events.jsonl)]
    H2[skill-gap-detector] --> E
    H3[async-test-runner] --> E
    H4[large-diff-escalator] --> E
    H5[task-gate] --> E
```

---

## Part 2: Event Types

### Code Change Events

```mermaid
flowchart LR
    subgraph triggers["When you..."]
        A[Edit file]
        B[Big change]
        C[Update deps]
        D[Delete code]
    end

    subgraph events["Event created"]
        E[tool_write]
        F[large_change]
        G[dependency_change]
        H[reversal]
    end

    A --> E
    B --> F
    C --> G
    D --> H
```

### Quality Signal Events

```mermaid
flowchart LR
    subgraph triggers["When..."]
        A[Tests run]
        B[Task done]
        C[Tool fails]
    end

    subgraph events["Event created"]
        D[test_run]
        E[task_completed]
        F[tool_failure]
    end

    A --> D
    B --> E
    C --> F
```

### Decision Events

```mermaid
flowchart LR
    subgraph triggers["When you..."]
        A[Explain tradeoffs]
        B[Share opinion]
    end

    subgraph events["Event created"]
        C[decision_tradeoff]
        D[prompt_opinion]
    end

    A --> C
    B --> D
```

---

## Part 3: Storage Layout

### Primary Log Files

```mermaid
flowchart TB
    subgraph home["~/.claude/"]
        A[dev-os-events.jsonl<br/>All events]
        B[impact-log.jsonl<br/>File changes]
        C[skill-friction-log.jsonl<br/>Errors]
    end
```

### Supporting Files

```mermaid
flowchart TB
    subgraph home["~/.claude/"]
        A["idea-vault.md<br/>Captured opinions"]
        B["learning-targets/<br/>Study guides"]
        C["session-summaries/<br/>Snapshots"]
        D["reviews/<br/>Weekly reports"]
    end
```

---

## Part 4: Event Schemas

### dev-os-events.jsonl

Each line contains:

```mermaid
flowchart LR
    subgraph event["Event Structure"]
        A[timestamp]
        B[session_id]
        C[event_type]
        D[payload]
    end
```

### impact-log.jsonl

Each line contains:

```mermaid
flowchart LR
    subgraph impact["Impact Entry"]
        A[timestamp]
        B[file_paths]
        C[change_type]
        D[skill_domains]
        E[risk_level]
    end
```

### skill-friction-log.jsonl

Each line contains:

```mermaid
flowchart LR
    subgraph friction["Friction Entry"]
        A[timestamp]
        B[tool_name]
        C[domain]
        D[subdomain]
        E[hints]
    end
```

---

## Part 5: Weekly Review Pipeline

### Pipeline Overview

Four scripts run in sequence:

```mermaid
flowchart LR
    A[aggregate.sh] --> B[charts.py]
    B --> C[render_md.sh]
    C --> D[render_dashboard.py]
```

### Step 1: Aggregate

```mermaid
flowchart LR
    A[(events.jsonl)] --> B[aggregate.sh]
    B --> C[summary.json]
```

### Step 2: Visualize

```mermaid
flowchart LR
    A[summary.json] --> B[charts.py]
    B --> C[events_by_type.png]
    B --> D[friction_domains.png]
    B --> E[principles.png]
```

### Step 3: Template

```mermaid
flowchart LR
    A[summary.json] --> B[render_md.sh]
    B --> C[review.md<br/>with placeholders]
```

### Step 4: Render HTML

```mermaid
flowchart LR
    A[summary.json]
    B[review.md]
    C[charts/]

    A --> D[render_dashboard.py]
    B --> D
    C --> D
    D --> E[index.html]
```

### Step 5: AI Synthesis

```mermaid
flowchart LR
    A[Claude reads<br/>summary + review] --> B[Fills 6 placeholders]
    B --> C[Regenerates HTML]
```

---

## Part 6: Friction Taxonomy

### Top-Level Domains

```mermaid
flowchart TB
    F[Friction] --> A[syntax]
    F --> B[type]
    F --> C[dependency]
    F --> D[state]
    F --> E[permission]
    F --> G[network]
    F --> H[config]
    F --> I[testing]
    F --> J[build]
```

### State Subdomains

Most common friction type:

```mermaid
flowchart LR
    A[state] --> B[file-not-found]
    A --> C[resource-limit]
    A --> D[conflict]
    A --> E[command-failed]
```

### Dependency Subdomains

```mermaid
flowchart LR
    A[dependency] --> B[ruby-bundler]
    A --> C[node-npm]
    A --> D[rust-cargo]
    A --> E[python-module]
```

---

## Part 7: Hook Lifecycle

### Session Start

```mermaid
flowchart TB
    A[Claude starts] --> B[session-context-injector]
    B --> C[Inject recent impact/friction]
    A --> D[friction-escalator]
    D --> E[Warn if repeated errors]
```

### During Work

```mermaid
flowchart TB
    A[Edit file] --> B[impact-extractor]
    A --> C[large-diff-escalator]
    A --> D[reversal-detector]
    A --> E[async-test-runner]
```

### On Error

```mermaid
flowchart LR
    A[Tool fails] --> B[skill-gap-detector]
    B --> C[Classify error]
    C --> D[Log to friction file]
```

### Session End

```mermaid
flowchart TB
    A[Stop requested] --> B{Tests passing?}
    B -->|No| C[Block stop]
    B -->|Yes| D{Meaningful work?}
    D -->|No| E[Prompt for insight]
    D -->|Yes| F[Generate learnings]
```

---

## Related Documentation

- [Workflow Scenarios](./workflow-scenarios.md) - Common workflow examples
- [Hooks README](../hooks/README.md) - Hook implementation details
- [Weekly Review SKILL.md](../skills/common/weekly-review/SKILL.md) - Running reviews
