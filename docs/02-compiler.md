# 02 — The XBASIC Compiler (`xcol.x` / `xcow.x`)

The compiler is itself an XBASIC program — the whole toolchain is self-hosted. The Linux
compiler is `src/linux/xcol.x` (28,155 lines); the Windows compiler is `src/win32/xcow.x`
(27,553 lines). The two are ~88.5% identical; the only real difference is the object-file
and linker layer (ELF on Linux, PE/COFF on Windows).

## 1. File header and the portability warning

```
' ####################  Max Reason
' #####  PROLOG  #####  copyright 1988-2000
' ####################  XBasic compiler
' subject to GPL license - see COPYING
' maxreason@maxreason.com
' for Linux XBasic
' for Windows XBasic
'
' ................  XBasic is written in XBasic.
' ................  In XBasic, user and system symbol names are interchangeable.
' ................  The /xxx/ and /XXX/ forms of a name are identical because the
' ................  symbol table does not preserve case and the tokenizer has an
' ................  option to swap the case of user symbols.
' ................  Consequently, all system functions and variables are declared
' ................  in lower case (e.g. /xst/), and when the compiler compiles itself
' ................  with the case-swap option, the system names are the only ones
' ................  that remain lowercase (because they are protected). All user
' ................  names are uppercase.
```

- **License**: GPL (`COPYING`).
- **Self-compilation**: the case-swap mechanism (`/xxx/` ↔ `/XXX/`) is the key trick that
  lets the compiler compile itself: system names are declared lowercase and protected,
  user symbols get uppercased by the tokenizer option.

## 2. Phase pipeline

There are **two passes**, not a classic multi-pass optimizer:

1. **PASS 0 — tokenize.** The entire source is tokenized into per-line token arrays.
   Each line is a `tok[]` array of 32-bit bitfield-packed token words.
2. **PASS 1 — compile.** One sweep through the lines via
   `CheckOneLine` (2617) → `CheckState` (2702, statement dispatch) with
   `Eval` (13037) / `Expresso` (14186, a Pratt-style expression parser) for
   expressions and `Code()` (7715) / `EmitBin` / `EmitAsm` for code generation.

### Two drivers

- **Console driver**: `Compile` (10669) / `CompileFile` (10830) — used by the
  `xb` command-line compiler.
- **PDE driver**: the IDE calls the `Xxx*` function API directly (see §5), enabling
  in-memory compile and edit→run without writing files.

### Two backends, selected at runtime

The compiler targets two backends, selected by mode flags (not build flags):

| Flag | Emitter | Target | Used by |
|---|---|---|---|
| `i486asm` | `EmitAsm` (12544) | GNU-as textual assembly (`.s` files) | disk builds: `xb prog.x -lib` etc. |
| `i486bin` | `EmitBin` (7777) | raw i486 machine code emitted directly into memory | PDE in-memory compile |

The dominant fork in the emitter is:
```
SELECT CASE TRUE
    CASE i486bin: GOSUB EmitBin
    CASE i486asm: GOSUB EmitAsm
END SELECT
```
This appears in `EmitFunctionLabel`, `EmitLabel`, `EmitUserLabel`, `EmitLine`,
`EmitString`, `XxxLoadLibrary`, `XxxUndeclaredFunction`.

## 3. Token representation

- Token words are 32-bit bitfield-packed; the tokenizer (`ParseLine` 22983,
  `ParseNumber` 23139, `ParseSymbol` 23334, `ParseChar` 22598, `ParseWhite` 23597,
  `ParseOutToken` 23257, `TokenRestOfLine` 25040) builds per-line `tok[]` arrays.
- Parallel symbol/function/label/type tables are kept by `AddSymbol` (1429),
  `AddLabel` (1334), `AssignAddress` (1798).
- `##`-prefixed names are compile-time constants AND runtime system variables.
  `#`-prefixed names are hashed dynamic variables (per-instance storage):
  `#emitasm`, `#immediatemode`, `#asm$[]`, `#asmupper`, `#asmnext`.

## 4. Code generation

- **Strings** are emitted as 16-byte chunk headers + `.string` body:
  `.long chunk,0,len,0x80130001` followed by the string data.
- **Function frames**: `push ebp / mov ebp,esp / sub esp,frame` with `esi/edi/ebx`
  saved at `ebp-12/-16/-20`.
- **User labels** are mangled `_g_` / `_s_` prefixed.
- **Assembler dialect differences** are handled by dual-maintained comments, e.g.:
  - `'.byte	"..."' ' spasm` vs `'.string "..."' ' gas ?` (12933–12935)
  - `"	movsbl	" ' gas` vs `"	movsx	" ' spasm` (8623–8624)
  - suffix = `RINSTR (s$, ".")` ' gas ? vs `suffix = RINSTR (s$, "_")` ' unspas (12658–12659)
  - `"XxxXProfilerLog$8" ' gas ?` vs `"XxxXProfilerLog_8" ' unspas` (26982–26983)

### Key emitter functions

| Function | Line | Purpose |
|---|---|---|
| `Code` | 7715 | emit instruction (central) |
| `EmitBin` / `EmitInstruction` / `EmitImm` | 7777 / 7847 / 8586 | in-memory machine code |
| `EmitAsm` | 12544 | textual assembly |
| `EmitData` | 12759 | data section |
| `EmitLabel` / `EmitFunctionLabel` / `EmitUserLabel` | 12805 / 12774 / 12992 | label emission |
| `EmitLine` | 12839 | line number tracking |
| `EmitString` | 12894 | string constants |
| `EmitNull` | 12879 | null emission |
| `AssemblerSymbol` | 1757 | symbol ↔ assembler name |

## 5. The `Xxx*` API — how the PDE drives the compiler

The compiler exposes its entire functionality as `Xxx*` EXTERNAL functions that the
IDE (`xit.x`) calls. This is the integration contract:

| Function | Line | Purpose |
|---|---|---|
| `XxxXBasicVersion$()` | 26164 | version string |
| `XxxCheckLine(lineNum, tok[])` | 26174 | compile one tokenized line |
| `XxxCloseCompileFiles()` | 26197 | close `.s`, write `.dec`/`.def` |
| `XxxCompilePrep()` | 26284 | clear DECLARE/DEFINED bits, label addresses, patch arrays |
| `XxxCreateCompileFiles()` | 26403 | open `prog.s` |
| `XxxDeleteFunction(funcNumber)` | 26559 | clear a function's records |
| `XxxDeparseFunction(func$, func[], lastLine, flags)` | 26577 | render a function's tokens back to text |
| `XxxDeparser(tok[], deparsed$)` | 26832 | render one token line to text |
| `XxxEmitXProfilerCall(func, line)` | 26979 | emit profiler hook call |
| `XxxErrorInfo(err, rawPtr, srcPtr, srcLine$)` | 26996 | error position for editor |
| `XxxFunctionName(command, funcName$, funcToken)` | 27062 | get/set function name |
| `XxxGetAddressGivenLabel(label$)` | 27090 | label→addr |
| `XxxGetFunctionVariables(...)` | 27137 | variables of a function |
| `XxxGetLabelGivenAddress(addr, labels$[])` | 27236 | reverse label lookup |
| `XxxGetPatchErrors(...)` | 27264 | forward-ref patch errors |
| `XxxGetProgramName(@name$)` | 27284 | program name |
| `XxxGetSymbolInfo(...)` | 27300 | symbol record readout |
| `XxxGetUserTypes(varTypes$[])` | 27317 | user composite type names |
| `XxxGetXerror$(err)` | 27338 | error message string |
| `XxxInitAll()` | 27353 | **master init** (see below) |
| `XxxInitParse()` | 27369 | reset parse state |
| `XxxInitVariablesPass1()` | 27381 | reset compiler state for a compile |
| `XxxLibraryAPI(lib$)` | 27481 | check lib in syslib.xxx list |
| `XxxLoadLibrary(token)` | 27502 | compile/import a `.dec` library |
| `XxxParseSourceLine(sourceLine$, tok[])` | 27710 | tokenize one source line |
| `XxxPassFunctionArrays(...)` | 27723 | ATTACH-based array swap |
| `XxxParseLibrary(token)` | 27751 | pre-parse TYPE statements of imported libs |
| `XxxPassTypeArrays(...)` | 27859 | ATTACH-based type-table swap |
| `XxxSetProgramName(name$)` | 27915 | set program name/path |
| `XxxTheType(token, funcNumber)` | 27935 | type of token in function context |
| `XxxUndeclaredFunction(funcToken)` | 27950 | lazy library-function declaration resolution |
| `XxxXntBlowback()` | 28082 | call library blowback entry points |
| `XxxXntFreeLibraries()` | 28124 | FreeLibrary all external libs |

`XxxInitAll` (27353) is the master init chain:
`InitArrays → InitEntry → InitErrors → XxxInitParse → InitProgram → InitVariables → TokensDefined → InitComplex`.

### The PDE compile flow

As driven by `xit.x` (xit.x 14339–14454):

```
i486asm = FALSE; i486bin = TRUE
XxxInitVariablesPass1()
XxxCompilePrep()
compile PROLOG (prog[0])
compile entry function (prog[entryFunction])
for each prog[func]: XxxParseSourceLine / XxxCheckLine (CompileLine)
XxxParseSourceLine("END PROGRAM")
```

For disk builds, `xit.x` uses `XxxCreateCompileFiles` / `XxxCloseCompileFiles`
(xit.x 14745). Source viewing/editing uses `XxxDeparser` / `XxxDeparseFunction` /
`XxxParseSourceLine` (xit.x 4498, 19109, 20527…). Errors go through `XxxErrorInfo`
(xit.x 20378). `XxxInitAll` is also called by the PDE at startup (xit.x 21326).

### Shared `/xxx/` globals with the IDE

The `EXTERNAL /xxx/` globals shared with xit.x (254–266): `i486asm, i486bin, library,
freezeFlag, bogusFunction, freezeFunction, checkattach, checkBounds, entryFunction,
maxFuncNumber, xpc, errorCount, litStringAddr`.

## 6. Platform conditional mechanism

There are **no `#ifdef`-style preprocessor directives** (no `##IFDEF` etc.).
Portability is handled by:

1. **The `/xxx/` ↔ `/XXX/` case-swap renaming** — the only "compiler" conditional.
2. **Runtime mode flags** `i486asm` / `i486bin` — the dominant fork.
3. **`##`-prefixed external system variables** (memory-mapped, set by PDE/runtime):
   `##UCODE`, `##UCODEZ`, `##DATAZ`, `##GLOBAL0`, `##GLOBALZ`, `##GLOBAL`, `##GLOBALX`,
   `##XBDir$` (`"/usr/xb"`), `##ERROR`, `##ENTERED`. `##GLOBAL0`/`##GLOBALZ` bound the
   global-data allocator (2118–2214).
4. **`#`-prefixed hashed dynamic variables** — per-instance storage.
5. **Linux-specific code**: `GetExternalAddresses` reads ELF directly
   (`elf.e_ident[1]='E'…`); Windows remnants appear as commented notes.
6. **`##WHOMASK` / `##LOCKOUT` are NOT in xcol.x** — they belong to the interpreter
   (`xin.x`, lines 206–215). In xcol.x only `OBJECT.whomask` (line 57) remains.

## Function map (cross-reference)

- **Tokenizer**: `ParseLine`(22983), `ParseNumber`(23139), `ParseSymbol`(23334),
  `ParseChar`(22598), `ParseWhite`(23597), `ParseOutToken`(23257), `TokenRestOfLine`(25040),
  `MakeToken`(20969), `Tok`(25016), `TokensDefined`(25062), `NextToken`(21353)
- **Parser/checker**: `CheckOneLine`(2617), `CheckState`(2702), `Eval`(13037),
  `Expresso`(14186), `ExpressArray`(13087), `Op`(21433), `Uop`, `Conv`(11509), `Move`(21045),
  `GetArg`(18164), `Push`/`Pop`/`Shuffle`/`StackIt`, `GetTokenOrAddress`(18813),
  `FunctionCallPrep/Post`(18142/18153)
- **Symbols/types**: `AddSymbol`(1429), `AddLabel`(1334), `AssignAddress`(1798),
  `TheType`(190), `ScopeToken`, `TypenameToken`, `TypeToken`, `UpdateToken`,
  `GetSymbol$`(18751)
- **Init**: `XxxInitAll`(27353), `InitArrays`(19048), `InitComplex`(20475),
  `InitEntry`(20594), `InitErrors`(20607), `InitOptions`(20714), `InitProgram`(20725),
  `InitVariables`(20738), `GetExternalAddresses`(18222)
- **Deparse**: `Deparse$`(12609), `XxxDeparser`(26832), `XxxDeparseFunction`(26577)
- **File/side outputs**: `Compile`(10669), `CompileFile`(10830),
  `XxxCreateCompileFiles`(26403), `XxxCloseCompileFiles`(26197),
  `WriteDeclarationFile`(26096), `WriteDefinitionFile`(26122)

## Accuracy notes

- The `OBJECT` TYPE is declared but unimplemented in xcol.x.
- The two "passes" are tokenization + one-sweep compile, not classic multi-pass optimization.
- `##WHOMASK`/`##LOCKOUT` belong to `xin.x`, not `xcol.x`.

## Related files

- `src/linux/xcol.x` — the Linux compiler (28,155 lines)
- `src/win32/xcow.x` — the Windows compiler (27,553 lines)
- `src/linux/elf32.x` — ELF parsing used by `GetExternalAddresses()`
- `src/linux/lib/appstart.s` — runtime assembly the emitted `.s` files link against
- `src/linux/xin.x` — interpreter where `##WHOMASK`/`##LOCKOUT` actually live
- `src/linux/xit.x` — the PDE that drives the compiler via the `Xxx*` API
