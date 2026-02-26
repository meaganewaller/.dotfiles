# Dev OS Workflow Scenarios

How telemetry captures data during common development activities.

---

## Scenario 1: Feature Development

### Starting Your Session

```mermaid
flowchart LR
    A[Launch Claude] --> B[Check friction log]
    B --> C{Repeated errors?}
    C -->|Yes| D[Show reminder]
    C -->|No| E[Normal start]
```

### Writing Code

Each file edit creates an event:

```mermaid
flowchart LR
    A[Edit service.rb] --> B[tool_write event]
    B --> C[Classified as:<br/>skill: app development]
```

### Auto-Classification

The system guesses what kind of work you're doing:

```mermaid
flowchart TB
    A[File path] --> B{Contains test/spec?}
    B -->|Yes| C[change_type: test]
    B -->|No| D{Contains config?}
    D -->|Yes| E[change_type: infra]
    D -->|No| F[change_type: refactor]
```

### Risk Assessment

```mermaid
flowchart TB
    A[Diff content] --> B{class/module/def?}
    B -->|Yes| C[risk: medium<br/>change_type: architecture]
    B -->|No| D[risk: low]
```

---

## Scenario 2: Large Changes

### Detection

```mermaid
flowchart LR
    A[Edit file] --> B[git diff --shortstat]
    B --> C{lines > 250?}
    C -->|Yes| D[large_change event]
    C -->|No| E[No action]
```

### Prompted Response

```mermaid
flowchart TB
    A[large_change detected] --> B[System message:<br/>'Document tradeoffs']
    B --> C[You explain reasoning]
    C --> D[SubagentStop extracts]
    D --> E[decision_tradeoff event]
```

### What Gets Captured

```mermaid
flowchart LR
    subgraph decision["decision_tradeoff"]
        A[summary]
        B[tradeoffs]
        C[options]
        D[principles]
    end
```

---

## Scenario 3: Debugging Errors

### Error Classification

```mermaid
flowchart LR
    A[Tool fails] --> B[skill-gap-detector]
    B --> C[Match error patterns]
    C --> D[Assign domain]
```

### Common: File Not Found

```mermaid
flowchart LR
    A[Error: No such file] --> B[domain: state]
    B --> C[subdomain: file-not-found]
    C --> D[hint: Check path exists]
```

### Common: Resource Limit

```mermaid
flowchart LR
    A[Error: File too large] --> B[domain: state]
    B --> C[subdomain: resource-limit]
    C --> D[hint: Use offset/limit]
```

### Pattern Detection

After multiple similar errors:

```mermaid
flowchart LR
    A[3+ same domain] --> B[friction-escalator]
    B --> C[Next session shows:<br/>'Repeated state errors']
```

---

## Scenario 4: Running Tests

### Async Test Flow

```mermaid
flowchart LR
    A[Edit .rb/.ts/.js] --> B[async-test-runner]
    B --> C[Run tests in background]
    C --> D[test_run event]
```

### Test Results

```mermaid
flowchart LR
    A[Tests complete] --> B{Passed?}
    B -->|Yes| C[test_run: passed]
    B -->|No| D[test_run: failed]
    D --> E[Show warning]
```

### Stop Blocking

```mermaid
flowchart LR
    A[Try to stop] --> B{Last test passed?}
    B -->|No| C[Block: Fix tests first]
    B -->|Yes| D[Allow stop]
```

---

## Scenario 5: Completing Tasks

### Task Gate Checks

```mermaid
flowchart TB
    A[Mark task done] --> B[task-gate.sh]
    B --> C{RSpec passes?}
    C -->|No| D[Block]
    C -->|Yes| E{RuboCop passes?}
    E -->|No| D
    E -->|Yes| F[task_completed event]
```

### What Gets Checked

```mermaid
flowchart LR
    A[task-gate] --> B[Tests]
    A --> C[Linting]
    A --> D[Migrations]
    A --> E[Docs]
```

---

## Scenario 6: Dependency Updates

### Detection

```mermaid
flowchart LR
    A[Edit Gemfile] --> B[dependency-change-detector]
    B --> C[Count added/removed]
    C --> D[dependency_change event]
```

### Tracked Files

```mermaid
flowchart TB
    A[dependency-change-detector] --> B[Gemfile]
    A --> C[package.json]
    A --> D[Cargo.toml]
    A --> E[requirements.txt]
```

---

## Scenario 7: Code Reversals

### Detection

```mermaid
flowchart LR
    A[Edit file] --> B[Count +/- lines]
    B --> C{removed > 50?}
    C -->|Yes| D{removed > added?}
    D -->|Yes| E[reversal event]
```

### Why Track This

```mermaid
flowchart LR
    A[Reversal detected] --> B[Likely exploration<br/>being undone]
    B --> C[Weekly review flags it]
```

---

## Scenario 8: End of Session

### Learning Generation

```mermaid
flowchart LR
    A[Session ends] --> B[learning-suggestion-generator]
    B --> C[Read impact log]
    B --> D[Read friction log]
    C --> E[learning-targets/latest.md]
    D --> E
```

### What's Generated

```mermaid
flowchart TB
    A[latest.md] --> B[Where you're bleeding<br/>Top friction domains]
    A --> C[Where you're investing<br/>Top skill areas]
    A --> D[Precision moves<br/>Suggested actions]
```

---

## Scenario 9: Weekly Review

### Data Aggregation

```mermaid
flowchart LR
    A[7 days of events] --> B[aggregate.sh]
    B --> C[summary.json]
```

### Key Metrics Computed

```mermaid
flowchart TB
    A[summary.json] --> B[Total writes]
    A --> C[Total failures]
    A --> D[Friction domains]
    A --> E[Principles invoked]
    A --> F[Test stability]
```

### AI Analysis

```mermaid
flowchart LR
    A[summary.json] --> B[Claude analyzes]
    B --> C[Executive summary]
    B --> D[Friction analysis]
    B --> E[Impact bullets]
    B --> F[Precision moves]
```

---

## Summary: What Gets Captured

| You Do This | Event Created | Shows Up In |
|-------------|---------------|-------------|
| Edit file | tool_write | Writes count |
| Big edit (>250 lines) | large_change | Discipline flags |
| Update deps | dependency_change | Churn tracking |
| Delete lots of code | reversal | Reversal count |
| Tool fails | tool_failure | Friction analysis |
| Run tests | test_run | Test stability |
| Complete task | task_completed | Tasks count |
| Explain tradeoff | decision_tradeoff | Principles invoked |

---

## Related Documentation

- [Telemetry Architecture](./telemetry-architecture.md) - System design
- [Hooks README](../hooks/README.md) - Hook details
- [Weekly Review SKILL.md](../skills/common/weekly-review/SKILL.md) - Running reviews
