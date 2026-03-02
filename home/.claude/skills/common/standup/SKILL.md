# Standup Skill

This skill should be used when the user asks for "standup", "daily standup", "what did I do yesterday", "what should I work on today", "standup summary", or at the start of a workday.

## Trigger Phrases
- "standup"
- "daily standup"
- "what did I do yesterday"
- "what did I accomplish"
- "standup summary"
- "morning standup"
- "start of day"

## How to Use

When this skill is invoked:

1. Run the standup aggregation script:
   ```bash
   bash ~/.claude/skills/standup/scripts/aggregate-standup.sh
   ```

2. Read the generated summary from the script output

3. Present the standup in this format:

```markdown
# Daily Standup — [Date]

## Yesterday
[Summary of work from dev-os events]

### Completed
- [Files modified with context]
- [Decisions made]

### Sessions
- [Number of sessions, total duration]

## Today
[Based on incomplete work, pending items, and patterns]

### Priorities
1. [Most important item based on yesterday's work]
2. [Follow-up items]
3. [Unfinished work]

## Blockers
[Any friction patterns or issues identified]

## Notes
[Any relevant context for the team]
```

## Data Sources

The standup aggregates from:
- `~/.claude/dev-os-events.jsonl` - All dev-os events
- Session duration data
- Friction patterns
- Decision tradeoffs documented

## Standup Questions

If the script output is insufficient, ask:
1. What were you working on yesterday?
2. What's the most important thing to accomplish today?
3. Are there any blockers?

## Example Output

```markdown
# Daily Standup — March 2, 2026

## Yesterday

### Completed
- Implemented tradeoff auto-capture system (3 files, 150 lines)
- Updated weekly review aggregation for session duration tracking
- Fixed marker expiry from 1h to 24h for long sessions

### Sessions
- 2 sessions, 4.5 hours total
- 1 context compaction (long session)

### Decisions Made
- Chose auto-capture over blocking for tradeoff documentation
- Extended marker expiry to support full-day sessions

## Today

### Priorities
1. Test the auto-capture agent hook in real usage
2. Continue Phase 2 of Dev OS enhancements
3. Review weekly data for friction patterns

## Blockers
- None identified

## Notes
- High Read tool failure rate (789 failures) needs investigation
- Consider adding diagnostic logging to skill-gap-detector
```

## Tips

- Run standup at the start of your day to plan effectively
- Use standup output as commit message context
- Share standup in team channels for visibility
- Review weekly to see productivity patterns
