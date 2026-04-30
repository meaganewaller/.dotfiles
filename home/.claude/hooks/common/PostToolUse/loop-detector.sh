#!/usr/bin/env bash
set -euo pipefail

TEMP=${TEMP:-/tmp}
STATE="$TEMP/claude-progress-loop.json"
LOCKFILE="$STATE.lock"

WINDOW=25
ERROR_LOOP=3
FILE_THRASH=6
READ_LIMIT=15

INPUT=$(cat || echo "{}")

tool=$(jq -r '.tool_name // ""' <<<"$INPUT")
toolInput=$(jq '.tool_input // {}' <<<"$INPUT")
toolOutput=$(jq -r '.tool_output // ""' <<<"$INPUT")

load_state() {
  if [[ -f "$STATE" ]]; then
    jq '.' "$STATE"
  else
    jq -n '{
      history: [],
      progress: [],
      files: [],
      errors: [],
      reads: 0,
      writes: 0
    }'
  fi
}

save_state() {
  # Atomic write with temp file
  local tmpfile
  tmpfile=$(mktemp)
  echo "$1" > "$tmpfile"
  mv "$tmpfile" "$STATE"
}

extract_file() {
  jq -r '.file_path // .path // empty' <<<"$toolInput"
}

fingerprint_error() {
  local hash_cmd="md5sum"
  command -v md5sum >/dev/null 2>&1 || hash_cmd="md5"
  grep -iE "error|failed|exception|traceback" <<<"$toolOutput" \
    | head -n1 \
    | $hash_cmd \
    | cut -c1-10 || true
}

progress_signal() {

  local score=0

  # success signals
  if grep -qiE "passed|success|completed" <<<"$toolOutput"; then
    score=$((score+3))
  fi

  # failures
  if grep -qiE "failed|error|exception" <<<"$toolOutput"; then
    score=$((score-2))
  fi

  # file writes = progress
  if [[ "$tool" == "Write" || "$tool" == "Edit" ]]; then
    score=$((score+1))
  fi

  echo "$score"
}

file=$(extract_file)
error_fp=$(fingerprint_error)
progress=$(progress_signal)

# Use mkdir-based lock (cross-platform, works on macOS and Linux)
_lock_acquired=false
for _i in 1 2 3 4 5; do
  if mkdir "$LOCKFILE" 2>/dev/null; then
    _lock_acquired=true
    trap 'rmdir "$LOCKFILE" 2>/dev/null' EXIT
    break
  fi
  sleep 1
done
$_lock_acquired || { echo "Failed to acquire lock" >&2; exit 0; }

state=$(load_state)

# --- update progress window ---
state=$(jq --argjson p "$progress" '
.progress += [$p]
| if (.progress|length) > 25 then .progress = .progress[-25:] else . end
' <<<"$state")

# --- track file edits ---
if [[ -n "$file" ]]; then
  state=$(jq --arg f "$file" '
.files += [$f]
| if (.files|length) > 30 then .files = .files[-30:] else . end
' <<<"$state")
fi

# --- error fingerprints ---
if [[ -n "$error_fp" ]]; then
  state=$(jq --arg e "$error_fp" '
.errors += [$e]
| if (.errors|length) > 20 then .errors = .errors[-20:] else . end
' <<<"$state")
fi

# --- read/write tracking ---
if [[ "$tool" == "Read" ]]; then
  state=$(jq '.reads += 1' <<<"$state")
fi

if [[ "$tool" == "Write" || "$tool" == "Edit" ]]; then
  state=$(jq '.writes += 1' <<<"$state")
fi

save_state "$state"

# Release lock
rmdir "$LOCKFILE" 2>/dev/null
trap - EXIT

# ---------------------------------------------------
# LOOP DETECTION
# ---------------------------------------------------

progress_sum=$(jq '[.progress[]] | add' <<<"$state")

# 1. progress stagnation
if (( progress_sum <= 0 )); then
  echo "[LOOP WARNING] No measurable progress over last $WINDOW actions." >&2
fi

# 2. repeated errors
if [[ -n "$error_fp" ]]; then
  err_count=$(jq --arg e "$error_fp" '[.errors[] | select(.==$e)] | length' <<<"$state")

  if (( err_count >= ERROR_LOOP )); then
    echo "[LOOP WARNING] Same error repeating $err_count times." >&2
  fi
fi

# 3. file thrashing
if [[ -n "$file" ]]; then
  thrash=$(jq --arg f "$file" '[.files[] | select(.==$f)] | length' <<<"$state")

  if (( thrash >= FILE_THRASH )); then
    echo "[LOOP WARNING] File \"$file\" edited $thrash times recently." >&2
  fi
fi

# 4. read scanning
reads=$(jq '.reads' <<<"$state")
writes=$(jq '.writes' <<<"$state")

if (( reads >= READ_LIMIT && writes == 0 )); then
  echo "[LOOP WARNING] $reads reads with no writes — scanning loop likely." >&2
fi

exit 0
