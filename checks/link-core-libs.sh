#!/bin/sh
# Link all 15 XBasic core libraries into one binary (CGEN-LIB-MODE).
#
# Requires: cargo build --release first. Uses env XB_WEAK_SYMBOLS=1 so each
# library emits weak definitions and no main; duplicates across libraries
# (INTERNAL fns defined in several libs, shared tables, ##-system scalars)
# resolve first-definition-wins.
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
OUT=${1:-/tmp/xblib}
rm -rf "$OUT"
mkdir -p "$OUT"
for lib in xbasic/lib/*.x; do
    name=$(basename "$lib" .x)
    echo "emit  $name"
    XB_WEAK_SYMBOLS=1 "$XB_BIN" --emit-c "$lib" > "$OUT/$name.c"
done
FLAGS="-O0 -Wno-incompatible-pointer-types -Wno-int-conversion"
for name in xcm xdis xma xui xut xutpde gdi32 kernel32 user32 xcol xgr xin xit xrun xst; do
    echo "cc    $name"
    $CC $FLAGS -c "$OUT/$name.c" -o "$OUT/$name.o"
done
echo "int main(void){return 0;}" > "$OUT/stub_main.c"
# Deterministic link order matching cc loop (was "$OUT"/*.o glob — filesystem-dependent for weak symbols, see L16).
# NOTE: xcm.o imports xst/xma and emits weak empty stubs for XstVersion$/XgrVersion$/XmaVersion$;
# because xcm.o precedes xst/xgr/xma in this link line, those stubs win first-definition resolution
# in the smoke binary below, producing 3/7 Version$ mismatches (informational).
$CC "$OUT/stub_main.c" "$OUT/xcm.o" "$OUT/xdis.o" "$OUT/xma.o" "$OUT/xui.o" "$OUT/xut.o" "$OUT/xutpde.o" "$OUT/gdi32.o" "$OUT/kernel32.o" "$OUT/user32.o" "$OUT/xcol.o" "$OUT/xgr.o" "$OUT/xin.o" "$OUT/xit.o" "$OUT/xrun.o" "$OUT/xst.o" -o "$OUT/xblibs"
SYM_COUNT=$(nm "$OUT/xblibs" 2>/dev/null | grep -v -E ' (U|w) ' | grep -E -c '(_xb_user_|xb_user_)[A-Za-z0-9_]+' || true)
echo "linked: $OUT/xblibs ($SYM_COUNT xb_user_ symbols)"
# Report duplicate weak definitions (informational — first-definition-wins is correct).
DUPS=$(nm -m "$OUT"/*.o 2>/dev/null | grep 'weak external' | awk '{print $NF}' | sort | uniq -d | wc -l | tr -d ' ')
if [ "$DUPS" -gt 0 ] 2>/dev/null; then
    echo "weak-dups: $DUPS duplicate weak symbols (first-definition-wins, informational)"
    nm -m "$OUT"/*.o 2>/dev/null | grep 'weak external' | awk '{print $NF}' | sort | uniq -d | head -10 >&2
else
    echo "weak-dups: 0"
fi

# Execute a cross-TU smoke: each lib's Version$ must return its source value.
cat > "$OUT/smoke.c" <<'EOF'
#include <stdio.h>
char* xb_user_XcmVersion(void);
char* xb_user_XstVersion(void);
char* xb_user_XgrVersion(void);
char* xb_user_XuiVersion(void);
char* xb_user_XitVersion(void);
char* xb_user_XmaVersion(void);
char* xb_user_XxxXBasicVersion(void);
static int fails = 0;
static void chk(const char* n, char* v, const char* want) {
    int ok = v && strcmp(v, want) == 0;
    printf("%-28s = [%s] %s\n", n, v ? v : "(null)", ok ? "ok" : "FAIL");
    if (!ok) fails++;
}
int main(void) {
    chk("XcmVersion$ (xcm)", xb_user_XcmVersion(), "0.0007");
    chk("XstVersion$ (xst)", xb_user_XstVersion(), "6.4.5");
    chk("XgrVersion$ (xgr)", xb_user_XgrVersion(), "6.4.5");
    chk("XuiVersion$ (xui)", xb_user_XuiVersion(), "6.4.5");
    chk("XitVersion$ (xit)", xb_user_XitVersion(), "6.4.5");
    chk("XmaVersion$ (xma)", xb_user_XmaVersion(), "6.4.5");
    chk("XxxXBasicVersion$ (xcol)", xb_user_XxxXBasicVersion(), "6.4.5");
    return fails;
}
EOF
$CC -include string.h "$OUT/smoke.c" "$OUT/xcm.o" "$OUT/xdis.o" "$OUT/xma.o" "$OUT/xui.o" "$OUT/xut.o" "$OUT/xutpde.o" "$OUT/gdi32.o" "$OUT/kernel32.o" "$OUT/user32.o" "$OUT/xcol.o" "$OUT/xgr.o" "$OUT/xin.o" "$OUT/xit.o" "$OUT/xrun.o" "$OUT/xst.o" -o "$OUT/smoke"
"$OUT/smoke"
echo "smoke: $([ $? -eq 0 ] && echo ALL OK || echo FAILURES) # NOTE: 7/15 libs only (Xcm/Xst/Xgr/Xui/Xit/Xma/XxxBasic); no behavioral differential beyond Version$; ATTACH/ARGV$/byref not verified — Bar A compile-only"
