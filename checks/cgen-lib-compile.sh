#!/bin/sh
# Probe: compile all 15 core libs through self-hosted cgen.x (CGEN-LIB-SCALE).
# Builds native cgen from selfhost/cgen.x via Rust CEmitter, then feeds
# Text IR (xb --emit-ir) to cgen and cc's the output. Reports passes/fails
# per lib. Exits non-zero if any lib fails; set CGEN_LIB_STRICT=0 for the
# old informational exit-0 behavior. CI can gate on exit code or grep count.

set -e
cd "$(dirname "$0")/.."
CC=${CC:-cc}
if [ -n "${XB_BIN:-}" ]; then
    : # honor caller override
elif [ -n "${CARGO_BIN_EXE_xb:-}" ]; then
    XB_BIN="$CARGO_BIN_EXE_xb"
elif [ -x "target/release/xb" ]; then
    XB_BIN="target/release/xb"
elif [ -x "target/debug/xb" ]; then
    XB_BIN="target/debug/xb"
else
    XB_BIN="target/release/xb"
fi
if [ ! -x "$XB_BIN" ]; then
    echo "building xb (release) for cgen-lib probe..." >&2
    cargo build --release -q
    XB_BIN="target/release/xb"
fi
OUT=${1:-/tmp/xblib-cgen}
rm -rf "$OUT"
mkdir -p "$OUT"

echo "=== build native cgen (selfhost/cgen.x via Rust CEmitter) ===" >&2
"$XB_BIN" --emit-c selfhost/cgen.x > "$OUT/cgen.c"
# cgen.c is ~200k lines; -O0 keeps cc fast and avoids extra warnings
$CC -O0 -Wno-incompatible-pointer-types -Wno-int-conversion "$OUT/cgen.c" -o "$OUT/cgen"
echo "cgen: $OUT/cgen ($(wc -c < "$OUT/cgen.c" | tr -d ' ') bytes C -> $(wc -c < "$OUT/cgen" | tr -d ' ') bytes exe)" >&2

FLAGS="-O0 -Wno-incompatible-pointer-types -Wno-int-conversion"
PASS=0
FAIL=0
FAILED_LIST=""
for lib in xbasic/lib/*.x xbasic/lib/*.x; do
    name=$(basename "$lib" .x)
    # Emit Text IR via Rust (heuristic; facet probe is similar at 9/15 — see docs/19)
    if ! "$XB_BIN" --emit-ir "$lib" > "$OUT/$name.ir" 2> "$OUT/$name.emit-err"; then
        echo "emit-ir FAIL $name" >&2
        cat "$OUT/$name.emit-err" >&2
        FAIL=$((FAIL+1))
        FAILED_LIST="$FAILED_LIST $name(emit-ir)"
        continue
    fi
    # Feed IR to cgen -> C
    "$OUT/cgen" < "$OUT/$name.ir" > "$OUT/$name.c" 2> "$OUT/$name.cgen-err"
    ec=$?
    if [ $ec -ne 0 ]; then
        echo "cgen FAIL $name (exit $ec)" >&2
        cat "$OUT/$name.cgen-err" >&2 | head -n 20
        FAIL=$((FAIL+1))
        FAILED_LIST="$FAILED_LIST $name(cgen:$ec)"
        continue
    fi
    # cc the emitted C (allow warnings, check for cc errors)
    if ! $CC $FLAGS -c "$OUT/$name.c" -o "$OUT/$name.o" 2> "$OUT/$name.cc-err"; then
        echo "cc FAIL $name" >&2
        cat "$OUT/$name.cc-err" >&2 | head -n 40
        FAIL=$((FAIL+1))
        FAILED_LIST="$FAILED_LIST $name(cc)"
        continue
    fi
    echo "ok $name" >&2
    PASS=$((PASS+1))
done

TOTAL=$((PASS+FAIL))
echo "" >&2
echo "=== cgen-lib probe: $PASS/$TOTAL pass, $FAIL fail ===" >&2
if [ -n "$FAILED_LIST" ]; then
    echo "failed:$FAILED_LIST" >&2
fi
# Also report size / RSS hint for xcol/xgr OOM cases
if [ -f "$OUT/xcol.ir" ]; then
    echo "xcol ir: $(wc -c < "$OUT/xcol.ir") bytes, c: $(wc -c < "$OUT/xcol.c" 2>/dev/null || echo "?") bytes" >&2
fi
if [ -f "$OUT/xgr.ir" ]; then
    echo "xgr ir: $(wc -c < "$OUT/xgr.ir") bytes, c: $(wc -c < "$OUT/xgr.c" 2>/dev/null || echo "?") bytes" >&2
fi

# Keep artifacts for inspection
echo "artifacts: $OUT" >&2
# Exit non-zero if any lib failed (CI can gate on this).
# Use CGEN_LIB_STRICT=0 to keep the old informational exit-0 behavior.
if [ "${CGEN_LIB_STRICT:-1}" = "0" ]; then
    exit 0
fi
exit "$FAIL"
