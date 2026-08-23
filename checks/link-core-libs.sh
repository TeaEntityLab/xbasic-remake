#!/bin/sh
# Link all 15 XBasic core libraries into one binary (CGEN-LIB-MODE).
#
# Requires: cargo build --release first. Uses env XB_WEAK_SYMBOLS=1 so each
# library emits weak definitions and no main; duplicates across libraries
# (INTERNAL fns defined in several libs, shared tables, ##-system scalars)
# resolve first-definition-wins.
set -e
cd "$(dirname "$0")/.."
OUT=${1:-/tmp/xblib}
mkdir -p "$OUT"
for lib in xbasic-6.4.5/src/shared/*.x xbasic-6.4.5/src/linux/*.x; do
    name=$(basename "$lib" .x)
    echo "emit  $name"
    XB_WEAK_SYMBOLS=1 target/release/xb --emit-c "$lib" > "$OUT/$name.c"
done
FLAGS="-O0 -Wno-incompatible-pointer-types -Wno-int-conversion"
for name in xcm xdis xma xui xut xutpde gdi32 kernel32 user32 xcol xgr xin xit xrun xst; do
    echo "cc    $name"
    cc $FLAGS -c "$OUT/$name.c" -o "$OUT/$name.o"
done
echo "int main(void){return 0;}" > "$OUT/stub_main.c"
cc "$OUT/stub_main.c" "$OUT"/*.o -o "$OUT/xblibs"
echo "linked: $OUT/xblibs ($(nm -U "$OUT/xblibs" | grep -c '_xb_user_') xb_user_ symbols)"

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
cc -include string.h "$OUT/smoke.c" "$OUT"/*.o -o "$OUT/smoke"
"$OUT/smoke"
echo "smoke: $([ $? -eq 0 ] && echo ALL OK || echo FAILURES)"
