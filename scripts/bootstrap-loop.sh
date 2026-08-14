#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERIFY="${VERIFY:-./checks/verify-bootstrap.sh}"
TASKS_SRC="${TASKS:-./TASKS.bootstrap.md}"
MAX_ITER="${MAX_ITER:-8}"
STATE="${STATE:-./state}"
LEDGER="$STATE/ledger.md"
CANON="$STATE/TASKS.canon"
AGENT_CMD="${AGENT_CMD:-}"

mkdir -p "$STATE"
touch "$LEDGER"

[ -x "$VERIFY" ] || { echo "verifier missing/not executable: $VERIFY" >&2; exit 4; }
[ -f "$TASKS_SRC" ] || { echo "task backlog missing: $TASKS_SRC" >&2; exit 4; }
[ -n "$AGENT_CMD" ] || { echo "AGENT_CMD must be set, e.g. AGENT_CMD='opencode run'" >&2; exit 4; }
[ -f "$CANON" ] || cp "$TASKS_SRC" "$CANON"

check() {
  local ec=0
  "$VERIFY" > "$STATE/verify-out.txt" 2>&1 || ec=$?
  return "$ec"
}

snapshot() {
  printf '%s +u%s' "$(git diff --stat | tail -n1)" "$(git ls-files -o --exclude-standard | wc -l | tr -d ' ')"
}

first_task_line() {
  grep -n -m1 '^- \[ \]' "$CANON" || true
}

if [ -s "$LEDGER" ]; then
  echo "- RESUMED $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LEDGER"
fi

if ! check; then
  echo "initial verifier failed; fix the workspace before looping" >&2
  cat "$STATE/verify-out.txt" >&2
  exit 3
fi

prev="$(snapshot)"
for i in $(seq 1 "$MAX_ITER"); do
  line="$(first_task_line)"
  if [ -z "$line" ]; then
    echo "- iter $i: BACKLOG EMPTY, VERIFIED" >> "$LEDGER"
    echo "bootstrap backlog complete"
    exit 0
  fi

  num="${line%%:*}"
  task="${line#*:}"

  {
    sed '/{{TASK}}/,$d' prompts/bootstrap-iteration.md
    printf '%s\n\n' "$task"
    sed -n '/{{LEDGER}}/,$p' prompts/bootstrap-iteration.md | sed '/{{LEDGER}}/d;/{{VERIFY_OUTPUT}}/,$d'
    tail -n 30 "$LEDGER" || true
    sed -n '/{{VERIFY_OUTPUT}}/,$p' prompts/bootstrap-iteration.md | sed '/{{VERIFY_OUTPUT}}/d'
    cat "$STATE/verify-out.txt"
  } > "$STATE/iter-$i-prompt.md"

  $AGENT_CMD "$(cat "$STATE/iter-$i-prompt.md")" > "$STATE/iter-$i-out.md" 2>&1 || true

  if ! check; then
    echo "- iter $i: VERIFY FAILED $task" >> "$LEDGER"
    cat "$STATE/verify-out.txt" >&2
    exit 3
  fi

  cur="$(snapshot)"
  if [ "$cur" = "$prev" ]; then
    echo "- iter $i: NO PROGRESS, not retiring task" >> "$LEDGER"
    exit 3
  fi

  sed "${num}d" "$CANON" > "$CANON.tmp" && mv "$CANON.tmp" "$CANON"
  echo "- iter $i: DONE $task" >> "$LEDGER"
  prev="$cur"
done

echo "- cap $MAX_ITER exhausted" >> "$LEDGER"
exit 2
