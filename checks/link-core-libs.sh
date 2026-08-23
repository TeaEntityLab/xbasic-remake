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
