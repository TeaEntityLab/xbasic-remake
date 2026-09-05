#!/bin/sh
# Full-suite validation with unambiguous failure reporting.
#
# Background: `cargo test | grep ... | head -N` truncation hid a bootstrap
# regression for an entire session (2026-08-23). Run this INSTEAD of ad-hoc
# greps: it prints every non-ok result and exits nonzero on any failure.
set -e
cd "$(dirname "$0")/.."

OUT=$(mktemp)
CARGO_RC=0
CARGO_BUILD_JOBS=4 cargo test --release -- --test-threads=1 > "$OUT" 2>&1 || CARGO_RC=$?

echo "=== suites ==="
grep "Running" "$OUT" | sed 's|.*deps/||; s|-[0-9a-f]*||' | head -40

FAILURES=$(grep -E "^test result:" "$OUT" | grep -vc " 0 failed" || true)
FAILED_TESTS=$(grep "^test .* FAILED" "$OUT" || true)

if [ "$FAILURES" != "0" ]; then
    echo ""
    echo "=== FAILURES ($FAILURES failing suites) ==="
    grep -B2 -A20 "^test .* FAILED" "$OUT" | head -80
    echo "full log: $OUT"
    exit 1
fi

TOTAL=$(grep -oE "[0-9]+ passed" "$OUT" | grep -oE "[0-9]+" | awk "{s+=\$1} END {print s+0}")
BINARIES=$(grep -c 'test result:' "$OUT" || true)
# Fail closed: a non-zero cargo exit with no parsed test failure means the run
# died before/without emitting results (compile error, harness crash, OOM kill).
if [ "$CARGO_RC" -ne 0 ] || [ "$BINARIES" -eq 0 ] || [ "$TOTAL" -eq 0 ]; then
    echo ""
    echo "=== CARGO GATE FAILED (exit $CARGO_RC, $BINARIES binaries, $TOTAL passed) ==="
    tail -n 40 "$OUT"
    echo "full log: $OUT"
    exit 1
fi
echo "=== ALL PASS ($TOTAL tests across $BINARIES binaries) ==="
rm -f "$OUT"

echo "=== core libs (link-core-libs.sh) ==="
rm -rf /tmp/xblib-validate
# Capture the helper's own status; a pipeline's status is its last command (tail).
LINK_RC=0
checks/link-core-libs.sh /tmp/xblib-validate > /tmp/xblib-validate.log 2>&1 || LINK_RC=$?
tail -n 20 /tmp/xblib-validate.log
if [ "$LINK_RC" -ne 0 ]; then
    echo "link-core-libs.sh FAILED (exit $LINK_RC, see /tmp/xblib-validate.log)"
    exit 1
fi
echo "=== core libs OK (15/15 compile+link; Version\$ smoke is informational, see link-core-libs.sh) ==="
OUT_BIN="/tmp/xblib-validate/xblibs"
if [ ! -f "$OUT_BIN" ]; then
    echo "ERROR: $OUT_BIN was not generated"
    exit 1
fi
# Cross-platform defined-symbol count (Darwin Mach-O '_xb_user_' vs Linux ELF 'xb_user_'; filter undefined U/w)
SYM_COUNT=$(nm "$OUT_BIN" 2>/dev/null | grep -v -E ' (U|w) ' | grep -E -c '(_xb_user_|xb_user_)[A-Za-z0-9_]+' || true)
EXPECTED_SYMS=1736
if [ "$SYM_COUNT" -ne "$EXPECTED_SYMS" ]; then
    echo "WARNING: Core lib symbol count variance: found $SYM_COUNT, expected $EXPECTED_SYMS (check for unnested exports or platform variance)"
    if [ "$SYM_COUNT" -lt 1690 ]; then
        echo "ERROR: Symbol count $SYM_COUNT dropped below minimum threshold (1690)"
        exit 1
    fi
fi
echo "=== core libs Tier-1 guard PASSED ($SYM_COUNT xb_user_ symbols, smoke 7 Version$) ==="
# Functional non-Version$ export presence (Provenance guard: ensures compiled lib bodies present beyond Version$)
if ! nm "$OUT_BIN" 2>/dev/null | grep -q -E '(_xb_user_|xb_user_)XstGetCommandLineArguments'; then
    echo "ERROR: Missing XstGetCommandLineArguments export in linked binary (functional non-Version$ check)"
    exit 1
fi
