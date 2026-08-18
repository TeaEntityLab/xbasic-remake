# 17 — Open-Work Roadmap (everything not done yet)

> Status: living umbrella roadmap. Consolidates known-but-undocumented gaps from
> working notes into one tracked place. Each item marks **provenance**:
> `[verified <session>]` = re-measured with a command shown; `[carried]` =
> from prior working notes, not re-measured here.
>
> Scoped sibling: [16-cgen-cemitter-sync-roadmap.md](16-cgen-cemitter-sync-roadmap.md)
> (the two C generators). Progress narrative: [14-self-hosting-progress.md](14-self-hosting-progress.md).

> Last full re-verification: **2026-08-17**. `cargo test --workspace --exclude
> xb-ide` = **154 passed / 0 failed**; every `✅ done` item below re-confirmed via
> its named locking test, and every open item re-confirmed still open (no silent
> regression *or* silent progress). Two doc corrections landed this pass:
> DEMO-RUNTIME recount (68/114) and the stale bootstrap fixed-point hash
> (`f6e21a03…` → `c8d5c7f1…`; docs/13 §Stages, docs/14 §21). One gap was found and
> fixed this pass: RT-FIXEDSTR (`STRING*N` composite members; see §2).

## 1. Backends

### LB-STUB — LLVM backend emits a real native object ✅ done
`llvm_backend::LlvmBackend::compile` (feature `llvm`) builds an LLVM module and writes a
real host-target object via `TargetMachine::write_to_memory_buffer(Object)` (was
`ObjectFile::from_bytes(Vec::new())`). A recursive `Emit` translates a growing subset into
a `main` driving `printf` (top-level items + the entry-function body, mirroring
`execute_main`): scalar `DIM`/assignment, **integers** (literals, vars, arithmetic
`+ - * /`, comparisons → XBasic `-1/0`, boolean/logical/`NOT`), **doubles** (literals,
vars, arithmetic, comparison, `%g` print, int→float promotion), **strings** (literals,
vars, `PRINT`), **`IF`/`WHILE`/`FOR`** control flow via basic blocks, **user-defined
functions** (definitions, calls, returns, params, per-function scope; two-pass declare +
emit), **N-dim arrays** (`DIM a[d0,d1,…]` → `calloc`'d row-major heap buffer with a
per-dimension count shape; `a[i,j,…]` read/write via a Horner offset mirroring
`TypedSlot::array_offset`) + **`UBOUND`** (flat length − 1 / `LEN` − 1 / −1), **`ABS`/`LEN`
builtins** (int/float abs via select; `LEN`→ libc `strlen`), **string comparison** (libc
`strcmp` vs 0), **`CHR$`** (calloc'd 2-byte buffer → string-returning builtin path),
**`LEFT$`/`RIGHT$`/`MID$`** substring builtins (`calloc`+`memcpy`; sext/unsigned-min/
saturating-sub mirroring the interpreter's `as usize`/`min`/`saturating_sub`), **string
concatenation** (`+` → `calloc`+two `memcpy`s), and **`STR$`** for integers
(`snprintf("%d")` = Rust `i32::to_string`). All string/array semantics parity-checked vs
`xb --run`. Still deferred (incremental; C backend stays the full AOT path):
content-preserving `REDIM` / array bounds checks, float `STR$` + `VAL` (Rust float-fmt /
strict `i32::parse` ≠ `printf`/`strtol`). Proven end-to-end (compile → `cc` link →
run): `hello`; `2*3+1`→`7`; `FOR` sum 1..3 + `IF`→`6`,`big`; `10.0/4.0`→`2.5`;
`Square(5)`→`25`; `a[2]=a[0]+a[1]`→`30`; `DIM m[2,3]` row-major → `5/9/7`;
`FOR i=0 TO UBOUND(a)` → `a[4]=16`; `LEN("hello")`→`5`, `ABS(0-7)`→`7`;
`IF n$="yes"`→`match`; `CHR$(65)`→`A`; `LEFT$/RIGHT$/MID$("hello world")`;
`"n="+STR$(42)`→`n=42`. Locked by feature-gated `lib.rs::tests::{llvm_backend_emits_runnable_object,
llvm_backend_compiles_integer_arithmetic, llvm_backend_compiles_control_flow,
llvm_backend_compiles_float_arithmetic, llvm_backend_compiles_user_function_call,
llvm_backend_compiles_array_indexing, llvm_backend_compiles_multidim_array,
llvm_backend_compiles_ubound, llvm_backend_compiles_builtins_abs_len,
llvm_backend_compiles_string_comparison, llvm_backend_compiles_chr_builtin,
llvm_backend_compiles_substring_builtins, llvm_backend_compiles_string_build}`. New error
leaf `CompileError::Llvm` = `XB-B002`. Reference: `docs/12 §3.1`.

### LB-TOOLCHAIN — LLVM feature builds against local LLVM 22 ✅ done
`cargo check/build/test -p xb-compiler --features llvm` now succeeds with
`LLVM_SYS_221_PREFIX=/opt/homebrew/opt/llvm` — the default Homebrew `llvm` is **22.1.8**
(and `llvm@22` is a keg), matching the documented `inkwell` `llvm22-1` pin, so **no version
reversal was needed** (the earlier "only llvm@21 installed" note was stale). The prior
failure was solely the missing `LLVM_SYS_221_PREFIX`. The `llvm` feature stays off by
default (`DisabledLlvmBackend` → `XB-B001`); the C generator remains the default AOT
backend (docs/13 §Stage 3). To build/test the LLVM path, set that env var.

### JIT-X87 — FPU-intrinsic JIT not implemented `[verified]`
No JIT crate is present (`iced-x86` / `dynasm` absent from `Cargo.lock`). The
x87 FPU-intrinsic JIT (old `xlib.s` FSIN/FCOS/FPREM/…) is deferred; runtime math
uses plain `f64`. Only pursue if exact x87 compat semantics are ever required
(`docs/12 §3.2`).

## 2. Runtime semantics

### RT-BYTESTRING — byte-accurate strings: value layer ✅ done; I/O channels deferred
`RuntimeValue::String` is now `Vec<u8>` (slot.rs), so `CHR$(>127)` yields a single
byte and `LEN`/`ASC`/`MID$`/`LEFT$`/`RIGHT$`/`INSTR`/`RINSTR`/concat/compare/
`STUFF$`/justify/clip and `{}` brace access are byte-accurate; textual ops (`VAL`,
case, `TRIM$`, `FORMAT$`, numeric parse) use a lossy UTF-8 view (ASCII unchanged).
~85 value sites updated across arith/builtin*/call/data_segment/eval/helpers/
interpreter; `render()` is the lossy display boundary. Locked by
`interpreter.rs::{chr_above_127_is_a_single_byte, string_builtins_are_byte_accurate}`
(full suite 158/0). **Still deferred**: the interpreter's I/O channels remain
`String`-based (`execute_main*` take `output: &mut Vec<String>` / `input:
Vec<String>`, used by ~10 test files + the sync tests), so *faithful high-byte
PRINT/INPUT* needs byte-capable channels — a separate refactor. **Correction**: the
old "msc.x MscEncrypt/MscDecrypt … stray 0x60" repro was mis-attributed to UTF-8
mangling; the msc.x "Decoded as" line is actually blocked by SEL-CASE-TRUE below
(`MscHexStr$`), not by string storage.

### SEL-CASE-TRUE — `SELECT CASE TRUE`/`FALSE`/`ALL` truthiness matching ✅ done
The idiom `SELECT CASE TRUE` with `CASE <boolexpr>:` branches (pervasive across the
legacy libs — xcol/xgr/xin/xst/xui/xma/kernel32) never matched a true branch: the
parser discarded the `TRUE`/`FALSE` keyword and set the selector to
`IntegerLiteral("1")`, then matched by *equality*, but comparisons/`&&` yield `-1`,
so control always fell to `CASE ELSE`. Fixed in `parser_select.rs` by desugaring the
special forms to `IF` (which tests non-zero): `SELECT CASE TRUE` → nested `IF/ELSE`
over each CASE condition (first truthy wins); `FALSE` → `IF NOT cond`; `ALL TRUE`/
`ALL FALSE`/`ALL <expr>` → independent `IF`s (every match runs). Plain `SELECT CASE
<expr>` still lowers to the value/first-match `SelectCase` IR unchanged — the
text-IR goldens and `cgen.x`'s `select_case ` contract are untouched (no
golden-bearing source uses the special forms). Locked by
`interpreter.rs::{select_case_true_matches_first_truthy_branch,
select_case_all_true_runs_every_truthy_branch}`; legacy corpus still 204/204.

### VAR-SUFFIX-COLLISION — numeric `x` and string `x$` sharing a base name ✅ done
`self.symbols` is keyed by BASE name, so a numeric `x` and a string `x$` in one scope
would otherwise fight over slot `x` (declaration order deciding the winner). Fixed with
a per-function pre-scan (`semantics_suffix.rs::scan_body_collisions`, run in
`function()`): a base referenced with both a string and a non-string type is a
collision, and `slot_name` then gives the string variant its `$`-suffixed slot and the
numeric the bare base — applied consistently at reads (`symbol`) and writes
(`assignment`), so it is **order-independent** (numeric-first `c = 5 : c$ = "F"` and
string-first `c$ = "F" : c = 5` both keep `c` / `c$` distinct). Non-colliding bases
still strip the suffix (goldens / `cgen.x` unchanged; only String/numeric collisions —
absent from every golden source — get the `$`-bearing slot, a C-backend concern of the
CG-BODY-COVER class). Locked by
`interpreter.rs::{numeric_then_string_same_base_name_are_distinct_slots,
string_then_numeric_same_base_name_are_distinct_slots}`.

### GOSUB-SCOPE — `GOSUB` to a local `SUB` shares the caller's scope ✅ done
A `SUB` inside a function (a local subroutine reached by `GOSUB`, classic BASIC) was
lowered as a *separate* nested `function` and run by `gosub` in a fresh scope, so its
mutations were lost (`x = 5 : GOSUB Bump` / `SUB Bump : x = x + 10` printed `5`, not
`15`). Fixed at the **semantic** layer (`semantics_function.rs::inline_gosub_subs`, run
in `function()`): a SUB whose name is a `GOSUB` target (scanning nested SUB bodies too)
is rewritten to inline `Label(name)` + body + bare `RETURN` (→ `GosubReturn`, after a
`RETURN` guard) and analyzed **in the caller's own scope**, so its variables share the
caller's symbol table + collision set; the interpreter's existing shared-scope
`Label`/`GosubReturn` path runs it. (A lowering-only inline — the first attempt — left
the SUB in a separate semantic scope → divergent types/names, i.e. the `ary.x`
`String`/`String` mismatch; the semantic fix resolves that.) Locked by
`interpreter.rs::gosub_to_local_sub_shares_caller_scope`; golden-safe (selfhost has no
SUBs; non-SUB bodies unchanged). Also made `ASC("")` → `0` (legacy) en route.

**msc.x fully closed**: RT-BYTESTRING + SEL-CASE-TRUE + VAR-SUFFIX-COLLISION +
GOSUB-SCOPE together make `msc.x`'s `TestMscHex` round-trip print `Decoded as:
robin@example.com`; locked by `xbsourcelib_run.rs::xbsourcelib_msc_strhex_is_correct`.

### MIG-ARY-REDIM — growable `DIM a[]` + `REDIM` preserving contents ✅ done
XBasic arrays do **not** auto-grow on assignment (an earlier note mis-stated this); they
use `DIM`/`REDIM`, where **`REDIM` resizes preserving existing contents** (grow
default-fills the new tail; shrink truncates), and `DIM a[]` is an *empty growable* array
(`UBOUND` = −1). Both were broken: `REDIM` lowered to a plain `DIM` that replaced the
slot (contents lost), and `DIM a[]` was indistinguishable from a scalar `DIM a`
(→ "not an array"). Fix: carry `is_array` + `redim` on `Statement::Dim`/`CheckedItem::Dim`/
`IrItem::Dim` (parser distinguishes `[]` from scalar; `REDIM` sets `redim`); the
interpreter honors them via `TypedSlot::array_resize` (`Vec::resize`, preserve semantics).
This unblocks the pervasive `REDIM a$[UBOUND(a$[]) + N]` idiom (ary/fgr/xui/msc/XBMerge +
demos adata/aprofile/agrids/CursorEdit). Locked by
`interpreter.rs::{redim_grows_preserving_contents_from_empty_dim,
redim_shrink_truncates_and_preserves_low_indices}`. **Golden-safe**: text-IR emission is
unchanged (`is_array`/`redim` are in-memory flags honored on the `--run` path, which
interprets IR directly; `static_redim_doevents.ir` stays byte-identical), and selfhost
uses no arrays, so the bootstrap fixed point is untouched. Note: the text-IR/C backends
treat `REDIM` as `DIM` (no dynamic resize — C emits fixed stack arrays); the interpreter
is the faithful runtime.

Confirmed spec-correct against `lang.txt:389-392` ("when an array is redimensioned, the
existing contents not in the new (smaller) size are lost, contents in both old and new
size are unchanged, and contents in the new (larger) size only are zeroed") — exactly
`Vec::resize`'s truncate / preserve / default-fill behavior.

### MIG-ARY-MULTIDIM — N-dim indexing ✅ done; `ATTACH` aliasing deferred
**N-dimensional row-major indexing done.** `a[i,j]` previously dropped all but the first
subscript, silently aliasing 2-D cells (`a[1,0]` and `a[1,1]` both hit `a[1]` → printed
`9,9` for distinct writes). Fixed by carrying extra subscripts as `Vec` fields alongside
the first (`Statement::Dim.extra_dims`, `Expression::ArrayAccess.extra_indices`,
`Statement::ArrayAssignment.extra_indices`, mirrored on Checked/IR) and a `TypedSlot`
shape (`dims`) with a Horner row-major `array_offset`; `DIM a[d0,d1,…]` allocates the flat
product and records the shape. **1-D byte-identical** (extras ignored in text-IR/C via
`..`; goldens + bootstrap fixed point unchanged; selfhost uses no arrays). Locked by
`interpreter.rs::two_dim_array_cells_are_distinct` (prints `7,9`).

**Still deferred: `ATTACH`** sub-array aliasing (`ATTACH bufferIndex[charCode,] TO a[]`),
the remaining blocker for `ary.x`'s `TestAryPerformance` (which also needs the 2-D buffer
index + is a 50k-iteration perf test). Real `ATTACH` = a view/alias binding between array
slots — a distinct feature. `ary.x` still parses+lowers (MIG-CORPUS-GATE) and stays out of
the `xbsourcelib_smoke_libs_run_clean` clean-run set.

### RT-KERNEL32 — kernel32/stdio stubs for `acgibin` `[verified 2026-08-17]`
`acgibin.x` needs `GetStdHandle`/`ReadFile`/`WriteFile` and the handle constants
`$$STD_INPUT_HANDLE=-10` / `$$STD_OUTPUT_HANDLE=-11`. Not implemented in the
interpreter runtime.

### CLI-STDIN — `xb --run` reads piped stdin ✅ done
`xb --run <file>` previously took input only from `--with-input <file>` and
ignored piped stdin, so every interactive program (`READLINE$` / `INLINE$`) saw
empty input. `run_path` now reads stdin (via `read_stdin_lines`) when no
`--with-input` is given: a terminal stdin is skipped so no-input/interactive runs
never block, and non-UTF-8 stdin is treated as empty (RT-BYTESTRING).
`printf 'hi\n' | xb --run echo.x` now feeds the program. Locked by
`cli.rs::cli_run_reads_piped_stdin_as_input`.

### RT-FUNCPTR — function-pointer calls (`afuntype`) ✅ done
`afuntype.x` calls through a `FUNCADDR` composite member: `dog.setName = &NameDog()`
then `@dog.setName (@dog, answer$)`. Two bugs made it silently wrong (printed `You claim
 has brown hair.` — empty name): `&NameDog()` **mis-lowered to a direct `call NameDog()`**
(the `&` dropped), and the indirect call had no dispatch + passed `@dog` as one unflattened
integer. Fixed in two sub-steps:
- **Sub-step 1 (`882cb70`)** — `&Func(...)` parses to a new `Expression::FuncAddr(name)`
  threaded through checked/IR/text-IR; the interpreter resolves it to the function's stable
  1-based id (`eval::function_id` walks top-level `IrItem::Function`, since `IrProgram` has
  no `functions` list); the C backend emits a real `((intptr_t)&func)` pointer.
- **Sub-step 2** — `parser.rs::type_stmt` now records `FUNCADDR` members (it only handled
  `Identifier` type-keywords; `FUNCADDR` is a `Keyword`, so `setName` was dropped from the
  DOG layout) and captures the member's `(DOG, STRING)` param signature on
  `TypeMember`/`CompositeMember`. `semantics_expr::call_stmt` derives `param_composites` from
  that signature so `flatten_call_args` flattens `@dog` → `(dog.name, dog.hairColor,
  dog.setName)` byref; and `call.rs` dispatches an unknown callee that is a slot holding a
  positive func-id to `function_name_by_id` → the real function (reusing the direct-call
  frame + byref write-back).

`afuntype` now prints **`You claim Rex has brown hair.`** Locked by
`interpreter.rs::{func_addr_yields_stable_function_id,
funcaddr_member_indirect_call_dispatches_and_writes_back}`. **Golden-safe**: selfhost uses
no `&Func()`/`FUNCADDR`, so text-IR for existing goldens and the bootstrap fixed point are
unchanged. `FUNCADDRESS` (the builtin) still returns `0` — no corpus program uses it; only
`&Func` + member dispatch (the `afuntype` path) is exercised.

### RT-FIXEDSTR — fixed-length string (`STRING*N`) composite members ✅ done
A composite TYPE member declared `STRING*N .m` was silently **dropped from the
layout entirely**: the TYPE-member parser matched only `TYPEKW . name`, and the
`*N` size spec between the keyword and the `.member` broke the match, so `.name` /
`.hairColor` / `STRING*32 .s` never became members and read back as Integer `0`.
Fixed in `parser.rs` (`type_stmt`): skip an optional `*<int>` before the `.`,
record the member with the type keyword's `is_string`, and use `N` as its byte
size. Repro now prints `fixed:hi var:yo` (was `fixed:0 var:yo`). Locked by
`interpreter.rs::fixed_length_string_composite_member_holds_string`. No
golden-bearing source (selfhost, positive corpus) uses `STRING*N` members, so the
bootstrap fixed point is unaffected.

### RT-BYREF — pass-by-reference (`@`) parameter write-back ✅ done
`@x` call arguments now write the callee's final parameter value back into the
caller's lvalue. `CheckedExprKind::ByRef` / `IrExprKind::ByRef` wrap by-ref *call
args only* (rvalue `@x` stays a plain symbol, preserving IR goldens); `call.rs`
records `(param, target)` pairs and copies them back after the call. Threaded
through lowering, interpreter eval, C emit (emits inner value; native C
write-back deferred, untested), and text-IR round-trip. Locked by
`interpreter.rs::by_ref_parameter_writes_back_to_caller`. Foundation for the
composite by-ref params below.

### RT-NESTED-COMPOSITE — nested composite TYPEs + composite params ✅ done
A TYPE member whose type is itself a composite (e.g. `GEO_BINODE` holds two
`GEO_BICOORD`s) flattens **recursively** into leaf struct-of-arrays slots
(`L1.a.x`) — `register_type` / `composite_decl` / `dim` (semantics*.rs), plus a
pre-existing bug where suffix-less non-Integer slots (incl. flat *float* composite
members) were overridden to Integer: dotted member slots now trust their declared
type (`symbol` / `assignment`).

**Composite parameters** (incl. by reference) now work: `Param` carries the
composite type + `@`; `FuncSig.param_composites` records them; `function()`
flattens a composite param into member `CheckedParam`s + member slots;
`flatten_call_args` expands composite call-args (with `@` members via RT-BYREF) to
match. Fixed en route: (a) **multi-variable composite decl** `T a, b` declared
only the first var (`composite_decl_stmt` skipped to line-end) — now one decl per
comma-separated var; (b) **mixed-numeric comparison** `a! = 0` (float vs integer
literal) errored (`compare` lacked Float/Integer arms) — now promotes int→float.

`XBSourceLib/geo/geo.x` runs end to end. Locked by `interpreter.rs`
(`composite_by_ref_parameter_writes_members_back`, `compares_float_to_integer_literal`,
`nested_composite_members_resolve_to_declared_float_type`) and
`xbsourcelib_run.rs::xbsourcelib_geo_runs_via_composite_params`.

## 3. Frontend / migration coverage

### MIG-CORPUS-GATE — legacy parse coverage gated by a test ✅ done
Combined parse coverage is **204/204** (151 `xbasic-6.4.5/*.x` + 13
`XBSourceLib/*.x` + 40 `XBSourceLib` source `.txt`). Now gated by
`crates/xb-compiler/tests/legacy_corpus.rs`
(`legacy_corpus_lowers_to_ir_without_swallow`): it walks both trees, requires
every file to parse+lower (the honest `rc == 0` metric — not "non-empty output",
not a min-IR-line threshold), and flags swallow regressions (a `>20`-source-line
file collapsing to `<=2` IR lines). Floors pin current counts (≥151 / ≥13 / ≥40,
≥204 total); additions must still lower, removals fail the gate.

### MIG-SEMANTICS — run-level fixtures landed for clean libs `[verified 2026-08-17]`
Beyond parse/lower (MIG-CORPUS-GATE), `crates/xb-runtime/tests/xbsourcelib_run.rs`
now runs core libs through the interpreter: `utils/mergeTest01`/`mergeTest02` run to a
clean exit; **`msc.x` round-trips fully** — `MscStrHex$` (string→hex) *and* the
`MscHexStr$` decode line are locked correct (RT-BYTESTRING + SEL-CASE-TRUE +
VAR-SUFFIX-COLLISION + GOSUB-SCOPE together closed it); **`geo.x` runs** end to end via
composite params (RT-NESTED-COMPOSITE). `ary.x` parses+lowers (MIG-CORPUS-GATE) but its
`TestAryPerformance` needs MIG-ARY-MULTIDIM, so it is out of the clean-run smoke set.

### MIG-RUNTIME-SWEEP — legacy runtime coverage measured end to end `[verified 2026-08-17]`
Beyond parse/lower (MIG-CORPUS-GATE, 204/204), the runnable *programs* were run
through the interpreter and classified. Of **130** candidate programs — 114
`demo/*.x` + 3 `helpsrc/help_program/*.x` + 13 `XBSourceLib/*.x` — **84 run to a
clean exit**, **46 are platform/library-blocked** (43 GUI = 40 message-loop
timeouts + 3 GUI-init overflows; 1 Win32 console `acgibin`/RT-KERNEL32; 1 X11/GDI
graphics `DrawScaled`; 1 unlinked Xst std-lib `qbtoxb`/`XstLoadStringArray`), and
**0 fail for a genuine interpreter/language reason**. Libraries are not standalone
programs: `src/shared/*` (6, platform-neutral) and `src/linux/*` (9, the platform
deps themselves) parse+lower but are linked, not run; `demo/gtk/*` (19) are GTK
GUI. Conclusion: **all legacy code that does not depend on platform features (GUI,
Win32/kernel32, X11/GDI, sockets) or on an unlinked standard library is workable**
through the interpreter.

Correctness note (2026-08-18): `afuntype` was the one program that exited cleanly but
printed **wrong** output (empty name — the funcptr call was a silent no-op). RT-FUNCPTR
fixed it (`You claim Rex has brown hair.`), so the non-GUI/non-platform corpus now has
**zero genuine failures and zero known silent-wrong-output bugs**.

## 4. Demos / GUI

### DEMO-RUNTIME — 68/114 demos run clean `[verified 2026-08-17]`
Re-measured with `xb --run` (6 s timeout, `</dev/null`): **68 / 114**
`xbasic-6.4.5/demo/*.x` reach a clean exit; **40** are GUI message-loop timeouts,
**3** are GUI-init stack overflows (`agrids`, `warning`, `xgrids`), and **3** are
platform/library-blocked — `DrawScaled` (`XgrCreateWindow`; div-by-zero from a 0
display size), `acgibin` (RT-KERNEL32), and `qbtoxb` (`XstLoadStringArray`, an Xst
std-lib function not linked into the standalone interpreter). **Zero of the 46
non-clean demos fail for a non-platform, non-library reason.** GUI runtime (winit +
softbuffer GDI-shim, per `docs/12`) is a large separate effort, intentionally
deferred.

Re-measured 2026-08-18 (after the msc-saga + MIG-ARY-REDIM fixes): demo-only is still
**68/114** — the session's runtime gains landed in the *libraries* (`msc`/`geo`/`mergeTest`
now run; the `ary` `REDIM a[UBOUND(a[])+N]` idiom works), not the GUI-heavy demos. The 6
non-timeout errors are all GUI/platform/library: `qbtoxb`/`DrawScaled`/`acgibin`, and
`agrids`/`warning`/`xgrids` now surface as `unknown runtime slot func` (the GUI builtin
`XuiGetDefaultMessageFuncArray(@func[])` never allocates the by-ref array) rather than the
earlier stack overflow. `ary`×2 need MIG-ARY-MULTIDIM. **Still 0 genuine interpreter
failures.**

## 5. Cross-references

- Two-C-generator drift and byte-identity: **16-cgen-cemitter-sync-roadmap.md**.
- Backend rationale / crate survey: **12-rust-llvm-rewrite-survey.md**.
- Stage status and decisions: **13-bootstrap-scaffold.md**, **14-self-hosting-progress.md**.
