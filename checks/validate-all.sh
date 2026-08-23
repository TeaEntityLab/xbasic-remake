#!/bin/sh
# Full-suite validation with unambiguous failure reporting.
#
# Background: `cargo test | grep ... | head -N` truncation hid a bootstrap
# regression for an entire session (2026-08-23). Run this INSTEAD of ad-hoc
# greps: it prints every non-ok result and exits nonzero on any failure.
set -e
cd "$(dirname "$0")/.."

OUT=$(mktemp)
cargo test --release > "$OUT" 2>&1 || true

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

TOTAL=$(grep -oE "[0-9]+ passed" "$OUT" | grep -oE "[0-9]+" | awk "{s+=\$1} END {print s}")
echo "=== ALL PASS ($TOTAL tests across $(grep -c 'test result:' "$OUT") binaries) ==="
rm -f "$OUT"
