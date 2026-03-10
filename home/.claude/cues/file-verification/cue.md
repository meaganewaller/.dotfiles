---
pattern: (file|path|directory|folder).*(exist|missing|check|verify|read|write|create|delete|move|copy)|(read|write|create|delete|move|copy|check|verify).*(file|path|directory|folder)|ENOENT|not.?found|no.?such.*(file|directory)
commands: touch|mkdir|rm|mv|cp|cat|ls
files: ["*.sh", "*.rb", "*.py", "*.ts", "*.js"]
scope: agent, subagent
description: Verify-then-act pattern for file operations
vocabulary: path exists readable writable directory file glob verify check
provenance:
  policy:
    - uri: home/.claude/governance/policies/reliability.md
      type: governance-doc
  controls:
    - id: FILE-001
      name: Path Verification Before Action
      justifications:
        - 682 file-not-found errors indicate systematic verification gaps
        - Verify-then-act prevents wasted tool calls and user frustration
    - id: FILE-002
      name: Absolute Path Requirement
      justifications:
        - Relative paths break when working directory changes
        - Absolute paths are unambiguous and reproducible
---

# File Verification Checklist

**Before ANY file operation, verify:**

```
1. PATH IS ABSOLUTE    →  Starts with / (not relative)
2. TARGET EXISTS       →  Use Glob to confirm file/directory exists
3. PERMISSIONS OK      →  Can read (for Read), can write to parent (for Write/Edit)
```

## Quick Verification Patterns

### Before Reading a File
```
# WRONG: Assume file exists
Read("/path/to/file.rb")

# RIGHT: Verify first with Glob
Glob("**/file.rb")           # Find the actual path
Read("/actual/path/file.rb") # Use confirmed path
```

### Before Writing/Creating
```
# WRONG: Write to assumed directory
Write("/path/to/new/file.rb", content)

# RIGHT: Verify parent exists
Glob("**/to/")               # Confirm parent directory
Write("/path/to/new/file.rb", content)
```

### Before Editing
```
# WRONG: Edit file you haven't read
Edit("/path/to/file.rb", old, new)

# RIGHT: Read first (required by Edit tool anyway)
Read("/path/to/file.rb")     # Confirms existence + gets content
Edit("/path/to/file.rb", old, new)
```

## Common Failure Patterns

| Error | Cause | Prevention |
|-------|-------|------------|
| `file not found` | Path doesn't exist | Glob before Read |
| `no such directory` | Parent missing | Glob for parent before Write |
| `permission denied` | Can't write | Check if path is in allowed directories |
| `ENOENT` | Any path component missing | Verify full path with Glob |

## Shell Script Utilities

When writing shell scripts, use the validation utilities from `validate-path.sh`:

```bash
source "$HOME/.claude/hooks/common/validate-path.sh"

# Validation (returns 0/1, never exits)
validate_file_exists "/path/to/file"
validate_file_readable "/path/to/file"
validate_file_writable "/path/to/file"
validate_dir_exists "/path/to/dir"

# Ensure (creates if needed)
ensure_dir_exists "/path/to/dir"
ensure_file_exists "/path/to/file"
```

## Mental Model

```
           ┌─────────────┐
           │  VERIFY     │  ← Glob, Read, ls
           └──────┬──────┘
                  │ exists?
           ┌──────▼──────┐
           │  THEN ACT   │  ← Write, Edit, Bash
           └─────────────┘
```

**The 3-second rule:** If you're about to operate on a path you haven't verified in the last 3 tool calls, verify it again.
