# Efficiency Principles

Actionable principles for working within resource constraints. Apply these when hitting limits or optimizing for scale.

## Resource-Aware Operations

### File Size Awareness

**Core insight:** Large files require chunked access strategies, not brute-force reads.

- Check file size before reading (use `ls -la` or stat)
- For files > 256KB: use `offset`/`limit` parameters or grep for specific content
- Session logs, JSONL files, and large configs are common offenders
- Prefer grep to find relevant sections, then read targeted ranges

**Anti-pattern:** Repeatedly attempting to read a large file without parameters.

### Context Window Economy

**Core insight:** Context is finite and expensive. Spend it wisely.

- Use task lists for multi-step work—they survive compaction
- Summarize findings before context fills up
- Prefer targeted searches (Grep/Glob) over broad exploration
- Delegate research to subagents to protect main context

**Heuristic:** If you've made 3+ searches without finding what you need, use the Explore agent.

### Caching and Memoization

**Core insight:** Avoid repeating expensive operations within a session.

- Session markers (`/tmp/.claude-*`) prevent redundant work
- Check for cached results before re-computing
- Emit events once, not on every iteration
- Use early exits when preconditions aren't met

**Anti-pattern:** Re-reading the same large file multiple times in one session.

---

## Scalable Data Access

### Progressive Loading

**Core insight:** Start small, expand only if needed.

- First: grep for keywords to locate relevant sections
- Then: read specific line ranges around matches
- Finally: read full file only if truly necessary

**Example flow:**
```bash
# Step 1: Find where errors occur
grep "error" file.log

# Step 2: Read context around specific match
Read file.log --offset 1000 --limit 50
```

### Streaming Over Batching

**Core insight:** Process data incrementally when possible.

- For JSONL: grep specific event types, don't read entire file
- For logs: tail recent entries, don't load full history
- For large directories: glob with specific patterns, don't list all

---

## Quick Reference

### When hitting file size limits:
1. Use grep to find relevant content first
2. Read with offset/limit for targeted sections
3. Consider if you really need the full file

### When context is filling up:
1. Create a task list to preserve state
2. Summarize findings in memory files
3. Delegate exploration to subagents

### When operations feel slow:
1. Check for redundant reads/searches
2. Add early exits for common cases
3. Use markers to skip completed work

---

## Signals This Applies

Invoke these principles when you see:
- `resource-limit` friction events
- "File exceeds maximum allowed size" errors
- Context threshold warnings
- Repeated failed reads of the same file
