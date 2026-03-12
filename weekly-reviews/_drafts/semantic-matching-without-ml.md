---
title: "Quick Tip: Semantic Matching Without ML (Just Gzip)"
date: 2026-03-10
status: draft
tags: [claude-code, developer-tools, quick-tip, algorithms, text-matching]
---

# Quick Tip: Semantic Matching Without ML (Just Gzip)

I needed to match user prompts to contextual cues. Regex works for obvious cases—"commit" triggers the commit cue—but what about fuzzy matches? "push my changes" should probably trigger the same cue, but writing regex for every variation is a losing game.

The obvious solution is embeddings. Compute vectors, calculate cosine similarity, done. But that means API calls, latency, and infrastructure I didn't want.

Then I remembered a trick from information theory: **similar texts compress well together**.

## The Insight: Compression as Similarity

Compression algorithms find patterns. If two pieces of text share patterns (words, phrases, structure), compressing them together produces a smaller result than compressing them separately.

This is formalized as **Normalized Compression Distance (NCD)**:

```
NCD(a, b) = (C(a+b) - min(C(a), C(b))) / max(C(a), C(b))
```

Where `C(x)` is the compressed size of `x`.

- NCD ≈ 0: Nearly identical (compress perfectly together)
- NCD ≈ 1: Completely different (no shared patterns)
- NCD < 0.6: Semantically similar (good threshold for matching)

The beautiful part: this works with *any* compression algorithm. I used gzip because it's everywhere.

## Real Examples

```bash
# Similar - both about software design
NCD("software design", "design the database schema") ≈ 0.52 ✓

# Different - "design" means different things
NCD("software design", "button design looks off") ≈ 0.63 ✗

# Similar - same domain, different words
NCD("commit my changes", "push code to repo") ≈ 0.55 ✓

# Similar - security context
NCD("check auth token", "validate session") ≈ 0.54 ✓
```

The algorithm doesn't know what these words *mean*. It just knows they share compression patterns—and that's often enough.

## The Implementation

~50 lines of bash:

```bash
#!/usr/bin/env bash
set -euo pipefail

QUERY="$1"
DESCRIPTION="$2"
THRESHOLD="${NCD_THRESHOLD:-0.65}"

# Normalize: lowercase, collapse whitespace
normalize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' '
}

# Get compressed size
compressed_size() {
  echo -n "$1" | gzip -c | wc -c | tr -d ' '
}

NORM_QUERY=$(normalize "$QUERY")
NORM_DESC=$(normalize "$DESCRIPTION")

SIZE_QUERY=$(compressed_size "$NORM_QUERY")
SIZE_DESC=$(compressed_size "$NORM_DESC")
SIZE_BOTH=$(compressed_size "$NORM_QUERY $NORM_DESC")

# Calculate NCD
if [[ $SIZE_QUERY -lt $SIZE_DESC ]]; then
  MIN=$SIZE_QUERY; MAX=$SIZE_DESC
else
  MIN=$SIZE_DESC; MAX=$SIZE_QUERY
fi

NCD=$(awk -v ab="$SIZE_BOTH" -v min="$MIN" -v max="$MAX" \
  'BEGIN { printf "%.4f", (ab - min) / max }')

# Check threshold
awk -v ncd="$NCD" -v t="$THRESHOLD" 'BEGIN { exit (ncd < t) ? 0 : 1 }'
```

Exit code 0 = match, 1 = no match. Simple.

## How I Use It

My cue system has three matching tiers:

1. **Regex** (fast, precise): `pattern: commit|push|merge`
2. **Vocabulary** (fast, keyword): `vocabulary: git commit push merge branch`
3. **Semantic** (slower, fuzzy): `description: Version control operations`

The semantic matcher is a fallback. If regex misses and vocabulary doesn't hit, NCD checks whether the prompt is semantically similar to the cue's description.

```yaml
# cue.md frontmatter
pattern: commit|push|merge
description: Version control operations for saving and sharing code changes
vocabulary: git commit push merge branch tag release deploy
```

A prompt like "save my work to the remote" won't match the regex or vocabulary, but NCD against "Version control operations for saving and sharing code changes" returns ~0.52—close enough to trigger.

## Boosting Accuracy with Vocabulary

Raw NCD on short queries can be noisy. The fix: append domain vocabulary to the description before comparing.

```bash
COMBINED="$DESCRIPTION $VOCABULARY"
SIZE_DESC=$(compressed_size "$(normalize "$COMBINED")")
```

Now "push changes" compresses well with "Version control operations git commit push merge branch"—the shared "push" creates pattern overlap that tips NCD under threshold.

This hybrid approach gets most of the benefit of embeddings with none of the infrastructure:

| Approach | Latency | Infrastructure | Accuracy |
|----------|---------|---------------|----------|
| Regex only | <1ms | None | Brittle |
| Embeddings | 50-200ms | API/Model | High |
| NCD + vocab | 2-5ms | None (just gzip) | Good enough |

## Limitations

NCD isn't magic:

- **Short texts**: Very short queries have high variance. "fix" vs "bug" might not match well even though they're related.
- **No world knowledge**: It can't know that "PR" and "pull request" are synonyms unless they appear together in vocabulary.
- **Language-dependent**: Works best for English; other languages may need different thresholds.

For my use case—triggering contextual cues—these limitations are fine. I'm not building a search engine. I just need "pretty good" matching that runs locally in milliseconds.

## Try It

The full script is in my dotfiles, but the core is just those 50 lines. If you need fuzzy text matching and don't want to spin up ML infrastructure, NCD might be exactly what you need.

Tune the threshold based on your false positive tolerance:
- 0.55: Strict (fewer matches, higher precision)
- 0.65: Balanced (default)
- 0.75: Loose (more matches, lower precision)

The algorithm is from a 2004 paper by Cilibrasi and Vitányi, "Clustering by Compression." The insight that compression approximates Kolmogorov complexity—and thus semantic similarity—is one of those ideas that's obvious in retrospect and delightful in practice.

---

*Implementation: `~/.claude/hooks/semantic-match.sh`. Used by the cue system in `match-cues.sh`. Part of the [Dev OS dotfiles](https://github.com/meaganewaller/.dotfiles).*
