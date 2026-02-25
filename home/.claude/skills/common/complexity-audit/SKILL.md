---
name: complexity-audit
description: This skill should be used when asking "is this module too complex?", "why is this hard to change?", "what's causing coupling here?", or before refactoring a tangled system. Use to audit for accidental complexity, circular dependencies, god objects, and layering violations.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# Complexity Audit

Audit a module or system for accidental complexity and unnecessary coupling.

## Target

$ARGUMENTS

---

## Complexity Types & Detection

### 1. Circular Dependencies

**What:** A → B → C → A, creating a dependency cycle.

**Detection patterns:**
- Search for mutual requires/imports between modules
- Look for "forward declarations" or lazy requires (often hiding cycles)
- Check if deleting one file breaks seemingly unrelated files

**Grep patterns:**
```
# Find requires/imports, then trace the graph
require\s+['"].*module_name
import.*from\s+['"].*module_name
```

**Severity indicators:**
- 2 modules: Concerning
- 3+ modules: Dangerous
- Crosses package/layer boundaries: Dangerous

---

### 2. Cross-Layer Leakage

**What:** Higher layers reaching into lower layer internals, or lower layers knowing about higher layers.

**Expected layering:**
```
UI → Application → Domain → Infrastructure
     (each layer only depends on layers below)
```

**Detection patterns:**
- Controllers importing models directly (skipping service layer)
- Domain objects importing HTTP/database concerns
- Utility modules importing business logic

**Grep patterns:**
```
# Domain importing infrastructure
/models/.*import.*ActiveRecord
/domain/.*require.*redis

# UI importing domain internals
/views/.*import.*repository
/controllers/.*Repository
```

**Severity indicators:**
- Single violation: Concerning
- Pattern of violations: Dangerous
- Domain depends on infrastructure: Dangerous

---

### 3. Implicit State

**What:** Behavior depends on state that isn't passed explicitly.

**Detection patterns:**
- Global variables or module-level mutable state
- Thread-local storage
- Singletons with mutable state
- Methods that behave differently based on "current" context

**Grep patterns:**
```
# Ruby
@@\w+                    # Class variables
Thread\.current\[
\.instance\s*$           # Singleton access

# JavaScript
let\s+\w+\s*=.*module    # Module-level let
global\.
process\.env\.           # (when read deep in code, not at boundary)
```

**Severity indicators:**
- Read-only global config: Harmless
- Mutable global accessed in multiple places: Concerning
- State affects control flow: Dangerous

---

### 4. Hidden Invariants

**What:** Rules that must be true but aren't enforced or documented.

**Detection patterns:**
- Comments like "must be called after X" or "assumes Y"
- Defensive checks deep in call stack (should be at boundary)
- Tests that set up elaborate preconditions
- Bugs that only reproduce in specific sequences

**Grep patterns:**
```
# Warning comments
must.*call.*first
assumes?
# ?should.*never.*happen
don't.*change.*order
```

**Severity indicators:**
- Documented invariant: Harmless
- Undocumented but tested: Concerning
- Undocumented and untested: Dangerous

---

### 5. God Objects

**What:** Classes/modules that know too much or do too much.

**Detection patterns:**
- Files over 500 lines
- Classes with 20+ methods
- Objects passed to many unrelated functions
- Names like `Manager`, `Handler`, `Processor`, `Utils`, `Helper`

**Grep patterns:**
```
# Find large files
wc -l on target files

# Suspicious names
class.*Manager
class.*Handler
module.*Utils
```

**Metrics:**
| Metric | Concerning | Dangerous |
|--------|------------|-----------|
| Lines | >300 | >500 |
| Methods | >15 | >25 |
| Dependencies | >10 | >20 |
| Dependents | >10 | >20 |

---

### 6. Over-Configuration

**What:** Flexibility that adds complexity but isn't used.

**Detection patterns:**
- Config options with only one value across all environments
- Feature flags that are always on/off
- Abstract interfaces with single implementation
- Plugin systems with one plugin

**Grep patterns:**
```
# Config keys
\.get\(['"].*['"]\)
ENV\[['"].*['"]\]

# Then check: are multiple values ever used?
```

**Severity indicators:**
- Unused config option: Harmless (just delete it)
- Abstraction for one implementation: Concerning
- Framework for one use case: Dangerous

---

### 7. Temporal Coupling

**What:** Methods that must be called in a specific order without enforcement.

**Detection patterns:**
- `initialize()` / `setup()` methods that must be called first
- State machine without explicit states
- Sequences of calls that fail if reordered

**Grep patterns:**
```
def initialize
def setup
must.*initialize.*first
call.*before
```

**Severity indicators:**
- Two-step initialization: Concerning
- Multi-step sequences: Dangerous
- Order enforced only by convention: Dangerous

---

## Classification Criteria

| Rating | Criteria |
|--------|----------|
| **Harmless** | Isolated, understood, doesn't affect change velocity |
| **Concerning** | Causes friction, could become dangerous, should track |
| **Dangerous** | Actively causes bugs, blocks changes, creates incidents |

**Escalate to Dangerous if:**
- Affects critical path / revenue-generating features
- Has caused production incidents
- Multiple developers have been confused by it
- Blocks or slows unrelated changes

---

## Output Format

### Summary

| Complexity Type | Count | Worst Severity |
|-----------------|-------|----------------|
| Circular deps | X | Rating |
| Cross-layer | X | Rating |
| ... | ... | ... |

### Findings

#### [Type]: [Brief description]

**Location:** `path/to/file:line`

**Evidence:**
```
[relevant code snippet]
```

**Severity:** [Harmless / Concerning / Dangerous]

**Why:** [Explanation of impact]

**Suggested remediation:** [How to fix]

---

### Recommendations

1. **Immediate** (Dangerous findings): [List]
2. **Soon** (Concerning findings): [List]
3. **Backlog** (Harmless findings): [List]

### Complexity Score

| Rating | Count |
|--------|-------|
| Dangerous | X |
| Concerning | X |
| Harmless | X |

**Overall:** [Healthy / Needs attention / Critical]
