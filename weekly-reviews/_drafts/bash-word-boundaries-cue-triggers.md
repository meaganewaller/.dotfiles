---
title: "Why Your Bash Regex Word Boundaries Aren't Working"
date: 2026-03-11
layout: post
tags: [bash, regex, debugging, quick-tip, claude-code, posix, shell]
summary: "A regex pattern that should have matched file operations never fired once. The culprit: Bash’s `[[ =~ ]]` operator uses `POSIX ERE`, which doesn’t support `/b` word boundaries. A quick debugging story about regex portability and silent failures."
category: postmortems
---

# Why Your Bash Regex Word Boundaries Aren't Working

*A debugging story about cue triggers and regex portability*

## The Mystery: 0 Firings

During a weekly review of my Claude Code "Dev OS" setup, I noticed something odd: my `file-verification` cue had fired exactly **zero times** despite being configured to trigger on common file operation terms like "file", "path", "directory", "read", "write", and "create".

The pattern looked reasonable:

```yaml
pattern: \b(file|path|directory|folder|exists?|missing|not.?found|no.?such|ENOENT|read|write|edit|create|delete|move|copy)\b
```

But it never matched anything. Meanwhile, other cues with simpler patterns were firing dozens of times per week.

## The Investigation

The cue matching system uses bash's `[[ =~ ]]` regex operator:

```bash
match_regex() {
  local subject="$1"
  local regex="$2"
  [[ "$subject" =~ $regex ]] && return 0
  return 1
}
```

I tested the pattern directly:

```bash
test_pattern='\b(file|path|directory)\b'
subject="check if the file exists"
[[ "$subject" =~ $test_pattern ]] && echo "MATCH" || echo "NO MATCH"
# Output: NO MATCH
```

Then without word boundaries:

```bash
test_pattern='(file|path|directory)'
[[ "$subject" =~ $test_pattern ]] && echo "MATCH" || echo "NO MATCH"
# Output: MATCH
```

## The Root Cause

**Bash's `[[ =~ ]]` uses POSIX Extended Regular Expressions (ERE), which don't support `\b` word boundaries.**

This is a common gotcha when porting regex patterns between tools:

| Tool | Regex Flavor | `\b` Support |
|------|--------------|--------------|
| grep -E | POSIX ERE | No |
| grep -P | PCRE | Yes |
| sed | POSIX BRE | No |
| bash `[[ =~ ]]` | POSIX ERE | No |
| JavaScript | ECMA | Yes |
| Python `re` | PCRE-like | Yes |
| ripgrep | Rust regex | Yes |

The `\b` metacharacter is a Perl-Compatible Regular Expression (PCRE) feature. If you're used to writing regex in Python, JavaScript, or ripgrep, you'll naturally reach for `\b` - and it will silently fail in bash.

## The Fix

Instead of `\b`, simulate word boundaries with character class anchors:

```bash
# Before (broken in bash):
\badr\b

# After (works in bash):
(^|[^a-zA-Z])adr([^a-zA-Z]|$)
```

For my file-verification cue, I took a different approach - making the pattern match compound phrases in either direction:

```yaml
# Before (broken):
pattern: \b(file|path|directory|...)\b

# After (working):
pattern: (file|path|directory|folder).*(exist|missing|check|verify|read|write|create|delete|move|copy)|(read|write|create|delete|move|copy|check|verify).*(file|path|directory|folder)|ENOENT|not.?found|no.?such.*(file|directory)
```

This is more verbose but more intentional - it triggers on phrases like "read the file" or "verify the path exists" rather than any prompt containing the word "file".

## Detecting the Problem

If you're using bash regex and something isn't matching, check for:

1. **`\b` word boundaries** - won't work
2. **`\d` digit class** - use `[0-9]` instead
3. **`\w` word character** - use `[a-zA-Z0-9_]` instead
4. **`\s` whitespace** - use `[[:space:]]` instead

POSIX character classes like `[[:alpha:]]`, `[[:digit:]]`, and `[[:space:]]` are your friends in bash.

## Testing Your Patterns

Before deploying regex patterns in bash scripts, test them:

```bash
test_pattern='your|pattern|here'
test_cases=(
  "should match this"
  "and this too"
  "but not this"
)

for subject in "${test_cases[@]}"; do
  if [[ "$subject" =~ $test_pattern ]]; then
    echo "MATCH: $subject"
  else
    echo "NO MATCH: $subject"
  fi
done
```

## Lessons Learned

1. **Regex flavors matter** - patterns aren't portable between tools
2. **Silent failures are the worst** - the pattern didn't error, it just never matched
3. **Test patterns in isolation** - don't wait for production to find out
4. **Weekly reviews catch drift** - without checking firing rates, this would have gone unnoticed indefinitely

The file-verification cue now fires correctly, and I've added pattern testing to my cue development workflow.

---

*This post is part of a series on building a "Dev OS" with Claude Code hooks and cues. The system provides contextual guidance based on what you're working on - but only if the triggers actually work.*
