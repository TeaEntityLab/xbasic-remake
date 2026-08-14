#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

fail() {
  echo "verify-bootstrap: $*" >&2
  exit 1
}

cargo fmt --all -- --check
cargo check --workspace
cargo test --workspace
cargo clippy --workspace --all-targets

[ ! -e xbasic-6.5.0 ] || fail "nested xbasic-6.5.0/ must not exist"
! grep -RIn 'xbasic-6\.5\.0' docs >/tmp/xbasic-verify-docrefs.txt 2>&1 || {
  cat /tmp/xbasic-verify-docrefs.txt >&2
  fail "docs still reference nested xbasic-6.5.0"
}

# ERE for BSD/GNU grep parity; matches real `unsafe` only, not the safe extern "C" XxxMain ABI.
if grep -REn 'unsafe[[:space:]]*(\{|fn|impl)' crates --include='*.rs' >/tmp/xbasic-verify-unsafe.txt 2>&1; then
  cat /tmp/xbasic-verify-unsafe.txt >&2
  fail "unsafe code requires a separate Miri-backed task"
fi

python3 - <<'PY'
from pathlib import Path
bad = []
for p in Path('crates').rglob('*.rs'):
    count = 0
    for line in p.read_text(errors='ignore').splitlines():
        s = line.strip()
        if s and not s.startswith('//'):
            count += 1
    if count > 250:
        bad.append((str(p), count))
if bad:
    for path, count in bad:
        print(f'{path}: {count} pure LOC > 250')
    raise SystemExit(1)
PY

[ -f crates/xb-frontend/src/parser_tests.rs ] || fail "parser tests missing"
grep -RIn 'rejects_trailing_tokens_after_print_expression' crates/xb-frontend/src >/dev/null || fail "parser trailing-token regression test missing"
grep -RIn 'DuplicateSymbol' crates/xb-compiler/src >/dev/null || fail "semantic duplicate-symbol check missing"
grep -RIn 'UnknownSymbol' crates/xb-compiler/src >/dev/null || fail "semantic unknown-symbol check missing"
grep -RIn 'IrProgram' crates/xb-compiler/src >/dev/null || fail "typed IR missing"
[ -f fixtures/bootstrap/hello.x ] || fail "bootstrap hello fixture missing"
grep -RIn 'cli_prints_stable_ir_summary_for_committed_fixture' crates/xb-cli/tests >/dev/null || fail "CLI fixture integration test missing"

echo "verify-bootstrap: ok"
