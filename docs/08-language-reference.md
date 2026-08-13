# XBASIC 6.2.3 — Language Reference (from the shipped help files)

Compiled from the distribution's own help databases: `help/language.hlp`
(261 entries), `help/operator.hlp` (operator table), and `help/command.hlp`
(PDE dot commands). All help files are plain text in XBASIC's own format
(`'` comment lines / `:label` help keys) — the PDE renders them in a help
grid.

## 1. Data Types

XBASIC is a **typed** BASIC with a rich set of machine-oriented types. The
`language.hlp` "catagory" column marks entries as *intrinsic* (compiler
built-in) or provided by a library (`xma`, `xst`, ...).

### Numeric types

| Type | Meaning |
|---|---|
| `SBYTE` / `UBYTE` | signed / unsigned 8-bit integer |
| `SSHORT` / `USHORT` | signed / unsigned 16-bit integer |
| `SLONG` / `ULONG` | signed / unsigned 32-bit integer |
| `XLONG` | 32-bit type used for TRUE/FALSE results (see operator table) |
| `SINGLE` | 32-bit floating point |
| `DOUBLE` | 64-bit floating point |
| `GIANT` | 64-bit integer (high/low 32-bit halves accessible via `GHIGH`/`GLOW`/`GMAKE`) |
| `SCOMPLEX` / `DCOMPLEX` | single / double precision complex numbers (used with `xcm`) |
| `STRING` | variable-length byte string |
| `BITFIELD` | bit-field constant or variable (`MAKE()`, `SET()`, `CLR()`, `EXTS()`, `EXTU()`) |
| `FUNCADDR` / `SUBADDR` / `GOADDR` | function, subroutine, and GOTO-label addresses (first-class code pointers) |

### Pointer/address intrinsics

Every numeric type has a `XxxAT()` pair to **read/write at an absolute
memory address** — XBASIC is a systems language:

- `SBYTEAT`, `UBYTEAT`, `SSHORTAT`, `USHORTAT`, `SLONGAT`, `ULONGAT`,
  `XLONGAT`, `SINGLEAT`, `DOUBLEAT`, `GIANTAT`
- Address-of operators: `&` (address of object data), `&&` (address of
  object handle)
- Conversion: `SMAKE()` (int → SINGLE), `DMAKE()`/`GMAKE()` (two 32-bit →
  DOUBLE/GIANT), `XMAKE()` (retype to XLONG, MSW for GIANT/DOUBLE),
  `DHIGH`/`DLOW`, `GHIGH`/`GLOW`

### Composite types

`TYPE ... END TYPE` and `UNION` define user composite types. Structures were
limited to 64 KB until the 6.2.1 fix ("Removed 64KB limit of structures").
`ATTACH` binds one array/subarray to another; `DIM`/`REDIM` allocate and
resize arrays (`REDIM` preserves contents); `UBOUND()` reads bounds;
`SIZE()`/`TYPE()` introspect values.

## 2. Scoping Model

Variables and functions carry explicit scope:

| Scope keyword | Meaning |
|---|---|
| `AUTO` / `AUTOX` | automatic (stack) variables — `CLEAR AUTOS` resets them |
| `STATIC` | persistent across calls |
| `SHARED` | shared module-wide |
| `EXTERNAL` | provided by another module |
| `INTERNAL` | visible only within the module |
| `LIBRARY` | compile the file as a function library (statement) / test if compiled as a library (`LIBRARY(0)`) |

## 3. Statements and Control Flow

- **Blocks**: `IF ... THEN ... ELSE ... ENDIF` (with `IFT`, `IFF`, `IFZ`
  variants testing true/false/zero), `SELECT CASE ... END SELECT` (with
  `ALL` to execute all matching cases, `TRUE`/`FALSE` as case selectors),
  `DO ... LOOP` (with `WHILE`/`UNTIL`), `FOR ... TO ... STEP ... NEXT`.
- **Subroutines**: `GOSUB`/`RETURN` (local), `GOTO label`, `SUB`/`END SUB`,
  `FUNCTION ... END FUNCTION`, `EXIT` (leave a block or function), `END`.
- **Declarations**: `DECLARE` (prototype), `DIM`, `REDIM`, `TYPE`, `UNION`,
  `AUTO(S)`, `STATIC`, `SHARED`, `EXTERNAL`, `INTERNAL`, `CFUNCTION` (C
  callable), `SFUNCTION` ("system" function).
- **Arithmetic**: `INC`, `DEC`, `SWAP` (typed swap; string/composite/array
  element support fixed across 6.2.1–6.2.2).
- **I/O**: `PRINT`, `READ`, `WRITE`, `OPEN()`, `CLOSE()`, `SEEK()`, `EOF()`,
  `LOF()`, `POF()`, `INFILE$()`, `INLINE$()`, `SHELL()`.
- **Process control**: `QUIT()`, `STOP`, `STOP`/`END`, `ERROR()` (get/set
  `##XERROR`), `ERROR$()` (number → message).

## 4. Operators (full table, from `operator.hlp`)

### Bitwise (integer only)

| Op | Alt | Meaning |
|---|---|---|
| `~` | `NOT` | bitwise NOT |
| `&` | `AND` | bitwise AND |
| `^` | `XOR` | bitwise XOR |
| `\|` | `OR` | bitwise OR |
| `<<` / `>>` | | bitwise left/right shift (zero fill) |
| `<<<` / `>>>` | | arithmetic up/down shift (sign-extending down-shift) |

### Logical

| Op | Alt | Meaning |
|---|---|---|
| `!!` | | logical TEST (TRUE if nonzero) |
| `!` | | logical NOT |
| `&&` | | logical AND |
| `^^` | | logical XOR |
| `\|\|` | | logical OR |

### Comparison

| Op | Alt | Meaning |
|---|---|---|
| `=` / `==` | | equal |
| `<>` / `!=` | | not equal |
| `<` / `!>=` | | less than |
| `<=` / `!>` | | less-or-equal |
| `>` / `!<=` | | greater than |
| `>=` / `!<` | | greater-or-equal |

Comparison operates on numbers **and strings**; results are always XLONG
TRUE/FALSE.

### Arithmetic

| Op | Meaning |
|---|---|
| `+` `-` `*` `/` | add, subtract, multiply, floating divide |
| `\` | integer divide |
| `MOD` | modulus (integer remainder) |
| `**` | raise to power (also `POWER()` in `xma`) |
| `+` (string) | string concatenation |

### Precedence (1 = lowest)

```
1  assignment (=)
2  logical OR (||), logical XOR (^^)
3  logical AND (&&)
4  =  ==  <>  !=   (equality)
5  <  >  <=  >=  !<  !>  !<=  !>=  (ordering)
6  bitwise OR (|), XOR (^)
7  bitwise AND (&)
8  +  -  (add/subtract/concatenate)
9  *  /  \  MOD
10 **  (power)
11 <<  >>  <<<  >>>  (shifts)
12 unary + - ! !! NOT  &  &&
```

The operator table in `help/operator.hlp` also documents each operator's
`KIND` (unary/binary), `CLASS` (numeric/string/integer/numstr), operand and
return types, and precedence — this is the table the compiler implements.

## 5. Intrinsic String Functions

`ASC()`, `CHR$()`, `CSTRING$()` (C string → native), `CSIZE()`/`CSIZE$()`
(null-clip), `STUFF$()` (insert into string), `MID$()`, `LEFT$()`,
`RIGHT$()`, `LEN()`, `SIZE()`, `NULL$()` (n nulls), `SPACE$()`, `TAB()`,
`INSTR()/INSTRI()/RINSTR()/RINSTRI()` (find, case-sensitive/insensitive,
forward/reverse), `INCHR()/INCHRI()/RINCHR()/RINCHRI()` (find set member),
`TRIM$()/LTRIM$()/RTRIM$()`, `LCLIP$()/RCLIP$()` (clip n bytes),
`LCASE$()/UCASE$()`, justification `LJUST$()/RJUST$()/CJUST$()`.

## 6. Numeric Formatting & Conversion

- `STR$()/STRING()/STRING$()` (signed), `SIGNED$()` (always signs),
  `FORMAT$()` (formatted output), `HEX$()/HEXX$()` (`0x` prefix),
  `OCT$()/OCTO$()` (`0o` prefix), `BIN$()/BINB$()` (`0b` prefix).
- Conversion functions for every type (`DOUBLE()`, `SINGLE()`, `INT()`,
  `FIX()` round-toward-zero, `SGN()/SIGN()`).

## 7. Math Library Functions (`xma`, from `language.hlp` + `amath.hlp`)

Trigonometric and hyperbolic in both directions: `SIN COS TAN COT CSC SEC`
and `ASIN ACOS ATAN ACOT ASEC ACSC`, plus `SINH COSH TANH COTH SECH CSCH`
and `ASINH ACOSH ATANH ACOTH ASECH ACSCH`; `EXP EXP10 LOG LOG10 POWER SQRT`.
The `amath.hlp` file documents a graph-drawing sample program (`Math`) that
plots all of these — a shipped demonstration of the `xgr` graphics library.

## 8. Bit & Integer Utilities

`MAKE()` (build bitfield), `SET()` (set bits), `CLR()` (clear bits),
`EXTS()/EXTU()` (signed/unsigned field extraction), `ROTATEL()/ROTATER()`
(rotate word), `HIGH0()/HIGH1()` (find most significant 0/1 bit),
`MAX()/MIN()`.

## 9. Files, Console, Shell

`OPEN/CLOSE/READ/WRITE/PRINT/SEEK/EOF/LOF/POF` for disk, console, and
communications files; `INFILE$()`; `INLINE$()` reads a line from the main
console; `SHELL()` executes a command line.

## 10. The PDE "Dot Command" Interface (`command.hlp`)

The PDE's command grid accepts `.command` lines — a keyboard-driven front-end
to every menu. Syntax:

```
.<command>[<space><argument>[<tab><argument>]]
```

Highlights:

- **Files**: `.fn t|p|g` (new text/program/GUI program), `.ft`, `.fl`, `.fs`,
  `.fm t|p`, `.fr`, `.fq` (quit).
- **Edit**: `.ec` cut, `.eg` grab, `.ep` paste, `.ed` delete, `.eb` buffer,
  `.ei` insert, `.ee` erase, `.ef` find, `.er/.ew` read/write files.
- **View**: `.vf/.vp/.vn/.vd/.vr/.vc` function view/navigation, `.vl/.vs`
  load/save functions.
- **Run**: `.rs` start, `.rc` continue, `.rj` jump to line, `.rp` pause,
  `.rk` kill, `.rr` recompile, `.ra` compile-to-assembly, `.rl` library.
- **Debug**: `.dt` toggle breakpoint, `.dc/.de` clear, `.dm` memory window,
  `.da` assembly window, `.dr` registers window.
- **Status**: `.sc` compile errors, `.sr` runtime error.
- **Help**: `.hn/.hs/.hm/.hl/.ho/.hd` open each `.hlp`.
- **Find/replace** shorthand: `.f` / `.r` immediate, with repetition
  `.*r PIRNT PRINT` style syntax (space-delimited find, tab-delimited
  replace).
- **Navigation**: `.s#` set tag, `.j#` jump to tag, `.#` scroll to line,
  `.` show line number, `.v` next function, `.v-` previous, `.v0` PROLOG,
  `.a` repeat, `.h` help.

This command interface is notable: it exposes the whole PDE as a
keyboard-driven tool, making the IDE scriptable from the keyboard without a
scripting language.

## 11. Grid Message Constants (`help/message.hlp`)

`message.hlp` documents the **grid message protocol** of the GUI toolkit —
the `#Message` constants sent to grid callback functions. Excerpt:

```
grid,  #Create      xWin  yWin  width  height  window  parent
grid,  #CreateWindow xDisp yDisp width height windowType display$
grid,  #Destroy
grid,  #CloseWindow
grid,  #DisplayWindow
grid,  #Disable
grid,  #Enable
grid,  #Enter
grid,  #Find  #FindForward  #FindReverse
grid,  #GetCallback  @callbackGrid  @callbackFuncAddr
grid,  #GetColor  @background @drawing @lowlight @highlight
grid,  #GetFont   @size @weight @italic @angle @typeface$
grid,  #GetSize   @x @y @width @height
grid,  #GetTextArray  @text$[]
...
```

This is the message-passing API the GUI toolkit (`xui.x`) implements — see
[`05-ide.md`](./05-ide.md) and the callback skeleton in
`templates/code.xxx` (`#Callback`, `#Selection`, `#TextEvent`,
`#CloseWindow`).

## 12. XBASIC Source File Conventions

- `'` starts a comment; the `' ####### Name #######` banner style is used
  for function headers throughout the source tree.
- `##NAME` = compiler directive / runtime system variable; `$$NAME` =
  shared constant (see [`01-architecture.md`](./01-architecture.md) §6).
- Statement separators: `:` allows multiple statements per line (used
  heavily in library sources).
- `' comment` after code on the same line is common.