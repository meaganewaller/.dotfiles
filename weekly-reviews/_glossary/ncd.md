---
layout: glossary-term
term: NCD (Normalized Compression Distance)
short: Compression-based semantic similarity metric
category: algorithm
related:
  - cue
  - trigger
  - friction-taxonomy
aliases:
  - normalized compression distance
  - compression distance
  - gzip similarity
---

A metric for measuring semantic similarity between texts using compression algorithms. Used in Dev OS for fuzzy matching of prompts to cues without requiring ML infrastructure.

## The Formula

```
NCD(a, b) = (C(a+b) - min(C(a), C(b))) / max(C(a), C(b))
```

Where `C(x)` is the compressed size of text `x`.

## Interpretation

| NCD Value | Meaning |
|-----------|---------|
| 0.0 | Identical (compress perfectly together) |
| < 0.55 | Highly similar |
| 0.55 - 0.65 | Similar (threshold range for matching) |
| > 0.65 | Different |
| ~1.0 | Completely unrelated |

## Why It Works

Compression algorithms (like gzip) find patterns in text. Similar texts share patterns—common words, phrases, and structures. When compressed together, these shared patterns compress efficiently, resulting in a smaller combined size relative to compressing each text separately.

This insight comes from information theory: compression approximates Kolmogorov complexity, which measures the "information content" of data. Similar texts have similar information content.

## Implementation

Dev OS uses a ~50 line bash script (`semantic-match.sh`):

```bash
# Normalize text
normalize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' '
}

# Get compressed size using gzip
compressed_size() {
  echo -n "$1" | gzip -c | wc -c
}

# Calculate NCD
SIZE_QUERY=$(compressed_size "$QUERY")
SIZE_DESC=$(compressed_size "$DESCRIPTION")
SIZE_BOTH=$(compressed_size "$QUERY $DESCRIPTION")

NCD=$(awk -v ab="$SIZE_BOTH" -v min="$MIN" -v max="$MAX" \
  'BEGIN { printf "%.4f", (ab - min) / max }')
```

## Use in Cue Matching

The cue system uses NCD as a fallback when regex patterns don't match:

1. **Primary**: Regex match against `pattern:` field
2. **Secondary**: Keyword match against `vocabulary:` field
3. **Tertiary**: NCD match against `description:` field

This allows fuzzy matching without external API calls:

```yaml
# cue.md frontmatter
pattern: commit|push|merge
vocabulary: git commit push merge branch
description: Version control operations for saving code
```

A prompt like "save my work to remote" won't hit regex or vocabulary, but NCD against the description returns ~0.52—triggering the cue.

## Boosting with Vocabulary

Short queries produce noisy NCD scores. Adding vocabulary keywords improves accuracy:

```bash
COMBINED="$DESCRIPTION $VOCABULARY"
SIZE_DESC=$(compressed_size "$COMBINED")
```

The query "push changes" now compresses well with "Version control operations git commit push merge"—shared "push" creates pattern overlap.

## Performance Characteristics

| Aspect | Value |
|--------|-------|
| Latency | 2-5ms per comparison |
| Dependencies | None (just gzip) |
| Accuracy | Good for semantic grouping |
| Best for | Short-to-medium text comparison |

## Limitations

- **Short texts**: High variance on very short queries (< 10 characters)
- **No synonyms**: Can't know "PR" = "pull request" without vocabulary hints
- **Language bias**: Tuned for English; other languages may need different thresholds
- **Not precise**: Better for "good enough" matching than exact similarity

## Academic Background

NCD was introduced by Cilibrasi and Vitányi in "Clustering by Compression" (2004). The key insight: any standard compression algorithm approximates the theoretical Kolmogorov complexity, making compression a universal similarity metric.

The paper demonstrated NCD successfully clustering:
- Music by genre
- Languages by family
- Texts by author

## Configuration

The threshold can be tuned via environment variable:

```bash
NCD_THRESHOLD=0.55  # Stricter matching
NCD_THRESHOLD=0.65  # Default
NCD_THRESHOLD=0.75  # Looser matching
```

## Example Comparisons

```
NCD("software design", "database schema design")     = 0.52 (match)
NCD("software design", "button looks wrong")         = 0.63 (no match)
NCD("fix the bug", "debug the issue")                = 0.54 (match)
NCD("commit changes", "push to remote")              = 0.55 (match)
NCD("add feature", "remove unused code")             = 0.61 (borderline)
```

## See Also

- [Clustering by Compression (Paper)](https://arxiv.org/abs/cs/0312044)
- `~/.claude/hooks/semantic-match.sh` - Implementation
- `~/.claude/hooks/match-cues.sh` - Usage in cue matching
