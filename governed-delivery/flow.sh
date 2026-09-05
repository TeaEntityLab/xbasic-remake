#!/usr/bin/env bash
# generated-by: flow-control-generator / sequential-pipeline / 2026-09-05 / stub-dry-run: see run-note.md
#
# Owns the SEVEN-GATE delivery sequence from governed-delivery/*.yaml as code.
# The model only ever runs inside stage 04 (execution). Every other stage is a
# deterministic check on files. Gates release on exit codes, never on
# self-report. Partial state stays under $STATE for inspection and resume.
#
# Exit codes: 0 done | 2 spec/plan gate failed | 3 verification failed
#             4 preflight (missing tool/verifier) | 5 awaiting a named human
#             6 envelope or constitutional-path violation
set -euo pipefail

# ---- config header ---------------------------------------------------------
AGENT_CMD="${AGENT_CMD:-claude -p}"           # host CLI; prompt is piped on STDIN. Stub: AGENT_CMD=cat
# Least-privilege flags for the execution step, e.g. for Claude Code:
#   AGENT_FLAGS='--allowedTools Read,Edit,Write,Bash(cargo:*),Bash(cc:*),Bash(git diff:*)'
# Never widened mid-run; the host, not this script, enforces them.
AGENT_FLAGS="${AGENT_FLAGS:-}"
TIMEOUT_CMD="${TIMEOUT_CMD:-}"                # host-provided, e.g. 'gtimeout 1800' (stock macOS has no timeout(1))
PYTHON="${PYTHON:-python3}"                   # needs PyYAML; pyenv resolves per-directory, so override if preflight exits 4
WORKDIR="${WORKDIR:-$(cd "$(dirname "$0")/.." && pwd)}"
CONTRACTS="${CONTRACTS:-$WORKDIR/governed-delivery}"
STATE="${STATE:-$CONTRACTS/state}"
VALIDATE_CMD="${VALIDATE_CMD:-checks/validate-all.sh}"
BOOTSTRAP_CMD="${BOOTSTRAP_CMD:-checks/verify-bootstrap.sh}"
# budget (mirrors envelope.yaml; the envelope is authoritative, these are the enforced copies)
MAX_EXEC_STEPS=1
MAX_FILES_TOUCHED="${MAX_FILES_TOUCHED:-12}"
GATE_TIMEOUT="${GATE_TIMEOUT:-1800}"
# ----------------------------------------------------------------------------

cd "$WORKDIR"; mkdir -p "$STATE"
LOG="$STATE/flow.log"
log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }
die() { log "ABORT exit=$1 $2"; echo "flow: $2" >&2; exit "$1"; }
yq() { "$PYTHON" - "$@" <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
for key in sys.argv[2].split('.'):
    doc = doc[int(key)] if isinstance(doc, list) else doc.get(key)
    if doc is None: print(''); sys.exit(0)
print(doc if not isinstance(doc, (list, dict)) else len(doc))
PY
}
run_agent() { # $1=prompt-file $2=out-file ; the only place a model runs
  log "start agent $1"
  local wrap=(); [ -n "$TIMEOUT_CMD" ] && read -r -a wrap <<<"$TIMEOUT_CMD"
  # shellcheck disable=SC2086
  ${wrap[@]+"${wrap[@]}"} $AGENT_CMD $AGENT_FLAGS < "$1" > "$2" || die 3 "agent exited non-zero for $1"
  log "done  agent $1 -> $2"
}
const_hash() { # hash of every constitutional path (files + dir trees)
  yq "$CONTRACTS/oracle-manifest.yaml" constitutional_paths >/dev/null
  "$PYTHON" - "$CONTRACTS/oracle-manifest.yaml" "$WORKDIR" <<'PY'
import hashlib, os, sys, yaml
paths = yaml.safe_load(open(sys.argv[1]))['constitutional_paths']
h = hashlib.sha256()
for p in sorted(paths):
    full = os.path.join(sys.argv[2], p)
    files = [full] if os.path.isfile(full) else sorted(
        os.path.join(r, f) for r, _, fs in os.walk(full) for f in fs) if os.path.isdir(full) else []
    for f in files:
        if '/state/' in f: continue
        h.update(f.encode()); h.update(open(f, 'rb').read())
print(h.hexdigest())
PY
}
gate() { # $1=stage $2=result(0/1) $3=note
  if [ "$2" -eq 0 ]; then log "gate $1 PASS $3"; else log "gate $1 FAIL $3"; fi
  return "$2"
}

# ---- preflight (exit 4) ----------------------------------------------------
command -v "$PYTHON" >/dev/null || die 4 "$PYTHON missing (set PYTHON=/path/to/python3 with PyYAML)"
"$PYTHON" -c 'import yaml' 2>/dev/null || die 4 "$PYTHON lacks the yaml module (set PYTHON=/path/to/python3 with PyYAML)"
for f in intent-record oracle-manifest task-packet verification-plan envelope acceptance-record; do
  [ -f "$CONTRACTS/$f.yaml" ] || die 4 "missing contract $f.yaml"
done
[ -x "$VALIDATE_CMD" ] || die 4 "verifier missing/not executable: $VALIDATE_CMD"
[ -x "$BOOTSTRAP_CMD" ] || die 4 "verifier missing/not executable: $BOOTSTRAP_CMD"
[ -f "$CONTRACTS/prompts/04-execute.md" ] || die 4 "missing prompts/04-execute.md"
git rev-parse --git-dir >/dev/null 2>&1 || die 4 "not a git workspace (needed for touched-file budget)"
log "preflight ok rev=$(git rev-parse --short HEAD)"

# ---- 01 intent: human decision; never auto-released ------------------------
if [ "$(yq "$CONTRACTS/intent-record.yaml" status)" != "signed" ] || [ -z "$(yq "$CONTRACTS/intent-record.yaml" signed_by)" ]; then
  gate 01-intent 1 "intent-record.yaml not signed" || true
  die 5 "awaiting human: sign governed-delivery/intent-record.yaml (signed_by + status: signed)"
fi
gate 01-intent 0 "signed_by=$(yq "$CONTRACTS/intent-record.yaml" signed_by)"
echo "signed" > "$STATE/01-intent.md"

# ---- 02 spec: versioned spec + oracle manifest; no stale dependents ---------
SPEC="$(yq "$CONTRACTS/task-packet.yaml" spec_version)"
for f in oracle-manifest acceptance-record; do
  [ "$(yq "$CONTRACTS/$f.yaml" spec_version)" = "$SPEC" ] || { gate 02-spec 1 "$f spec_version != $SPEC" || true; die 2 "spec version drift in $f"; }
done
! grep -rqE '^\s*status:\s*stale' "$CONTRACTS"/*.yaml || { gate 02-spec 1 "stale dependents present" || true; die 2 "stale items must be re-planned first"; }
NAC="$(yq "$CONTRACTS/task-packet.yaml" acceptance_criteria)"
[ "${NAC:-0}" -gt 0 ] || { gate 02-spec 1 "task-packet has no acceptance_criteria" || true; die 2 "missing acceptance: stop and repair the packet"; }
gate 02-spec 0 "spec=$SPEC criteria=$NAC"
printf 'spec_version: %s\nacceptance_criteria: %s\n' "$SPEC" "$NAC" > "$STATE/02-spec.md"

# ---- 03 plan: plan items bound to the current spec (deterministic) ---------
LEDGER_DOC="$WORKDIR/docs/17-open-work-roadmap.md"
[ -f "$LEDGER_DOC" ] || { gate 03-plan 1 "ledger missing" || true; die 2 "state ledger docs/17 missing"; }
missing=0
for row in $(yq "$CONTRACTS/task-packet.yaml" state_ledger_ref | grep -oE '[A-Z][A-Z0-9-]{4,}' | sort -u); do
  grep -q -- "$row" "$LEDGER_DOC" || { log "plan: row $row not found in docs/17"; missing=$((missing+1)); }
done
[ "$missing" -eq 0 ] || { gate 03-plan 1 "$missing referenced rows missing" || true; die 2 "plan not bound to ledger"; }
gate 03-plan 0 "ledger rows present"
yq "$CONTRACTS/task-packet.yaml" state_ledger_ref > "$STATE/03-plan.md"

# ---- 04 execution: the only model step; envelope-bounded --------------------
[ -n "$(yq "$CONTRACTS/envelope.yaml" approved_by)" ] || { gate 04-execution 1 "envelope not approved" || true; die 5 "awaiting human: set approved_by in governed-delivery/envelope.yaml"; }
if [ -s "$STATE/04-execution.md" ] && [ -s "$STATE/04-base-rev.txt" ] && [ -s "$STATE/04-const-before.sha" ]; then
  # resume convention: never re-run the model step; re-validate its post-conditions instead
  BEFORE="$(cat "$STATE/04-const-before.sha")"; BASE_REV="$(cat "$STATE/04-base-rev.txt")"
  log "resume: 04-execution.md present, skipping agent call (base=$BASE_REV)"
else
  BEFORE="$(const_hash)"; echo "$BEFORE" > "$STATE/04-const-before.sha"
  BASE_REV="$(git rev-parse HEAD)"; echo "$BASE_REV" > "$STATE/04-base-rev.txt"
  { cat "$CONTRACTS/prompts/04-execute.md"; echo; echo "## Task packet"; cat "$CONTRACTS/task-packet.yaml";
    echo; echo "## Spec"; cat "$STATE/02-spec.md"; } > "$STATE/04-prompt.md"
  run_agent "$STATE/04-prompt.md" "$STATE/04-execution.md"                   # step 1 of MAX_EXEC_STEPS=1
fi
AFTER="$(const_hash)"; echo "$AFTER" > "$STATE/04-const-after.sha"
[ "$BEFORE" = "$AFTER" ] || { gate 04-execution 1 "constitutional path changed" || true; die 6 "GDR-1: a constitutional path changed during execution; roll back to $BASE_REV"; }
TOUCHED="$(git diff --name-only "$BASE_REV" | wc -l | tr -d ' ')"; TOUCHED=$((TOUCHED + $(git ls-files -o --exclude-standard | grep -vc '^governed-delivery/state/' || true)))
[ "$TOUCHED" -le "$MAX_FILES_TOUCHED" ] || { gate 04-execution 1 "touched=$TOUCHED > $MAX_FILES_TOUCHED" || true; die 6 "envelope: too many files touched"; }
gate 04-execution 0 "touched=$TOUCHED const_hash=unchanged"

# ---- 05 verification: deterministic verifiers are the only signal ----------
run_verifier() { # $1=name $2=cmd  -> appends failure signature and exits 3 on failure
  local out="$STATE/05-$1.log" rc=0 wrap=()
  [ -n "$TIMEOUT_CMD" ] && read -r -a wrap <<<"$TIMEOUT_CMD"
  log "start verifier $1"
  ${wrap[@]+"${wrap[@]}"} "$2" > "$out" 2>&1 || rc=$?
  echo "exit=$rc" >> "$out"
  if [ "$rc" -ne 0 ]; then
    { echo "  - oracle: \"$1\""; echo "    error_class: \"$(tail -n 2 "$out" | head -n 1 | tr -d '"' | cut -c1-160)\"";
      echo "    surface: \"$(git diff --name-only "$BASE_REV" | tr '\n' ' ' | cut -c1-200)\"";
      echo "    revision: \"$(git rev-parse --short HEAD)\""; echo "    after_correction: false"; echo "    exit: escalate"; } >> "$STATE/failure-log.yaml"
    gate 05-verification 1 "$1 exit=$rc" || true
    die 3 "verifier $1 failed (exit $rc); signature appended to $STATE/failure-log.yaml; see $out"
  fi
  log "done  verifier $1 exit=0 -> $out"
}
[ -f "$STATE/failure-log.yaml" ] || echo "entries:" > "$STATE/failure-log.yaml"
run_verifier validate-all "$VALIDATE_CMD"
run_verifier verify-bootstrap "$BOOTSTRAP_CMD"
gate 05-verification 0 "validate-all+verify-bootstrap exit=0 rev=$(git rev-parse --short HEAD)"
{ echo "revision: $(git rev-parse HEAD)"; echo "validate-all: exit=0 receipt=state/05-validate-all.log";
  echo "verify-bootstrap: exit=0 receipt=state/05-verify-bootstrap.log"; } > "$STATE/05-verification.md"

# ---- 06 acceptance: named human closes against oracles; never auto ---------
if [ "$(yq "$CONTRACTS/acceptance-record.yaml" closed)" != "True" ] || [ -z "$(yq "$CONTRACTS/acceptance-record.yaml" accepter)" ]; then
  gate 06-acceptance 1 "acceptance-record.yaml not closed" || true
  die 5 "awaiting human: accepter reviews $STATE/05-verification.md against oracle-manifest.yaml, then sets closed: true"
fi
gate 06-acceptance 0 "accepter=$(yq "$CONTRACTS/acceptance-record.yaml" accepter)"
echo "closed" > "$STATE/06-acceptance.md"

# ---- 07 retro: derived from flow.log; policy change stays off activation ---
"$PYTHON" - "$LOG" "$STATE/07-gate-retro.yaml" <<'PY'
import re, sys, yaml
lines = open(sys.argv[1]).read().splitlines()
gates = ['intent','spec','plan','execution','verification','acceptance','retro']
rec = {g: {'name': g, 'fired': False, 'bypassed': False, 'caught_nothing': False} for g in gates}
for l in lines:
    m = re.search(r'gate 0\d-(\w+) (PASS|FAIL)', l)
    if m: rec[m.group(1)]['fired'] = True; rec[m.group(1)]['caught_nothing'] = (m.group(2) == 'PASS')
rec['retro']['fired'] = True; rec['retro']['caught_nothing'] = True
yaml.safe_dump({'gates': [rec[g] for g in gates], 'policy_change': 'separate_from_activation'}, open(sys.argv[2], 'w'), sort_keys=False)
yaml.safe_load(open(sys.argv[2]))   # gate: parses
PY
gate 07-retro 0 "written $STATE/07-gate-retro.yaml"
log "pipeline complete"
echo "flow: complete; evidence under $STATE"
