VERSION "0.1"
FUNCTION Main
DIM src$
DIM line$
DIM tok$
DIM tk$
DIM pos
DIM ch
DIM ch2
DIM ntok
DIM done
' tt$/tv$ are sized after the source is joined (see the token-table DIMs
' below); declared unsized here so they live on the heap.
DIM tt$[]
DIM tv$[]
DIM tpos
DIM indent
DIM i
DIM j
DIM k
DIM t$
DIM v$
DIM prefix$
DIM spOp
DIM spVal
DIM expectOp
DIM edone
DIM popPrec
DIM parenDepth
DIM opStack$(256)
DIM opPrec(256)
DIM valStack$(256)
DIM valType$(256)
DIM pendingOp$
DIM pendingPrec
DIM prec
DIM bop$
DIM bleft$
DIM bright$
DIM blt$
DIM brt$
DIM bres$
DIM fname$
DIM funcName$(64)
DIM funcStart(64)
DIM funcSP
DIM fnargs
DIM nargs
DIM cir$
DIM fargs$[]
DIM iname$
DIM vname$
DIM vtype$
DIM eir$
DIM etype$
DIM isStop
DIM stopPop
DIM stmtState
DIM exprStop$
DIM an$
DIM bn$
DIM vt$
DIM cname$
DIM cval$
DIM assignTarget$
DIM assignType$
DIM forVar$
DIM forStart$
DIM forEnd$
DIM doMode$
DIM arrName$
DIM arrIndex$
DIM dimName$
DIM dimType$
DIM ifDepth
DIM ifStack(64)
DIM ifSP
DIM singleLineIf
DIM midTarget$
DIM midStart$
DIM midLen$
DIM arrNames$[]
DIM arrSP
DIM isArr
DIM lookPos
DIM parenCount
DIM params$
DIM pname$
DIM esc$
DIM ei
' Size-driven tables are unsized (heap, auto-grow on indexed write): the
' fixed (64)/(8) forms overflowed their stack VLAs on the core libs
' (xcol.x: 485 $$ constants, 15-arg calls; xui.x: 274 DIMs) -> SIGSEGV.
' Depth stacks (opStack/valStack 256, funcName/ifStack 64) stay fixed:
' they bound nesting, not program size.
DIM constName$[]
DIM constType$[]
DIM constValue$[]
DIM nConst
DIM ci
DIM isFloat
DIM subName$
DIM curScope$
DIM facetDump
DIM fTab$
DIM fSeen$
DIM fScopeArrs$
DIM fTypeNames$
DIM fp
DIM fsp
DIM fdep
DIM frk
DIM fnm$
DIM ftp$
DIM fst$
DIM fLn$
DIM fKey$
DIM ftmp$
DIM fSharedTop$
DIM fSharedFn$
DIM fIsType
DIM fi
DIM fpc
DIM fRedimMode
##suffixType$ = ""
DIM fListShared
DIM fFirstQual
DIM fEnd
DIM fMore
DIM fIsDef
DIM fCompSkip
DIM fQuit
DIM up
DIM udep
DIM uSzDep
DIM uSwap
DIM un
DIM uPreOk
DIM uPreScope$
DIM uPreBase$
DIM fNonStr$
DIM fInherit
DIM urdep
DIM ufresh
DIM udecl
DIM fNameSk
DIM ucurScope$
DIM uprev$
DIM uInType
DIM ue1
DIM ue2
DIM up0
DIM ueol
DIM udp
DIM fInType
DIM ufound
DIM ui
DIM uch
DIM uDone
DIM fIsKw
DIM uCallDepth
DIM uPos
DIM fSized
DIM uArmCall
DIM uChanged
DIM uIter
DIM uIsDesc
nConst = 0
' Line table: unsized (heap, auto-grow on indexed write - the 2026-09-02
' unsized-DIM contract) instead of a fixed VLA. xui.x is 41958 lines; the
' old srcLines$(20000) silently wrote past the stack array in native C.
DIM srcLines$[]
nLines = 0
totalLen = 0
WHILE EOF() = 0
  nLines = nLines + 1
  srcLines$(nLines) = READLINE$()
  totalLen = totalLen + LEN(srcLines$(nLines))
  IF EOF() = 0 THEN
    totalLen = totalLen + 1
  END IF
WEND
src$ = SPACE$(totalLen)
srcPos = 1
FOR i = 1 TO nLines
  line$ = srcLines$(i)
  lineLen = LEN(line$)
  IF lineLen > 0 THEN
    MID$(src$, srcPos, lineLen) = line$
  END IF
  srcPos = srcPos + lineLen
  IF i < nLines THEN
    MID$(src$, srcPos, 1) = CHR$(10)
    srcPos = srcPos + 1
  END IF
NEXT i
' Token tables: sized from the joined source once its length is known
' (tokens <= characters), on the heap via the same unsized-then-sized
' contract. The old fixed 131072 overflowed on xcol/xgr/xit/xui
' (147K-294K tokens) -> SIGSEGV; and at 393216 x 2 x 8 B the VLAs alone
' would exceed the 8 MB main-thread stack.
DIM tt$[LEN(src$) + 1]
DIM tv$[LEN(src$) + 1]
' P1 facet dump hook (docs/19 §9.4): a leading ##FACETS## line asks for
' facet lines only instead of normal emission. Normal path sees one extra
' IF evaluation and is otherwise untouched.
facetDump = 0
IF nLines >= 1 THEN
  IF srcLines$(1) = "##FACETS##" THEN
    facetDump = 1
  END IF
END IF

ntok = 0
pos = 1
WHILE pos <= LEN(src$)
  ch = ASC(MID$(src$, pos, 1))
  IF ch = 32 OR ch = 9 OR ch = 13 THEN
    pos = pos + 1
  ELSEIF ch = 39 THEN
    ' Quote handling: a quote that is the first non-whitespace on its line
    ' always opens a comment (covers indented ' comments containing
    ' apostrophes like Don't). Otherwise a later quote on the line makes
    ' it a char/string literal - skip to the match (emitting a string
    ' token so brackets around it never read as empty) so surviving
    ' parens keep call tracking balanced; with no match it is a comment.
    fi = pos - 1
    fIsType = 0
    WHILE fi >= 1 AND fIsType = 0
      ch2 = ASC(MID$(src$, fi, 1))
      IF ch2 = 10 THEN
        fIsType = 1
      ELSEIF ch2 <> 32 AND ch2 <> 9 AND ch2 <> 13 THEN
        fIsType = 2
      END IF
      fi = fi - 1
    WEND
    IF fIsType = 0 THEN
      fIsType = 1
    ELSEIF fIsType = 2 THEN
      fIsType = 0
    END IF
    IF fIsType = 0 THEN
      fIsType = 1
      fi = pos + 1
      WHILE fi <= LEN(src$) AND ASC(MID$(src$, fi, 1)) <> 39 AND ASC(MID$(src$, fi, 1)) <> 10
        fi = fi + 1
      WEND
      IF fi <= LEN(src$) AND ASC(MID$(src$, fi, 1)) = 39 THEN
        fIsType = 0
      END IF
    END IF
    IF fIsType = 1 THEN
      WHILE pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) <> 10
        pos = pos + 1
      WEND
    ELSE
      ntok = ntok + 1
      tt$(ntok) = "string"
      tv$(ntok) = MID$(src$, pos + 1, fi - pos - 1)
      pos = fi + 1
    END IF
  ELSEIF ch = 10 THEN
    ntok = ntok + 1
    tt$(ntok) = "newline"
    tv$(ntok) = ""
    pos = pos + 1
  ELSEIF ch = 36 THEN
    pos = pos + 1
    IF pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = 36 THEN
      pos = pos + 1
      tok$ = ""
      done = 0
      WHILE done = 0
        IF pos > LEN(src$) THEN
          done = 1
        ELSE
          ch = ASC(MID$(src$, pos, 1))
          IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR (ch >= 48 AND ch <= 57) OR ch = 95 THEN
            tok$ = tok$ + CHR$(ch)
            pos = pos + 1
          ELSE
            done = 1
          END IF
        END IF
      WEND
      ntok = ntok + 1
      tt$(ntok) = "sysconst"
      tv$(ntok) = tok$
    ELSE
      ntok = ntok + 1
      tt$(ntok) = "symbol"
      tv$(ntok) = "$"
    END IF
  ELSEIF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR ch = 95 THEN
    tok$ = ""
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR (ch >= 48 AND ch <= 57) OR ch = 36 OR ch = 37 OR ch = 95 THEN
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        ELSE
          done = 1
        END IF
      END IF
    WEND
    IF pos <= LEN(src$) AND ch = 33 THEN
      tok$ = tok$ + CHR$(ch)
      pos = pos + 1
    ELSEIF pos <= LEN(src$) AND ch = 35 THEN
      IF pos + 1 > LEN(src$) OR ASC(MID$(src$, pos + 1, 1)) <> 35 THEN
        tok$ = tok$ + CHR$(ch)
        pos = pos + 1
      END IF
    END IF
    IF pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = 64 THEN
      WHILE pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = 64
        tok$ = tok$ + CHR$(64)
        pos = pos + 1
      WEND
    END IF
    tk$ = "ident"
    IF tok$ = "PRINT" OR tok$ = "IF" OR tok$ = "THEN" OR tok$ = "ELSE" OR tok$ = "END" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "FUNCTION" OR tok$ = "DIM" OR tok$ = "FOR" OR tok$ = "TO" OR tok$ = "NEXT" OR tok$ = "STEP" OR tok$ = "DO" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "WHILE" OR tok$ = "WEND" OR tok$ = "RETURN" OR tok$ = "AND" OR tok$ = "OR" OR tok$ = "XOR" OR tok$ = "UNTIL" OR tok$ = "LOOP" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "NOT" OR tok$ = "MOD" OR tok$ = "EXIT" OR tok$ = "ELSEIF" OR tok$ = "VERSION" OR tok$ = "GOSUB" OR tok$ = "BREAK" OR tok$ = "CONST" OR tok$ = "LET" OR tok$ = "GOTO" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "SELECT" OR tok$ = "CASE" OR tok$ = "TYPE" OR tok$ = "PACKED" OR tok$ = "IMPORT" OR tok$ = "INC" OR tok$ = "DEC" OR tok$ = "SWAP" OR tok$ = "SUB" OR tok$ = "PROGRAM" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "IFZ" OR tok$ = "IFT" OR tok$ = "IFF" OR tok$ = "STATIC" OR tok$ = "REDIM" OR tok$ = "DOEVENTS" OR tok$ = "SHARED" OR tok$ = "EXPORT" OR tok$ = "RANDOMIZE" OR tok$ = "DATA" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "READ" OR tok$ = "STOP" OR tok$ = "RESTORE" OR tok$ = "FUNCADDR" OR tok$ = "DECLARE" OR tok$ = "INTERNAL" OR tok$ = "EXTERNAL" OR tok$ = "CFUNCTION" THEN
      tk$ = "keyword"
    END IF
    IF UCASE$(tok$) = "REM" THEN
      WHILE pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) <> 10
        pos = pos + 1
      WEND
      ntok = ntok + 1
      tt$(ntok) = "newline"
      tv$(ntok) = ""
    ELSE
      ntok = ntok + 1
      tt$(ntok) = tk$
      tv$(ntok) = tok$
    END IF
  ELSEIF (ch >= 48 AND ch <= 57) THEN
    tok$ = ""
    done = 0
    IF ch = 48 AND pos + 1 <= LEN(src$) THEN
      ch = ASC(MID$(src$, pos + 1, 1))
      IF ch = 120 OR ch = 88 THEN
        tok$ = "0x"
        pos = pos + 2
        WHILE done = 0
          IF pos > LEN(src$) THEN
            done = 1
          ELSE
            ch = ASC(MID$(src$, pos, 1))
            IF (ch >= 48 AND ch <= 57) OR (ch >= 65 AND ch <= 70) OR (ch >= 97 AND ch <= 102) THEN
              tok$ = tok$ + CHR$(ch)
              pos = pos + 1
            ELSE
              done = 1
            END IF
          END IF
        WEND
        ntok = ntok + 1
        tt$(ntok) = "number"
        tv$(ntok) = tok$
      ELSE
        done = 0
      END IF
    ELSE
      done = 0
    END IF
    IF done = 0 OR tok$ = "" THEN
      tok$ = ""
      done = 0
      WHILE done = 0
        IF pos > LEN(src$) THEN
          done = 1
        ELSE
          ch = ASC(MID$(src$, pos, 1))
          IF (ch >= 48 AND ch <= 57) OR ch = 46 THEN
            tok$ = tok$ + CHR$(ch)
            pos = pos + 1
          ELSE
            done = 1
          END IF
        END IF
      WEND
      IF pos <= LEN(src$) AND (ASC(MID$(src$, pos, 1)) = 101 OR ASC(MID$(src$, pos, 1)) = 69) THEN
        tok$ = tok$ + CHR$(ASC(MID$(src$, pos, 1)))
        pos = pos + 1
        IF pos <= LEN(src$) AND (ASC(MID$(src$, pos, 1)) = 43 OR ASC(MID$(src$, pos, 1)) = 45) THEN
          tok$ = tok$ + CHR$(ASC(MID$(src$, pos, 1)))
          pos = pos + 1
        END IF
        done = 0
        WHILE done = 0
          IF pos > LEN(src$) THEN
            done = 1
          ELSE
            ch = ASC(MID$(src$, pos, 1))
            IF ch >= 48 AND ch <= 57 THEN
              tok$ = tok$ + CHR$(ch)
              pos = pos + 1
            ELSE
              done = 1
            END IF
          END IF
        WEND
      END IF
      ntok = ntok + 1
      tt$(ntok) = "number"
      tv$(ntok) = tok$
    END IF
  ELSEIF ch = 34 THEN
    tok$ = ""
    pos = pos + 1
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF ch = 92 THEN
          ' Backslash escape: quote, backslash, n, t, r
          pos = pos + 1
          IF pos <= LEN(src$) THEN
            ch = ASC(MID$(src$, pos, 1))
            IF ch = 34 THEN
              tok$ = tok$ + CHR$(34)
            ELSEIF ch = 92 THEN
              tok$ = tok$ + CHR$(92)
            ELSEIF ch = 110 THEN
              tok$ = tok$ + CHR$(10)
            ELSEIF ch = 116 THEN
              tok$ = tok$ + CHR$(9)
            ELSEIF ch = 114 THEN
              tok$ = tok$ + CHR$(13)
            ELSE
              tok$ = tok$ + CHR$(92) + CHR$(ch)
            END IF
            pos = pos + 1
          END IF
        ELSEIF ch = 34 THEN
          pos = pos + 1
          done = 1
        ELSE
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        END IF
      END IF
    WEND
    ntok = ntok + 1
    tt$(ntok) = "string"
    tv$(ntok) = tok$
  ELSEIF ch = 35 THEN
    pos = pos + 1
    IF pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = 35 THEN
      pos = pos + 1
    END IF
    tok$ = ""
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR (ch >= 48 AND ch <= 57) OR ch = 36 OR ch = 95 THEN
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        ELSE
          done = 1
        END IF
      END IF
    WEND
    ntok = ntok + 1
    tt$(ntok) = "shared"
    tv$(ntok) = tok$
  ELSEIF ch = 60 OR ch = 62 THEN
    tok$ = CHR$(ch)
    pos = pos + 1
    IF pos <= LEN(src$) THEN
      ch = ASC(MID$(src$, pos, 1))
      IF ch = 61 OR ch = 62 THEN
        tok$ = tok$ + CHR$(ch)
        pos = pos + 1
      END IF
    END IF
    ntok = ntok + 1
    tt$(ntok) = "symbol"
    tv$(ntok) = tok$
  ELSEIF ch = 42 THEN
    IF pos + 1 <= LEN(src$) THEN
      IF ASC(MID$(src$, pos + 1, 1)) = 42 THEN
        ntok = ntok + 1
        tt$(ntok) = "power"
        tv$(ntok) = "**"
        pos = pos + 2
      ELSE
        ntok = ntok + 1
        tt$(ntok) = "symbol"
        tv$(ntok) = "*"
        pos = pos + 1
      END IF
    ELSE
      ntok = ntok + 1
      tt$(ntok) = "symbol"
      tv$(ntok) = "*"
      pos = pos + 1
    END IF
  ELSEIF ch = 61 THEN
    tok$ = "="
    pos = pos + 1
    IF pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = 61 THEN
      tok$ = "=="
      pos = pos + 1
    END IF
    ntok = ntok + 1
    tt$(ntok) = "symbol"
    tv$(ntok) = tok$
  ELSEIF ch = 33 THEN
    tok$ = "!"
    pos = pos + 1
    IF pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = 61 THEN
      tok$ = "!="
      pos = pos + 1
    END IF
    ntok = ntok + 1
    tt$(ntok) = "symbol"
    tv$(ntok) = tok$
  ELSEIF ch = 38 OR ch = 124 OR ch = 94 THEN
    tok$ = CHR$(ch)
    pos = pos + 1
    IF pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) = ch THEN
      tok$ = tok$ + CHR$(ch)
      pos = pos + 1
    END IF
    ntok = ntok + 1
    tt$(ntok) = "symbol"
    tv$(ntok) = tok$
  ELSE
    ntok = ntok + 1
    tt$(ntok) = "symbol"
    tv$(ntok) = CHR$(ch)
    pos = pos + 1
  END IF
WEND

tpos = 1
indent = 0
stmtState = 0
ifDepth = 0
ifSP = 0
arrSP = 0
singleLineIf = 0
midLen$ = ""

' P1 facet accumulation (docs/19 §9.1-9.2, §9.5 P1): dump-only pre-pass over
' the token tables, in source order. Recognition mirrors the emit-pass
' triggers (FUNCTION / END FUNCTION / DIM) plus the SHARED statement form.
' Storage is syntactic only; shared promotes per-scope in source order:
' DIM # / DIM SHARED / SHARED-statement names mark the current scope set
' (fresh per FUNCTION, top level separate), and later array DIMs of those
' names in the same scope promote (Rust: semantics_stmts.rs,
' semantics_function.rs, parser_select.rs shared_static_stmt, parser.rs
' DIM SHARED). Scalar SHARED names do not propagate. dyn/dual/descriptor/
' position/byref are later phases, so dual=0 is a placeholder and
' params/member DIMs emit nothing (no array-param or dotted-member-DIM
' syntax). Rank counts top-level comma groups in the DIM brackets.
' DECLARE/EXTERNAL FUNCTION forward decls do not set scope. Scope is the
' stripped function name as the IR prints it.

IF facetDump = 1 THEN
  curScope$ = "*"
  fTab$ = ""
  fSeen$ = ""
  fScopeArrs$ = ""
  fSharedTop$ = ""
  fSharedFn$ = ""
  fp = 1
  WHILE fp <= ntok AND NOT (tt$(fp) = "newline")
    fp = fp + 1
  WEND
  fp = fp + 1
  ' Composite TYPE names (for the typed-dim mirror: composite-typed
  ' declarations lower to member facets, not plain DIMs). Program-wide and
  ' order-free: collected before the main walk.
  fTypeNames$ = ""
  fsp = 1
  WHILE fsp <= ntok
    IF tt$(fsp) = "keyword" AND (tv$(fsp) = "TYPE" OR tv$(fsp) = "PACKED") AND fsp + 1 <= ntok AND tt$(fsp + 1) = "ident" THEN
      IF INSTR(fTypeNames$, ":" + tv$(fsp + 1) + ":") = 0 THEN
        fTypeNames$ = fTypeNames$ + ":" + tv$(fsp + 1) + ":"
      END IF
    END IF
    fsp = fsp + 1
  WEND
  WHILE fp <= ntok
    IF tt$(fp) = "keyword" AND tv$(fp) = "END" AND fp + 1 <= ntok AND tt$(fp + 1) = "keyword" AND tv$(fp + 1) = "FUNCTION" THEN
      curScope$ = "*"
      fp = fp + 2
    ELSEIF tt$(fp) = "keyword" AND (tv$(fp) = "FUNCTION" OR tv$(fp) = "CFUNCTION") THEN
      ' CFUNCTION (xit's signal handler) is a real function item in Rust and
      ' scopes like FUNCTION; it also closes with END FUNCTION.
      ' Prototypes (DECLARE/EXTERNAL FUNCTION) contribute no IR item in
      ' Rust, so they set no scope and emit no param facets: skip the whole
      ' line (the walk would otherwise read the prototype's param list as
      ' declarations - TOKEN tok[] misfires the typed-dim mirror). Matched
      ' by tv$ text of the previous token. INTERNAL is deliberately NOT
      ' here: Rust emits real function items for INTERNAL FUNCTION
      ' (verified: param + body-DIM facets), so it defines scope like a
      ' plain FUNCTION. A variable literally named DECLARE followed by a
      ' real FUNCTION line would misfire, but Rust lexes DECLARE as a
      ' keyword too, so no Rust-parseable program contains that shape.
      fIsDef = 0
      IF fp > 1 AND (tv$(fp - 1) = "DECLARE" OR tv$(fp - 1) = "EXTERNAL") THEN
        WHILE fp <= ntok AND NOT (tt$(fp) = "newline")
          fp = fp + 1
        WEND
        fp = fp + 1
      ELSEIF fp + 1 > ntok THEN
        fp = fp + 1
      ELSEIF tt$(fp + 1) = "ident" OR tt$(fp + 1) = "shared" THEN
        fIsDef = 1
      ELSE
        fp = fp + 1
      END IF
      IF fIsDef = 1 THEN
        ' Scope is the name as the compiler itself emits it (stripped: the
        ' IR function line prints bn$, and Rust scopes agree - c_type, not
        ' c_type$).
        fNameSk = fp + 1
        IF fNameSk + 2 <= ntok AND (tt$(fNameSk + 1) = "ident" OR tt$(fNameSk + 1) = "shared") AND tt$(fNameSk + 2) = "symbol" AND tv$(fNameSk + 2) = "(" THEN
          fNameSk = fNameSk + 1
        END IF
        ftmp$ = strip_suffix$(tv$(fNameSk))
        curScope$ = ftmp$
        ' A fresh function scope gets a fresh shared set (Rust per-function
        ' shared_arrays, semantics_function.rs).
        fSharedFn$ = ""
        fp = fNameSk + 1
        fpc = 0
        IF fp <= ntok AND tt$(fp) = "symbol" AND tv$(fp) = "(" THEN
          fdep = 1
          fp = fp + 1
          WHILE fp <= ntok AND fdep > 0
            IF tt$(fp) = "symbol" AND tv$(fp) = "(" THEN
              fdep = fdep + 1
            END IF
            IF tt$(fp) = "symbol" AND tv$(fp) = ")" THEN
              fdep = fdep - 1
            END IF
            IF fdep = 1 AND tt$(fp) = "symbol" AND tv$(fp) = "," THEN
              fpc = fpc + 1
            END IF
            ' Only depth 1: a parenthesized group inside the param list
            ' (e.g. XuiDropBox (..., (r1, r1$, r1[], r1$[]))) is not a param
            ' position Rust recognizes, so its contents classify nothing.
            IF fdep = 1 AND (tt$(fp) = "ident" OR tt$(fp) = "shared") THEN
              ' Array param (name[] - the brackets are visible even though
              ' the emit pass treats params as scalars): Rust emits only the
              ' param facet in this scope (DIMs of the name are dropped at
              ' lowering), so emit it here and let fSeen$ suppress the later
              ' DIM facet. rank=1 (params are unsized in practice) and no
              ' descriptor=1 (P4 owns descriptor facts); dual=0 is P2.
              IF fp + 1 <= ntok AND tt$(fp + 1) = "symbol" AND (tv$(fp + 1) = "[" OR tv$(fp + 1) = "(") THEN
                fnm$ = tv$(fp)
                GOSUB uCanonName
                ftmp$ = strip_suffix$(fnm$)
                ftp$ = ##suffixType$
                IF LEN(fnm$) >= 2 THEN
                  IF RIGHT$(fnm$, 2) = "$$" THEN
                    ftp$ = "giant"
                  END IF
                END IF
                fLn$ = "facet " + fnm$ + ":" + ftp$ + " scope=" + curScope$ + " storage=param rank=1 dual=0 position=" + STR$(fpc)
                fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
                IF fp > 1 AND tt$(fp - 1) = "ident" AND INSTR(fTypeNames$, ":" + tv$(fp - 1) + ":") > 0 THEN
                  ' Composite-typed array param (TOKEN tok[], DISPLAY d[]):
                  ' Rust lowers it to member facts and emits no plain facet,
                  ' exactly like a composite DIM. Track it so later DIMs of
                  ' the name stay suppressed too.
                  IF INSTR(fCompVars$, fKey$) = 0 THEN
                    fCompVars$ = fCompVars$ + fKey$
                  END IF
                END IF
                IF INSTR(fSeen$, fKey$) = 0 THEN
                  fSeen$ = fSeen$ + fKey$
                  IF INSTR(fCompVars$, fKey$) = 0 THEN
                    fTab$ = fTab$ + fLn$ + CHR$(10)
                  END IF
                ' P2 array knowledge (all types/storages, for paren-form
                ' access-vs-call disambiguation in the use-walk).
                IF INSTR(fScopeArrs$, ":" + curScope$ + ":" + fnm$ + ":") = 0 THEN
                  fScopeArrs$ = fScopeArrs$ + ":" + curScope$ + ":" + fnm$ + ":"
                END IF
                IF INSTR(fAPnames$, fKey$) = 0 THEN
                  fAPnames$ = fAPnames$ + fKey$
                END IF
                uEdge$ = ":" + curScope$ + ":" + STR$(fpc) + ":" + fnm$ + ":"
                IF INSTR(fAPpos$, uEdge$) = 0 THEN
                  fAPpos$ = fAPpos$ + uEdge$
                END IF
                END IF
              END IF
            END IF
            fp = fp + 1
          WEND
        END IF
      END IF
    ELSEIF tt$(fp) = "keyword" AND tv$(fp) = "TYPE" AND NOT (fp + 1 <= ntok AND tt$(fp + 1) = "symbol" AND tv$(fp + 1) = "(") THEN
      ' TYPE block (not the TYPE() call): member lines declare composite
      ' members, never plain facets - skip to END TYPE like Phase B.
      fInType = 1
      fp = fp + 1
    ELSEIF tt$(fp) = "keyword" AND tv$(fp) = "END" AND fp + 1 <= ntok AND tt$(fp + 1) = "keyword" AND tv$(fp + 1) = "TYPE" THEN
      fInType = 0
      fp = fp + 2
    ELSEIF fInType = 1 THEN
      fp = fp + 1
    ELSEIF tt$(fp) = "keyword" AND tv$(fp) = "SHARED" THEN
      ' SHARED statement: each name lowers to its own Dim{shared}
      ' (parser_select.rs shared_static_stmt), but only bracket-form names
      ' enter the scope shared set - scalar shared DIMs do not propagate
      ' (semantics_stmts.rs: only `shared && is_array` inserts). Per-element
      ' brackets: SHARED a[], b[] marks both; a TYPE qualifier (ident
      ' directly followed by another name, e.g. SHARED SQUAREINFORMATION
      ' squareInfo[]) is skipped. Bracketed size exprs are skipped so commas
      ' and idents inside them don't read as names. A variable literally
      ' named SHARED with no following name is untouched.
      fsp = fp + 1
      ' `SHARED /cb/ CALLBACKS callbacks[]` names a shared GROUP first; the
      ' group is not a declared name, so step over `/ ident /` before the
      ' qualifier walk. Without this the leading `/` aborts the whole arm and
      ' a composite like CALLBACKS never reaches fCompVars$, so a later
      ' `DIM callbacks[..]` wrongly emits a plain facet.
      IF fsp + 2 <= ntok AND tt$(fsp) = "symbol" AND tv$(fsp) = "/" AND (tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared") AND tt$(fsp + 2) = "symbol" AND tv$(fsp + 2) = "/" THEN
        fsp = fsp + 3
      END IF
      fCompSkip = 0
      fQuit = 0
      WHILE fsp <= ntok AND fQuit = 0 AND (tt$(fsp) = "ident" OR tt$(fsp) = "shared" OR (tt$(fsp) = "symbol" AND (tv$(fsp) = "," OR tv$(fsp) = "[" OR tv$(fsp) = "(")))
        IF tt$(fsp) = "ident" OR tt$(fsp) = "shared" THEN
          fIsType = 0
          IF fsp + 1 <= ntok AND tt$(fsp + 1) = "shared" THEN
            fIsType = 1
          ELSEIF fsp + 1 <= ntok AND tt$(fsp + 1) = "ident" THEN
            ' A next token Rust lexes as a keyword is not a name (shared_
            ' static_stmt restores it): STATIC SUBADDR sub[] names SUBADDR.
            fnm$ = tv$(fsp + 1)
            GOSUB uCanonName
            IF fIsKw = 0 THEN
              fIsType = 1
            END IF
          END IF
          fnm$ = tv$(fsp)
          GOSUB uCanonName
          IF fIsType = 1 THEN
            IF INSTR(fTypeNames$, ":" + fnm$ + ":") > 0 THEN
              fCompSkip = 1
            END IF
          END IF
          IF fIsType = 0 AND fCompSkip = 1 THEN
            fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
            IF INSTR(fCompVars$, fKey$) = 0 THEN
              fCompVars$ = fCompVars$ + fKey$
            END IF
          END IF
          IF fIsType = 0 THEN
            IF fsp + 1 <= ntok AND tt$(fsp + 1) = "symbol" AND (tv$(fsp + 1) = "[" OR tv$(fsp + 1) = "(") THEN
              IF curScope$ = "*" THEN
                IF INSTR(fSharedTop$, ":" + fnm$ + ":") = 0 THEN
                  fSharedTop$ = fSharedTop$ + ":" + fnm$ + ":"
                END IF
              ELSEIF INSTR(fSharedFn$, ":" + fnm$ + ":") = 0 THEN
                fSharedFn$ = fSharedFn$ + ":" + fnm$ + ":"
              END IF
              ' SHARED-statement arrays feed dim_info like any DIM, so they
              ' get facet lines (dual patched later like all lines). Rank
              ' counted; shared facets never affect the allStrArr predicate.
              ' Composite-qualified names (fCompSkip) get member facets in
              ' Rust, never plain ones: scan and track, but emit nothing.
              ftmp$ = strip_suffix$(fnm$)
              ftp$ = ##suffixType$
              IF LEN(fnm$) >= 2 THEN
                IF RIGHT$(fnm$, 2) = "$$" THEN
                  ftp$ = "giant"
                END IF
              END IF
              frk = 1
              fdep = 0
              fi = fsp + 1
              fEnd = 0
              WHILE fi <= ntok AND fEnd = 0
                IF tt$(fi) = "symbol" AND (tv$(fi) = "[" OR tv$(fi) = "(") THEN
                  fdep = fdep + 1
                ELSEIF tt$(fi) = "symbol" AND (tv$(fi) = "]" OR tv$(fi) = ")") THEN
                  fdep = fdep - 1
                  IF fdep = 0 THEN
                    fEnd = fi
                  END IF
                ELSEIF fdep = 1 AND tt$(fi) = "symbol" AND tv$(fi) = "," THEN
                  frk = frk + 1
                END IF
                fi = fi + 1
              WEND
              IF fEnd = fsp + 2 THEN
                fSized = 0
              ELSE
                fSized = 1
              END IF
              IF fCompSkip = 0 THEN
                fLn$ = "facet " + fnm$ + ":" + ftp$ + " scope=" + curScope$ + " storage=shared rank=" + STR$(frk) + " dual=0 shared"
                fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
                IF INSTR(fSeen$, fKey$) = 0 THEN
                  fSeen$ = fSeen$ + fKey$
                IF INSTR(fCompVars$, fKey$) = 0 AND INSTR(fCompVars$, ":" + curScope$ + ":" + strip_suffix$(fnm$) + ":") = 0 THEN
                  ' Rust keys its per-scope `seen` set on the suffix-stripped
                  ' name, so a composite `DISPLAY display[]` already claims
                  ' `display` and the sibling `display$[]` emits no facet.
                  fTab$ = fTab$ + fLn$ + CHR$(10)
                END IF
                END IF
                IF INSTR(fArrDim$, fKey$) = 0 THEN
                  fArrDim$ = fArrDim$ + fKey$
                END IF
                IF fEnd > 0 AND (fSized = 1 OR fRedimMode = 1) THEN
                  IF INSTR(fResized$, fKey$) = 0 THEN
                    fResized$ = fResized$ + fKey$
                  END IF
                END IF
              END IF
              fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
              IF INSTR(fSharedAll$, fKey$) = 0 THEN
                fSharedAll$ = fSharedAll$ + fKey$
              END IF
              IF INSTR(fScopeArrs$, ":" + curScope$ + ":" + fnm$ + ":") = 0 THEN
                fScopeArrs$ = fScopeArrs$ + ":" + curScope$ + ":" + fnm$ + ":"
              END IF
            ELSE
              ' scalar SHARED name: shared-tracked; Rust ends the statement
              ' unless a comma follows (STATIC SUBADDR sub[] names SUBADDR).
              fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
              IF INSTR(fSharedAll$, fKey$) = 0 THEN
                fSharedAll$ = fSharedAll$ + fKey$
              END IF
              IF INSTR(fSharedScalar$, fKey$) = 0 THEN
                fSharedScalar$ = fSharedScalar$ + fKey$
              END IF
              IF NOT (fsp + 1 <= ntok AND tt$(fsp + 1) = "symbol" AND tv$(fsp + 1) = ",") THEN
                fQuit = 1
                fsp = fsp + 1
              END IF
            END IF
            fCompSkip = 0
          END IF
          fsp = fsp + 1
        ELSEIF tt$(fsp) = "symbol" AND (tv$(fsp) = "[" OR tv$(fsp) = "(") THEN
          fdep = 1
          fsp = fsp + 1
          WHILE fsp <= ntok AND fdep > 0
            IF tt$(fsp) = "symbol" AND (tv$(fsp) = "[" OR tv$(fsp) = "(") THEN
              fdep = fdep + 1
            END IF
            IF tt$(fsp) = "symbol" AND (tv$(fsp) = "]" OR tv$(fsp) = ")") THEN
              fdep = fdep - 1
            END IF
            fsp = fsp + 1
          WEND
        ELSE
          fsp = fsp + 1
        END IF
      WEND
      fp = fsp
    ELSEIF (tt$(fp) = "keyword" AND tv$(fp) = "DIM") OR (tt$(fp) = "keyword" AND tv$(fp) = "REDIM") OR (tt$(fp) = "keyword" AND tv$(fp) = "STATIC") OR (tt$(fp) = "ident" AND tv$(fp) = "STRING") THEN
      ' DIM [SHARED] name[...] [, ...] / STATIC name[...] [, ...] - the
      ' classic shared-storage form plus #, comma-separated declarators each
      ' with optional brackets (xcol `DIM op[255], op$[255]`; `STATIC a[],
      ' b[]` lists). REDIM and STATIC take the same branch: they lower to
      ' Dim with shared:false (parser_select.rs), so neither forces shared
      ' from # (unlike DIM) nor takes a SHARED keyword (REDIM SHARED is a
      ' parse error in Rust); the scope set still applies, and a shared
      ' outcome feeds back like DIM. Storage promotes through the current
      ' scope set in source order (semantics_stmts.rs). fixed/dyn confusion
      ' is gate-invisible (both included by the predicate).
      fsp = fp + 1
      fst$ = "fixed"
      fRedimMode = 0
      IF tt$(fp) = "keyword" AND tv$(fp) = "REDIM" THEN
        fRedimMode = 1
      END IF
      IF tt$(fp) = "keyword" AND tv$(fp) = "STATIC" THEN
        fRedimMode = 2
      END IF
      ' STRING name[] declares explicit-string arrays (xst temp1$[]); the
      ' typename wins over the suffix, and TYPENAME # shares like DIM #
      ' (qbtoxb `STRING #string$[]`); other TYPENAME statements need no
      ' rule (their facets are non-string on both sides).
      IF tt$(fp) = "ident" AND tv$(fp) = "STRING" THEN
        fRedimMode = 3
      END IF
      fListShared = 0
      IF fRedimMode = 0 AND fsp <= ntok AND tt$(fsp) = "keyword" AND tv$(fsp) = "SHARED" AND fsp + 1 <= ntok AND (tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared") THEN
        fListShared = 1
        fsp = fsp + 1
      END IF
      fFirstQual = 1
      fCompSkip = 0
      fMore = 1
      WHILE fMore = 1 AND fsp <= ntok AND (tt$(fsp) = "ident" OR tt$(fsp) = "shared")
        fst$ = "fixed"
        frk = 0
        fEnd = 0
        IF fListShared = 1 THEN
          fst$ = "shared"
        END IF
        IF fRedimMode = 2 AND fFirstQual = 1 THEN
          IF tt$(fsp) = "ident" AND fsp + 1 <= ntok AND (tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared") THEN
            fnm$ = tv$(fsp + 1)
            GOSUB uCanonName
            IF fIsKw = 0 THEN
              IF INSTR(fTypeNames$, ":" + tv$(fsp) + ":") > 0 THEN
                fCompSkip = 1
              END IF
              fsp = fsp + 1
            END IF
          END IF
          fFirstQual = 0
        END IF
        fnm$ = tv$(fsp)
        GOSUB uCanonName
        IF fCompSkip = 1 THEN
          fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
          IF INSTR(fCompVars$, fKey$) = 0 THEN
            fCompVars$ = fCompVars$ + fKey$
          END IF
          fCompSkip = 0
        END IF
        ftmp$ = strip_suffix$(fnm$)
        ftp$ = ##suffixType$
        IF fRedimMode = 3 THEN
          ftp$ = "string"
        END IF
        ' A trailing $$ suffix is GIANT (Rust canonicalizes a$$ to a&&);
        ' strip_suffix$ only strips one $, so override the string it reports.
        ' Giant is predicate-excluded like every non-string, so only the
        ' typename-vs-suffix direction matters here.
        IF LEN(fnm$) >= 2 THEN
          IF RIGHT$(fnm$, 2) = "$$" THEN
            ftp$ = "giant"
          END IF
        END IF
        fInherit = 0
        IF tt$(fsp) = "shared" AND (fRedimMode = 0 OR fRedimMode = 3) THEN
          ' DIM # and TYPENAME # share; REDIM # and STATIC # do not force
          ' (parser hardcodes shared:false for both).
          fst$ = "shared"
        ELSEIF curScope$ = "*" THEN
          IF INSTR(fSharedTop$, ":" + fnm$ + ":") > 0 THEN
            fst$ = "shared"
            fInherit = 1
          END IF
        ELSEIF INSTR(fSharedFn$, ":" + fnm$ + ":") > 0 THEN
          ' Storage is inherited from a same-named SHARED array, but the
          ' declaration itself is still a LOCAL scalar: only an explicit
          ' `SHARED name` statement makes the scalar shared. Rust duals
          ' `DIM sicon`/`XLONG sicon` beside `SHARED sicon[]`, not `SHARED
          ' sicon`.
          fst$ = "shared"
          fInherit = 1
        END IF
        IF fsp + 1 <= ntok AND tt$(fsp + 1) = "symbol" AND (tv$(fsp + 1) = "[" OR tv$(fsp + 1) = "(") THEN
          frk = 1
          fdep = 0
          fi = fsp + 1
          fEnd = 0
          WHILE fi <= ntok AND fEnd = 0
            IF tt$(fi) = "symbol" AND (tv$(fi) = "[" OR tv$(fi) = "(") THEN
              fdep = fdep + 1
            ELSEIF tt$(fi) = "symbol" AND (tv$(fi) = "]" OR tv$(fi) = ")") THEN
              fdep = fdep - 1
              IF fdep = 0 THEN
                fEnd = fi
              END IF
            ELSEIF fdep = 1 AND tt$(fi) = "symbol" AND tv$(fi) = "," THEN
              frk = frk + 1
            END IF
            fi = fi + 1
          WEND
          IF fEnd = fsp + 2 THEN
            fSized = 0
          ELSE
            fSized = 1
          END IF
          IF fEnd > 0 THEN
            fsp = fEnd
          ELSE
            fsp = ntok + 1
          END IF
        END IF
          fLn$ = "facet " + fnm$ + ":" + ftp$ + " scope=" + curScope$ + " storage=" + fst$ + " rank=" + STR$(frk) + " dual=0"
          IF fst$ = "shared" THEN
            fLn$ = fLn$ + " shared"
          END IF
          fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
          IF frk > 0 AND INSTR(fSeen$, fKey$) = 0 THEN
            fSeen$ = fSeen$ + fKey$
          IF INSTR(fCompVars$, fKey$) = 0 AND NOT (fst$ = "shared" AND INSTR(fCompVars$, ":*:" + fnm$ + ":") > 0) THEN
              fTab$ = fTab$ + fLn$ + CHR$(10)
            END IF
          END IF
          ' P2 array knowledge: every array declarator, any type/storage.
          IF INSTR(fScopeArrs$, ":" + curScope$ + ":" + fnm$ + ":") = 0 THEN
            fScopeArrs$ = fScopeArrs$ + ":" + curScope$ + ":" + fnm$ + ":"
          END IF
          IF fEnd > 0 THEN
            IF INSTR(fArrDim$, fKey$) = 0 THEN
              fArrDim$ = fArrDim$ + fKey$
            END IF
            IF fSized = 1 OR fRedimMode = 1 THEN
              IF INSTR(fResized$, fKey$) = 0 THEN
                fResized$ = fResized$ + fKey$
              END IF
            END IF
          ELSEIF fst$ <> "shared" OR fRedimMode = 2 OR fInherit = 1 THEN
            ' STATIC scalars stay local even when a SHARED array of the
            ' same name exists (CheckState funcKind vs funcKind[]).
            GOSUB uStripSfx
            fKey$ = ":" + curScope$ + ":" + uBase$ + ":"
            IF INSTR(fScalar$, fKey$) = 0 THEN
              fScalar$ = fScalar$ + fKey$
            END IF
          ELSE
            IF INSTR(fSharedScalar$, fKey$) = 0 THEN
              fSharedScalar$ = fSharedScalar$ + fKey$
            END IF
          END IF
          IF fst$ = "shared" THEN
            IF INSTR(fSharedAll$, fKey$) = 0 THEN
              fSharedAll$ = fSharedAll$ + fKey$
            END IF
          END IF
          IF fst$ = "shared" THEN
            IF curScope$ = "*" THEN
              IF INSTR(fSharedTop$, ":" + fnm$ + ":") = 0 THEN
                fSharedTop$ = fSharedTop$ + ":" + fnm$ + ":"
              END IF
            ELSEIF INSTR(fSharedFn$, ":" + fnm$ + ":") = 0 THEN
              fSharedFn$ = fSharedFn$ + ":" + fnm$ + ":"
            END IF
          END IF
        fsp = fsp + 1
        IF fsp > ntok THEN
          fMore = 0
        ELSE
          IF tt$(fsp) = "symbol" THEN
            IF tv$(fsp) = "," THEN
              IF fsp + 1 <= ntok THEN
                IF tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared" THEN
                  fsp = fsp + 1
                ELSE
                  fMore = 0
                END IF
              ELSE
                fMore = 0
              END IF
            ELSE
              fMore = 0
            END IF
          ELSE
            fMore = 0
          END IF
        END IF
      WEND
      fp = fsp
    ELSEIF tt$(fp) = "ident" AND fp + 1 <= ntok AND (tt$(fp + 1) = "ident" OR tt$(fp + 1) = "shared") AND fp > 1 AND (tt$(fp - 1) = "newline" OR (tt$(fp - 1) = "symbol" AND tv$(fp - 1) = ":") OR (tt$(fp - 1) = "keyword" AND (tv$(fp - 1) = "THEN" OR tv$(fp - 1) = "ELSE"))) AND tv$(fp) <> "SELECT" AND tv$(fp) <> "CASE" AND tv$(fp) <> "INC" AND tv$(fp) <> "DEC" AND tv$(fp) <> "ATTACH" AND tv$(fp) <> "DECLARE" AND tv$(fp) <> "SUB" AND tv$(fp) <> "DATA" AND tv$(fp) <> "READ" AND tv$(fp) <> "CONST" AND tv$(fp) <> "LET" AND tv$(fp) <> "RESTORE" AND tv$(fp) <> "STOP" AND tv$(fp) <> "REM" THEN
      ' TYPENAME-led declaration mirror (typed_dim_stmt): leading identifiers
      ' are qualifiers, the last identifier before [/=,comma/EOL is the name.
      ' Statement-start gated (prev is newline, :, THEN, or ELSE): Rust only
      ' reaches typed_dim_stmt at statement position (statement keywords
      ' dispatch first), so a mid-statement pair like `address HEXX$(...)`
      ' inside PRINT is an expression, never a declaration. Each excluded
      ' verb above is routed elsewhere in Rust (its own statement rule or
      ' skip); REM lines never reach here (skipped at the chain head).
      ' Composite typenames (TYPE blocks, fTypeNames$) lower to member
      ' facets, never plain DIMs - that case falls through with fsp past the
      ' names (no declarator pass). Otherwise the declarator mirrors DIM
      ' (suffix types; no SHARED-keyword form).
      fsp = fp
      fIsType = 0
      WHILE fsp + 1 <= ntok AND (tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared")
        IF INSTR(fTypeNames$, ":" + tv$(fsp) + ":") > 0 THEN
          fIsType = 1
        END IF
        fsp = fsp + 1
      WEND
      IF fIsType = 1 THEN
        ' Composite-typed names lower to member facets in Rust: record them
        ' so later plain DIMs suppress their plain facet (arecord TYPE0).
        WHILE fsp <= ntok AND (tt$(fsp) = "ident" OR tt$(fsp) = "shared")
          IF fsp + 1 <= ntok AND (tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared") THEN
            fsp = fsp + 1
          ELSE
            fnm$ = tv$(fsp)
            GOSUB uCanonName
            fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
            IF INSTR(fCompVars$, fKey$) = 0 THEN
              fCompVars$ = fCompVars$ + fKey$
            END IF
            fsp = fsp + 1
            IF fsp <= ntok AND tt$(fsp) = "symbol" AND (tv$(fsp) = "[" OR tv$(fsp) = "(") THEN
              fdep = 1
              fsp = fsp + 1
              WHILE fsp <= ntok AND fdep > 0
                IF tt$(fsp) = "symbol" AND (tv$(fsp) = "[" OR tv$(fsp) = "(") THEN
                  fdep = fdep + 1
                END IF
                IF tt$(fsp) = "symbol" AND (tv$(fsp) = "]" OR tv$(fsp) = ")") THEN
                  fdep = fdep - 1
                END IF
                fsp = fsp + 1
              WEND
            END IF
            IF fsp <= ntok AND tt$(fsp) = "symbol" AND tv$(fsp) = "," THEN
              fsp = fsp + 1
            ELSE
              WHILE fsp <= ntok AND NOT (tt$(fsp) = "newline")
                fsp = fsp + 1
              WEND
            END IF
          END IF
        WEND
      END IF
      IF fIsType = 0 THEN
        fsp = fp + 1
        WHILE fsp + 1 <= ntok AND (tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared")
          fsp = fsp + 1
        WEND
        ' fsp now at the declarator name (or past end); run one declarator
        ' pass over name[, name...] exactly like DIM.
        fRedimMode = 0
        fListShared = 0
        fMore = 1
        WHILE fMore = 1 AND fsp <= ntok AND (tt$(fsp) = "ident" OR tt$(fsp) = "shared")
          fst$ = "fixed"
          frk = 0
          fEnd = 0
          IF fListShared = 1 THEN
            fst$ = "shared"
          END IF
          fnm$ = tv$(fsp)
          GOSUB uCanonName
          ftmp$ = strip_suffix$(fnm$)
          ftp$ = ##suffixType$
          fInherit = 0
          IF tt$(fsp) = "shared" THEN
            fst$ = "shared"
          ELSEIF curScope$ = "*" THEN
            IF INSTR(fSharedTop$, ":" + fnm$ + ":") > 0 THEN
              fst$ = "shared"
              fInherit = 1
            END IF
          ELSEIF INSTR(fSharedFn$, ":" + fnm$ + ":") > 0 THEN
            fst$ = "shared"
            fInherit = 1
          END IF
          IF fsp + 1 <= ntok AND tt$(fsp + 1) = "symbol" AND (tv$(fsp + 1) = "[" OR tv$(fsp + 1) = "(") THEN
            frk = 1
            fdep = 0
            fi = fsp + 1
            fEnd = 0
            WHILE fi <= ntok AND fEnd = 0
              IF tt$(fi) = "symbol" AND (tv$(fi) = "[" OR tv$(fi) = "(") THEN
                fdep = fdep + 1
              ELSEIF tt$(fi) = "symbol" AND (tv$(fi) = "]" OR tv$(fi) = ")") THEN
                fdep = fdep - 1
                IF fdep = 0 THEN
                  fEnd = fi
                END IF
              ELSEIF fdep = 1 AND tt$(fi) = "symbol" AND tv$(fi) = "," THEN
                frk = frk + 1
              END IF
              fi = fi + 1
            WEND
            IF fEnd = fsp + 2 THEN
              fSized = 0
            ELSE
              fSized = 1
            END IF
            IF fEnd > 0 THEN
              fsp = fEnd
            ELSE
              fsp = ntok + 1
          END IF
          END IF
            fLn$ = "facet " + fnm$ + ":" + ftp$ + " scope=" + curScope$ + " storage=" + fst$ + " rank=" + STR$(frk) + " dual=0"
            IF fst$ = "shared" THEN
              fLn$ = fLn$ + " shared"
            END IF
            fKey$ = ":" + curScope$ + ":" + fnm$ + ":"
            IF frk > 0 AND INSTR(fSeen$, fKey$) = 0 THEN
              fSeen$ = fSeen$ + fKey$
              IF INSTR(fCompVars$, fKey$) = 0 AND NOT (fst$ = "shared" AND INSTR(fCompVars$, ":*:" + fnm$ + ":") > 0) THEN
                fTab$ = fTab$ + fLn$ + CHR$(10)
              END IF
            END IF
            IF fEnd > 0 THEN
              IF INSTR(fArrDim$, fKey$) = 0 THEN
                fArrDim$ = fArrDim$ + fKey$
              END IF
              IF fSized = 1 OR fRedimMode = 1 THEN
                IF INSTR(fResized$, fKey$) = 0 THEN
                  fResized$ = fResized$ + fKey$
                END IF
              END IF
            ELSEIF fst$ <> "shared" OR fInherit = 1 THEN
              GOSUB uStripSfx
              fKey$ = ":" + curScope$ + ":" + uBase$ + ":"
              IF INSTR(fScalar$, fKey$) = 0 THEN
                fScalar$ = fScalar$ + fKey$
              END IF
            ELSE
              IF INSTR(fSharedScalar$, fKey$) = 0 THEN
                fSharedScalar$ = fSharedScalar$ + fKey$
              END IF
            END IF
            IF fst$ = "shared" THEN
              IF INSTR(fSharedAll$, fKey$) = 0 THEN
                fSharedAll$ = fSharedAll$ + fKey$
              END IF
            END IF
            IF fst$ = "shared" THEN
              IF curScope$ = "*" THEN
                IF INSTR(fSharedTop$, ":" + fnm$ + ":") = 0 THEN
                  fSharedTop$ = fSharedTop$ + ":" + fnm$ + ":"
                END IF
              ELSEIF INSTR(fSharedFn$, ":" + fnm$ + ":") = 0 THEN
                fSharedFn$ = fSharedFn$ + ":" + fnm$ + ":"
              END IF
            END IF
            IF INSTR(fScopeArrs$, ":" + curScope$ + ":" + fnm$ + ":") = 0 THEN
              fScopeArrs$ = fScopeArrs$ + ":" + curScope$ + ":" + fnm$ + ":"
            END IF
          fsp = fsp + 1
          IF fsp > ntok THEN
            fMore = 0
          ELSE
            IF tt$(fsp) = "symbol" THEN
              IF tv$(fsp) = "," THEN
                IF fsp + 1 <= ntok THEN
                  IF tt$(fsp + 1) = "ident" OR tt$(fsp + 1) = "shared" THEN
                    fsp = fsp + 1
                  ELSE
                    fMore = 0
                  END IF
                ELSE
                  fMore = 0
                END IF
              ELSE
                fMore = 0
              END IF
            ELSE
              fMore = 0
            END IF
          END IF
        WEND
        fp = fsp
      ELSE
        fp = fp + 1
      END IF
    ELSE
      fp = fp + 1
    END IF
  WEND
  ' Phase B use-walk (P2 dual): per-scope scalar/array use sets, then patch
  ' dual=0 to dual=1 on fTab$ lines whose (scope,name) sits in both sets.
  ' Rules mirror c_emit_hoist.rs with divert_byref=true: a bare ident is a
  ' scalar use unless it names a declaration (skipped lines carry Phase A
  ' facts already), a call callee (followed by (), a label (followed by :),
  ' a member (after .), a goto/gosub label, or an @-forwarded name; name[
  ' is always an array use. DIM sizes are walked (their idents are scalar
  ' reads); UBOUND(string) counts as a scalar use too. DATA, ATTACH,
  ' DECLARE/EXTERNAL, SUB headers, and TYPE blocks contribute no facts in
  ' Rust (catch-all arms) and are skipped here.
  fArrUse$ = ""
  fDual$ = ""
  ' VAR-SUFFIX-COLLISION pre-pass (mirrors semantics_suffix.rs
  ' scan_body_collisions): a base name referenced with BOTH a string and a
  ' non-string type collides on its base-keyed slot, and only then does a
  ' string scalar keep its `$`. The string side is implicit here (uStripSfx is
  ' only asked about a suffixed name), so record just the NON-string side.
  ' note_var fires on scalar refs, scalar DIMs, assignment/INC/DEC/SWAP/READ
  ' targets and FOR vars - never on an array base (name[ ) or a call (name( ),
  ' never on dotted members, and never on a bare shared #name (that lowers to
  ' SharedVariable, not Identifier).
  fNonStr$ = ""
  uPreScope$ = "*"
  un = 1
  WHILE un <= ntok AND NOT (tt$(un) = "newline")
    un = un + 1
  WEND
  un = un + 1
  WHILE un <= ntok
    IF tt$(un) = "keyword" AND tv$(un) = "END" AND un + 1 <= ntok AND tt$(un + 1) = "keyword" AND tv$(un + 1) = "FUNCTION" THEN
      uPreScope$ = "*"
      un = un + 2
    ELSEIF tt$(un) = "keyword" AND (tv$(un) = "DECLARE" OR tv$(un) = "EXTERNAL") THEN
      WHILE un <= ntok AND NOT (tt$(un) = "newline")
        un = un + 1
      WEND
      un = un + 1
    ELSEIF tt$(un) = "keyword" AND (tv$(un) = "FUNCTION" OR tv$(un) = "CFUNCTION") THEN
      fNameSk = un + 1
      IF fNameSk + 2 <= ntok AND (tt$(fNameSk + 1) = "ident" OR tt$(fNameSk + 1) = "shared") AND tt$(fNameSk + 2) = "symbol" AND tv$(fNameSk + 2) = "(" THEN
        fNameSk = fNameSk + 1
      END IF
      uPreScope$ = strip_suffix$(tv$(fNameSk))
      WHILE un <= ntok AND NOT (tt$(un) = "newline")
        un = un + 1
      WEND
      un = un + 1
    ELSE
      IF tt$(un) = "ident" THEN
        uPreOk = 1
        IF un + 1 <= ntok AND tt$(un + 1) = "symbol" AND (tv$(un + 1) = "[" OR tv$(un + 1) = "(" OR tv$(un + 1) = ".") THEN
          uPreOk = 0
        END IF
        IF un > 1 AND tt$(un - 1) = "symbol" AND tv$(un - 1) = "." THEN
          uPreOk = 0
        END IF
        IF uPreOk = 1 THEN
          fnm$ = tv$(un)
          GOSUB uCanonName
          IF fIsKw = 0 AND RIGHT$(fnm$, 1) <> "$" THEN
            uPreBase$ = strip_suffix$(fnm$)
            uEdge$ = ":" + uPreScope$ + ":" + uPreBase$ + ":"
            IF INSTR(fNonStr$, uEdge$) = 0 THEN
              fNonStr$ = fNonStr$ + uEdge$
            END IF
          END IF
        END IF
      END IF
      un = un + 1
    END IF
  WEND
  ucurScope$ = "*"
  uInType = 0
  up = 1
  WHILE up <= ntok AND NOT (tt$(up) = "newline")
    up = up + 1
  WEND
  up = up + 1
  WHILE up <= ntok
    IF tt$(up) = "newline" THEN
      up = up + 1
    ELSEIF tt$(up) = "keyword" AND (tv$(up) = "FUNCTION" OR tv$(up) = "CFUNCTION") THEN
      ' Scope-set mirrors Phase A (rettype skip); header params are not uses.
      fNameSk = up + 1
      IF fNameSk + 2 <= ntok AND (tt$(fNameSk + 1) = "ident" OR tt$(fNameSk + 1) = "shared") AND tt$(fNameSk + 2) = "symbol" AND tv$(fNameSk + 2) = "(" THEN
        fNameSk = fNameSk + 1
      END IF
      ftmp$ = strip_suffix$(tv$(fNameSk))
      ucurScope$ = ftmp$
      WHILE up <= ntok AND NOT (tt$(up) = "newline")
        up = up + 1
      WEND
      up = up + 1
    ELSEIF tt$(up) = "keyword" AND tv$(up) = "END" AND up + 1 <= ntok AND tt$(up + 1) = "keyword" AND tv$(up + 1) = "FUNCTION" THEN
      ucurScope$ = "*"
      up = up + 2
    ELSEIF tt$(up) = "keyword" AND (tv$(up) = "DECLARE" OR tv$(up) = "EXTERNAL") AND up + 1 <= ntok AND tt$(up + 1) = "keyword" AND (tv$(up + 1) = "FUNCTION" OR tv$(up + 1) = "CFUNCTION") THEN
      WHILE up <= ntok AND NOT (tt$(up) = "newline")
        up = up + 1
      WEND
      up = up + 1
    ELSEIF (tt$(up) = "keyword" AND (tv$(up) = "DIM" OR tv$(up) = "REDIM" OR tv$(up) = "STATIC" OR tv$(up) = "SHARED" OR tv$(up) = "DATA")) OR (tt$(up) = "ident" AND tv$(up) = "STRING") THEN
      udecl = 1
      GOSUB uScanEOL
      WHILE up <= ntok AND uprev$ = ","
        up = up + 1
        GOSUB uScanEOL
      WEND
    ELSEIF tt$(up) = "keyword" AND tv$(up) = "SUB" THEN
      WHILE up <= ntok AND NOT (tt$(up) = "newline")
        up = up + 1
      WEND
      up = up + 1
    ELSEIF tt$(up) = "keyword" AND tv$(up) = "TYPE" AND NOT (up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = "(") THEN
      up = up + 1
    ELSEIF tt$(up) = "keyword" AND tv$(up) = "END" AND up + 1 <= ntok AND tt$(up + 1) = "keyword" AND tv$(up + 1) = "TYPE" THEN
      uInType = 0
      up = up + 2
    ELSEIF uInType = 1 THEN
      WHILE up <= ntok AND NOT (tt$(up) = "newline")
        up = up + 1
      WEND
      up = up + 1
    ELSE
      udecl = 0
      GOSUB uScanEOL
      WHILE up <= ntok AND uprev$ = ","
        up = up + 1
        GOSUB uScanEOL
      WEND
    END IF
  WEND
  ' Descriptor fixpoint seeds (mirrors collect_descriptor_params): resized
  ' array params, and array params at XstQuickSort/XstCopyArray positions
  ' 0-1. Out: fDescParam$ (:S:N:).
  uWork$ = fAPnames$
  WHILE LEN(uWork$) > 0
    uWork$ = MID$(uWork$, 2)
    ue1 = INSTR(uWork$, ":")
    IF ue1 = 0 THEN
      uWork$ = ""
    ELSE
      ftmp$ = LEFT$(uWork$, ue1 - 1)
      fLn$ = MID$(uWork$, ue1 + 1)
      ue2 = INSTR(fLn$, ":")
      IF ue2 = 0 THEN
        uWork$ = ""
      ELSE
        fnm$ = LEFT$(fLn$, ue2 - 1)
        uWork$ = MID$(fLn$, ue2 + 1)
        fKey$ = ":" + ftmp$ + ":" + fnm$ + ":"
        IF INSTR(fResized$, fKey$) > 0 THEN
          IF INSTR(fDescParam$, fKey$) = 0 THEN
            fDescParam$ = fDescParam$ + fKey$
          END IF
        END IF
      END IF
    END IF
  WEND
  ' Seed: array params forwarded to XstQuickSort/XstCopyArray positions 0-1.
  uWork$ = fEdges$
  WHILE LEN(uWork$) > 0
    uWork$ = MID$(uWork$, 2)
    ue1 = INSTR(uWork$, ":")
    IF ue1 = 0 THEN
      uWork$ = ""
    ELSE
      uCaller$ = LEFT$(uWork$, ue1 - 1)
      uWork$ = MID$(uWork$, ue1 + 1)
      ue1 = INSTR(uWork$, ":")
      IF ue1 = 0 THEN
        uWork$ = ""
      ELSE
        uCal2$ = LEFT$(uWork$, ue1 - 1)
        uWork$ = MID$(uWork$, ue1 + 1)
        ue1 = INSTR(uWork$, ":")
        IF ue1 = 0 THEN
          uWork$ = ""
        ELSE
          uArgPos$ = LEFT$(uWork$, ue1 - 1)
          uWork$ = MID$(uWork$, ue1 + 1)
          ue1 = INSTR(uWork$, ":")
          IF ue1 = 0 THEN
            uWork$ = ""
          ELSE
            uSym$ = LEFT$(uWork$, ue1 - 1)
            uWork$ = MID$(uWork$, ue1 + 1)
            IF (uCal2$ = "XstQuickSort" OR uCal2$ = "XstCopyArray") AND (uArgPos$ = "0" OR uArgPos$ = "1") THEN
            IF INSTR(fAPnames$, ":" + uCaller$ + ":" + uSym$ + ":") > 0 THEN
              fKey$ = ":" + uCaller$ + ":" + uSym$ + ":"
              IF INSTR(fDescParam$, fKey$) = 0 THEN
                fDescParam$ = fDescParam$ + fKey$
              END IF
            END IF
            END IF
            END IF
          END IF
        END IF
      END IF
  WEND
  uChanged = 1
  uIter = 0
  WHILE uChanged = 1 AND uIter < 50
    uChanged = 0
    uIter = uIter + 1
    uWork$ = fEdges$
    WHILE LEN(uWork$) > 0
      uWork$ = MID$(uWork$, 2)
      ue1 = INSTR(uWork$, ":")
      IF ue1 = 0 THEN
        uWork$ = ""
      ELSE
        uCaller$ = LEFT$(uWork$, ue1 - 1)
        uWork$ = MID$(uWork$, ue1 + 1)
        ue1 = INSTR(uWork$, ":")
        IF ue1 = 0 THEN
          uWork$ = ""
        ELSE
          uCal2$ = LEFT$(uWork$, ue1 - 1)
          uWork$ = MID$(uWork$, ue1 + 1)
          ue1 = INSTR(uWork$, ":")
          IF ue1 = 0 THEN
            uWork$ = ""
          ELSE
            uArgPos$ = LEFT$(uWork$, ue1 - 1)
            uWork$ = MID$(uWork$, ue1 + 1)
            ue1 = INSTR(uWork$, ":")
            IF ue1 = 0 THEN
              uWork$ = ""
            ELSE
              uSym$ = LEFT$(uWork$, ue1 - 1)
              uWork$ = MID$(uWork$, ue1 + 1)
              uIsDesc = 0
              IF (uCal2$ = "XstQuickSort" OR uCal2$ = "XstCopyArray") AND (uArgPos$ = "0" OR uArgPos$ = "1") THEN
                uIsDesc = 1
              ELSE
                uPat$ = ":" + uCal2$ + ":" + uArgPos$ + ":"
                up0 = INSTR(fAPpos$, uPat$)
                IF up0 > 0 THEN
                  uRest$ = MID$(fAPpos$, up0 + LEN(uPat$))
                  ue1 = INSTR(uRest$, ":")
                  IF ue1 > 0 THEN
                    uPn$ = LEFT$(uRest$, ue1 - 1)
                    IF INSTR(fDescParam$, ":" + uCal2$ + ":" + uPn$ + ":") > 0 THEN
                      uIsDesc = 1
                    END IF
                  END IF
                END IF
              END IF
              IF uIsDesc = 1 THEN
                IF INSTR(fAPnames$, ":" + uCaller$ + ":" + uSym$ + ":") > 0 THEN
                  fKey$ = ":" + uCaller$ + ":" + uSym$ + ":"
                  IF INSTR(fDescParam$, fKey$) = 0 THEN
                    fDescParam$ = fDescParam$ + fKey$
                    uChanged = 1
                  END IF
                ELSE
                  fKey$ = ":" + uCaller$ + ":" + uSym$ + ":"
                  IF INSTR(fDynLocal$, fKey$) = 0 THEN
                    fDynLocal$ = fDynLocal$ + fKey$
                    uChanged = 1
                  END IF
                END IF
              END IF
            END IF
          END IF
        END IF
      END IF
    WEND
  WEND
  ' Dual compute: scalar use ∩ array use (array = fArrUse$ ∪ fArrDim$),
  ' keyed :scope:name:. Then patch matching fTab$ lines dual=0 -> dual=1.
  WHILE LEN(fScalar$) > 0
    fScalar$ = MID$(fScalar$, 2)
    ue1 = INSTR(fScalar$, ":")
    IF ue1 = 0 THEN
      fScalar$ = ""
    ELSE
      ftmp$ = LEFT$(fScalar$, ue1 - 1)
      fLn$ = MID$(fScalar$, ue1 + 1)
      ue2 = INSTR(fLn$, ":")
      IF ue2 = 0 THEN
        fScalar$ = ""
      ELSE
        fnm$ = LEFT$(fLn$, ue2 - 1)
        fScalar$ = MID$(fLn$, ue2 + 1)
        fKey$ = ":" + ftmp$ + ":" + fnm$ + ":"
        IF INSTR(fArrUse$, fKey$) > 0 OR INSTR(fArrDim$, fKey$) > 0 OR INSTR(fDescParam$, fKey$) > 0 OR INSTR(fDynLocal$, fKey$) > 0 THEN
          IF INSTR(fDual$, fKey$) = 0 THEN
            fDual$ = fDual$ + fKey$
          END IF
        END IF
      END IF
    END IF
  WEND
  WHILE LEN(fDual$) > 0
    fDual$ = MID$(fDual$, 2)
    ue1 = INSTR(fDual$, ":")
    IF ue1 = 0 THEN
      fDual$ = ""
    ELSE
      ftmp$ = LEFT$(fDual$, ue1 - 1)
      fLn$ = MID$(fDual$, ue1 + 1)
      ue2 = INSTR(fLn$, ":")
      IF ue2 = 0 THEN
        fDual$ = ""
      ELSE
        fnm$ = LEFT$(fLn$, ue2 - 1)
        fDual$ = MID$(fLn$, ue2 + 1)
        uAnchor$ = "facet " + fnm$ + ":"
        uSeg$ = fTab$
        ufound = 0
        WHILE LEN(uSeg$) > 0 AND ufound = 0
          up0 = INSTR(uSeg$, uAnchor$)
          IF up0 = 0 THEN
            uSeg$ = ""
          ELSE
            uTail$ = MID$(uSeg$, up0)
            ueol = INSTR(uTail$, CHR$(10))
            IF ueol = 0 THEN
              uLine$ = uTail$
            ELSE
              uLine$ = LEFT$(uTail$, ueol - 1)
            END IF
            IF INSTR(uLine$, " scope=" + ftmp$ + " storage=") > 0 THEN
              udp = INSTR(uLine$, " dual=0")
              IF udp > 0 THEN
                uNew$ = LEFT$(uLine$, udp - 1) + " dual=1" + MID$(uLine$, udp + 7)
                udp = INSTR(uNew$, " storage=fixed ")
                IF udp > 0 THEN
                  uNew$ = LEFT$(uNew$, udp - 1) + " storage=dyn " + MID$(uNew$, udp + 15)
                END IF
                up0 = INSTR(fTab$, uLine$)
                fTab$ = LEFT$(fTab$, up0 - 1) + uNew$ + MID$(fTab$, up0 + LEN(uLine$))
              END IF
              ufound = 1
            ELSE
              IF ueol = 0 THEN
                uSeg$ = ""
              ELSE
                uSeg$ = MID$(uTail$, ueol + 1)
              END IF
            END IF
          END IF
        WEND
      END IF
    END IF
  WEND
  ' Descriptor-forwarded locals (whole-array @x[] with no array DIM in
  ' scope): Rust emits a dyn rank=1 dual=1 byref=1 facet (dual by
  ' construction). byref=1 keeps them out of the allStrArr predicate.
  WHILE LEN(fDynLocal$) > 0
    fDynLocal$ = MID$(fDynLocal$, 2)
    ue1 = INSTR(fDynLocal$, ":")
    IF ue1 = 0 THEN
      fDynLocal$ = ""
    ELSE
      ftmp$ = LEFT$(fDynLocal$, ue1 - 1)
      fLn$ = MID$(fDynLocal$, ue1 + 1)
      ue2 = INSTR(fLn$, ":")
      IF ue2 = 0 THEN
        fDynLocal$ = ""
      ELSE
        fnm$ = LEFT$(fLn$, ue2 - 1)
        fDynLocal$ = MID$(fLn$, ue2 + 1)
        fKey$ = ":" + ftmp$ + ":" + fnm$ + ":"
        IF ftmp$ <> "*" AND INSTR(fCompVars$, fKey$) = 0 AND INSTR(fSeen$, fKey$) = 0 THEN
          fSeen$ = fSeen$ + fKey$
          IF RIGHT$(fnm$, 1) = "$" THEN
            ftp$ = "string"
          ELSE
            ftp$ = "integer"
          END IF
          fTab$ = fTab$ + "facet " + fnm$ + ":" + ftp$ + " scope=" + ftmp$ + " storage=dyn rank=1 dual=1 byref=1" + CHR$(10)
        END IF
      END IF
    END IF
  WEND
  PRINT fTab$
  tpos = ntok + 1
END IF
GOTO uAfterScan
  uScanEOL:
    urdep = 0
    ufresh = 1
    udep = 0
    uSzDep = 0
    uSwap = 0
    uprev$ = ""
    uDone = 0
    uArmCall = 0
    WHILE up <= ntok AND uDone = 0 AND NOT (tt$(up) = "newline")
      IF tt$(up) = "ident" OR tt$(up) = "shared" THEN
        fnm$ = tv$(up)
        GOSUB uCanonName
        fKey$ = ":" + ucurScope$ + ":" + fnm$ + ":"
        GOSUB uStripSfx
        uSKey$ = ":" + ucurScope$ + ":" + uBase$ + ":"
        IF udecl = 1 THEN
          IF urdep >= 1 THEN
            IF up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = "[" THEN
              IF INSTR(fArrUse$, fKey$) = 0 THEN
                fArrUse$ = fArrUse$ + fKey$
              END IF
            ELSEIF up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = "(" THEN
              ' nested call callee inside a size: not a use (UBOUND below still tracks).
            ELSEIF udep > 0 AND RIGHT$(fnm$, 1) = "$" AND INSTR(fSharedScalar$, fKey$) = 0 THEN
              IF INSTR(fScalar$, fKey$) = 0 THEN
                fScalar$ = fScalar$ + fKey$
              END IF
            ELSE
              IF INSTR(fSharedScalar$, uSKey$) = 0 AND INSTR(fScalar$, uSKey$) = 0 THEN
                fScalar$ = fScalar$ + uSKey$
              END IF
          END IF
        END IF
        ELSE
          IF ufresh = 1 AND up + 1 <= ntok AND (tt$(up + 1) = "ident" OR tt$(up + 1) = "shared") AND fnm$ <> "SELECT" AND fnm$ <> "CASE" AND fnm$ <> "INC" AND fnm$ <> "DEC" AND fnm$ <> "ATTACH" AND fnm$ <> "DECLARE" AND fnm$ <> "SUB" AND fnm$ <> "DATA" AND fnm$ <> "READ" AND fnm$ <> "CONST" AND fnm$ <> "LET" AND fnm$ <> "RESTORE" AND fnm$ <> "STOP" AND fnm$ <> "REM" THEN
            ' TYPENAME-led declaration mirror (Phase A trigger): the leader
            ' is a qualifier; the rest of the line declares.
            udecl = 1
          ELSEIF ufresh = 1 AND fnm$ = "ATTACH" THEN
            WHILE up <= ntok AND NOT (tt$(up) = "newline")
              up = up + 1
            WEND
            uDone = 1
          ELSEIF uprev$ = "." THEN
            ' member name: not a variable use.
          ELSEIF uprev$ = "GOTO" OR uprev$ = "GOSUB" THEN
            IF INSTR(fScopeArrs$, uSKey$) > 0 THEN
              IF INSTR(fScalar$, uSKey$) = 0 THEN
                fScalar$ = fScalar$ + uSKey$
              END IF
            END IF
          ELSEIF up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = "[" THEN
            IF up + 2 <= ntok AND tt$(up + 2) = "symbol" AND tv$(up + 2) = "]" THEN
              ' empty brackets lower to a scalar read (IFZ sub[]); @-whole
              ' arrays divert (descriptor forwarding records a byref fact,
              ' emitted below); UBOUND still takes the array ref.
              IF uprev$ = "@" THEN
                IF INSTR(fByrefFwd$, fKey$) = 0 THEN
                  fByrefFwd$ = fByrefFwd$ + fKey$
                END IF
                IF uCallDepth = 1 THEN
                  uEdge$ = ":" + ucurScope$ + ":" + uCal$ + ":" + STR$(uPos) + ":" + fnm$ + ":"
                  IF INSTR(fEdges$, uEdge$) = 0 THEN
                    fEdges$ = fEdges$ + uEdge$
                  END IF
                END IF
              ELSE
                IF udep > 0 THEN
                  IF INSTR(fArrUse$, fKey$) = 0 THEN
                    fArrUse$ = fArrUse$ + fKey$
                  END IF
                END IF
                IF uSzDep = 0 AND (udep = 0 OR RIGHT$(fnm$, 1) = "$") THEN
                  ' IFZ a[] / SWAP a[] / &a[] are scalar reads; LEN(a[]) and
                  ' SIZE(a[]) lower to SizeOf, which names no scalar.
                  IF INSTR(fScalar$, fKey$) = 0 THEN
                    fScalar$ = fScalar$ + fKey$
                  END IF
                END IF
              END IF
            ELSE
              IF INSTR(fArrUse$, fKey$) = 0 THEN
                fArrUse$ = fArrUse$ + fKey$
              END IF
              IF udep = 0 AND INSTR(fArrSub$, fKey$) = 0 THEN
                fArrSub$ = fArrSub$ + fKey$
              END IF
              ' indexed UBOUND never notes a scalar (only empty/bare do).
            END IF
          ELSEIF up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = "(" THEN
            IF fnm$ = "UBOUND" THEN
              udep = 1
            ELSEIF fnm$ = "LEN" OR fnm$ = "SIZE" THEN
              uSzDep = uSzDep + 1
            ELSEIF uCallDepth = 0 THEN
              uCallDepth = 1
              uCal$ = tv$(up)
              uPos = 0
              uArmCall = 1
            END IF
          ELSEIF up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = ":" THEN
            ' label definition: not a use.
          ELSE
            IF uprev$ = "@" AND uCallDepth = 1 THEN
                uEdge$ = ":" + ucurScope$ + ":" + uCal$ + ":" + STR$(uPos) + ":" + uBase$ + ":"
                IF INSTR(fEdges$, uEdge$) = 0 THEN
                  fEdges$ = fEdges$ + uEdge$
                END IF
            END IF
            IF uprev$ <> "@" THEN
              IF udep = 1 AND up + 1 <= ntok AND tt$(up + 1) = "symbol" AND (tv$(up + 1) = ")" OR tv$(up + 1) = ",") THEN
                IF INSTR(fSharedScalar$, fKey$) = 0 AND INSTR(fScalar$, fKey$) = 0 THEN
                  fScalar$ = fScalar$ + fKey$
                END IF
                IF INSTR(fArrUse$, fKey$) = 0 THEN
                  fArrUse$ = fArrUse$ + fKey$
                END IF
              ELSEIF uprev$ = "FOR" THEN
                IF INSTR(fScalar$, uSKey$) = 0 THEN
                  fScalar$ = fScalar$ + uSKey$
                END IF
              ELSEIF ufresh = 1 AND up + 1 <= ntok AND tt$(up + 1) = "symbol" AND tv$(up + 1) = "=" AND (INSTR(fSharedScalar$, uSKey$) > 0 OR INSTR(fSharedScalar$, fKey$) > 0) THEN
                ' scalar-shared assignment target (SharedAssignment in Rust):
              ELSEIF (udep = 0 OR RIGHT$(fnm$, 1) = "$") AND tt$(up) <> "shared" THEN
                ' Bare #name is SharedVariable (not a local scalar). Empty
                ' #name[] still notes above (IFZ #asm$[] / SWAP #qbasic$[]).
                ' SWAP keeps the suffixed spelling in Rust (`swap t$ tt$`,
                ' and `SWAP t$, tt$[n]` assigns to `t$`), unlike a plain
                ' assignment which strips it - so note the full key there.
                IF uSwap = 1 THEN
                  uSKey$ = fKey$
                END IF
                IF INSTR(fSharedScalar$, uSKey$) = 0 AND INSTR(fScalar$, uSKey$) = 0 THEN
                  fScalar$ = fScalar$ + uSKey$
                END IF
              END IF
            END IF
          END IF
        END IF
      END IF
        uprev$ = tv$(up)
        IF tt$(up) = "keyword" AND (tv$(up) = "DIM" OR tv$(up) = "REDIM" OR tv$(up) = "STATIC" OR tv$(up) = "SHARED" OR tv$(up) = "DATA" OR tv$(up) = "SUB") THEN
          udecl = 1
        ELSEIF tt$(up) = "keyword" AND tv$(up) = "SWAP" THEN
          uSwap = 1
        ELSEIF tt$(up) = "symbol" AND tv$(up) = "(" THEN
          IF uArmCall = 1 THEN
            uArmCall = 0
          ELSEIF uCallDepth > 0 THEN
            uCallDepth = uCallDepth + 1
          END IF
          IF udep > 0 THEN
            udep = udep + 1
          END IF
          IF udecl = 1 THEN
            urdep = urdep + 1
          END IF
        ELSEIF tt$(up) = "symbol" AND tv$(up) = ")" THEN
          IF uSzDep > 0 THEN
            uSzDep = uSzDep - 1
          END IF
          IF udep > 0 THEN
            udep = udep - 1
          END IF
          IF uCallDepth > 0 THEN
            uCallDepth = uCallDepth - 1
          END IF
          IF udecl = 1 AND urdep > 0 THEN
            urdep = urdep - 1
          END IF
        ELSEIF tt$(up) = "symbol" AND tv$(up) = "," AND uCallDepth = 1 THEN
          uPos = uPos + 1
        ELSEIF tt$(up) = "symbol" AND tv$(up) = "[" AND udecl = 1 THEN
          urdep = urdep + 1
        ELSEIF tt$(up) = "symbol" AND tv$(up) = "]" AND udecl = 1 AND urdep > 0 THEN
          urdep = urdep - 1
        ELSEIF tt$(up) = "symbol" AND tv$(up) = ":" AND udep = 0 AND urdep = 0 AND uCallDepth = 0 THEN
          ' A colon at depth 0 ends the statement (DIM temp[3] : SWAP a[], temp[]).
          ' Rust parses those as separate items, so the declaration context must
          ' not leak into the next one - otherwise the SWAP arm notes nothing.
          udecl = 0
          uSwap = 0
          ufresh = 1
        ELSE
          ufresh = 0
        END IF
        up = up + 1
    WEND
    RETURN
  uCanonName:
    ' Canonicalize a program identifier to Rust's facet-name spelling:
    ' words the Rust lexer takes as keywords (case-insensitively) become
    ' the Keyword Debug spelling (sub -> Sub); everything else keeps
    ' source case. Suffixed names (sub$) never match and pass through.
    ' In: fnm$. Out: fnm$ (canonical), fIsKw (1 if keyword), uTmp$ (upper).
    IF uKwMap$ = "" THEN
      uKwMap$ = ":FUNCTION:Function:END:End:DECLARE:Declare:INTERNAL:Internal:EXTERNAL:External:CFUNCTION:CFunction:IF:If:THEN:Then:ELSE:Else:ELSEIF:ElseIf:SELECT:Select:CASE:Case:FOR:For:TO:To:NEXT:Next:STEP:Step:DO:Do:LOOP:Loop:WHILE:While:UNTIL:Until:WEND:Wend:RETURN:Return:DIM:Dim:TYPE:Type:PACKED:Packed:PRINT:Print:IMPORT:Import:AND:And:OR:Or:NOT:Not:MOD:Mod:EXIT:Exit:VERSION:Version:INC:Inc:DEC:Dec:SWAP:Swap:PROGRAM:Program:SUB:Sub:IFZ:Ifz:IFT:Ift:IFF:Iff:STATIC:Static:REDIM:Redim:DOEVENTS:DoEvents:GOSUB:Gosub:BREAK:Break:SHARED:Shared:XOR:Xor:LET:Let:GOTO:Goto:CONST:Const:EXPORT:Export:RANDOMIZE:Randomize:DATA:Data:READ:Read:STOP:Stop:RESTORE:Restore:FUNCADDR:FuncAddr:"
    END IF
    uTmp$ = ""
    ui = 1
    WHILE ui <= LEN(fnm$)
      uch = ASC(MID$(fnm$, ui, 1))
      IF uch >= 97 AND uch <= 122 THEN
        uch = uch - 32
      END IF
      uTmp$ = uTmp$ + CHR$(uch)
      ui = ui + 1
    WEND
    fIsKw = 0
    up0 = INSTR(uKwMap$, ":" + uTmp$ + ":")
    IF up0 > 0 THEN
      fIsKw = 1
      uRest$ = MID$(uKwMap$, up0 + LEN(uTmp$) + 2)
      ue1 = INSTR(uRest$, ":")
      IF ue1 > 0 THEN
        fnm$ = LEFT$(uRest$, ue1 - 1)
      END IF
    END IF
    RETURN
  uStripSfx:
    ' Split a suffixed name to its scalar base (Rust Symbol lowering keeps
    ' the type but drops the suffix: text$ reads/writes as text:string).
    ' Array/DIM/UBOUND positions keep the full spelling; only scalar-use
    ' keys strip. In: fnm$. Out: uBase$.
    '
    ' Suffix retention follows semantics_suffix.rs::slot_name exactly: a
    ' STRING scalar keeps its `$` iff the base name also has a non-string
    ' reference in the same body (fNonStr$, built in the pre-pass above);
    ' every non-string suffix (#, %, !, &&) always takes the bare base.
    ' Phase A callers leave ucurScope$ unset on purpose, so a *declaration*
    ' always strips - that keeps `DIM text[3]` + `DIM text$` unified on
    ' `text` the way Rust does (array DIMs never note a collision).
    uBase$ = fnm$
    IF LEN(uBase$) >= 2 THEN
      IF RIGHT$(uBase$, 2) = "&&" THEN
        uBase$ = LEFT$(uBase$, LEN(uBase$) - 2)
      ELSEIF RIGHT$(uBase$, 1) = "$" OR RIGHT$(uBase$, 1) = "#" OR RIGHT$(uBase$, 1) = "%" OR RIGHT$(uBase$, 1) = "!" THEN
        uBase$ = LEFT$(uBase$, LEN(uBase$) - 1)
      END IF
    END IF
    IF uBase$ <> fnm$ AND RIGHT$(fnm$, 1) = "$" THEN
      ' Only a STRING scalar can keep its suffix (slot_name: non-string always
      ' takes the bare base), and only when the base also has a non-string
      ' reference in the same body. Two note sources, both required:
      '   - an unsuffixed ARRAY declaration of the base (verified: DIM v[],
      '     DIM v[3], DIM v[n], SHARED v[], STATIC v[] all make v$ keep it)
      '   - a non-string scalar reference anywhere in the body (fNonStr$),
      '     e.g. the index in dir$[dir], or STATIC window beside window$
      ' `SHARED gridName$[]` plus scalar gridName$ has neither, so it strips.
      IF INSTR(fArrDim$, ":" + ucurScope$ + ":" + uBase$ + ":") > 0 THEN
        uBase$ = fnm$
      ELSEIF INSTR(fNonStr$, ":" + ucurScope$ + ":" + uBase$ + ":") > 0 THEN
        uBase$ = fnm$
      END IF
    END IF
    RETURN
uAfterScan:
WHILE tpos <= ntok
  IF stmtState = 0 THEN
    IF singleLineIf = 2 THEN
      ' Check if next token is ELSE — if so, this is a single-line
      ' IF...THEN...ELSE; emit "else" and set singleLineIf = 1 so the
      ' ELSE branch statement gets the same treatment as the THEN branch
      ' (singleLineIf 1→2→end-if after the statement is emitted).
      IF tpos <= ntok AND tt$(tpos) = "keyword" AND tv$(tpos) = "ELSE" THEN
        singleLineIf = 1
        indent = indent - 1
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        PRINT prefix$ + "else"
        indent = indent + 1
        tpos = tpos + 1
      ELSE
        singleLineIf = 0
        indent = indent - 1
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        PRINT prefix$ + "end if"
        ifDepth = ifStack(ifSP)
        ifSP = ifSP - 1
      END IF
    END IF
    IF singleLineIf = 1 THEN
      singleLineIf = 2
    END IF
    t$ = tt$(tpos)
    v$ = tv$(tpos)
    IF t$ = "newline" THEN
      tpos = tpos + 1
    ELSEIF t$ = "keyword" AND v$ = "VERSION" THEN
      tpos = tpos + 1
      v$ = tv$(tpos)
      tpos = tpos + 1
      PRINT "version " + v$
    ELSEIF t$ = "keyword" AND v$ = "FUNCTION" THEN
      tpos = tpos + 1
      v$ = tv$(tpos)
      tpos = tpos + 1
      indent = 1
      params$ = ""
      IF tpos <= ntok AND tt$(tpos) = "symbol" AND tv$(tpos) = "(" THEN
        tpos = tpos + 1
        WHILE tpos <= ntok AND NOT (tt$(tpos) = "symbol" AND tv$(tpos) = ")")
          IF tt$(tpos) = "symbol" AND tv$(tpos) = "," THEN
            params$ = params$ + ", "
          ELSEIF tt$(tpos) = "ident" THEN
            pname$ = tv$(tpos)
            vt$ = "integer"
            pname$ = strip_suffix$(pname$)
            vt$ = ##suffixType$
            params$ = params$ + pname$ + ":" + vt$
          END IF
          tpos = tpos + 1
        WEND
        tpos = tpos + 1
      END IF
      vt$ = "integer"
      bn$ = strip_suffix$(v$)
      vt$ = ##suffixType$
      PRINT "function " + bn$ + "(" + params$ + ") -> " + vt$
    ELSEIF t$ = "keyword" AND v$ = "DIM" THEN
      tpos = tpos + 1
      v$ = tv$(tpos)
      tpos = tpos + 1
      vt$ = "integer"
      bn$ = strip_suffix$(v$)
      vt$ = ##suffixType$
      IF tpos <= ntok AND tt$(tpos) = "symbol" AND (tv$(tpos) = "(" OR tv$(tpos) = "[") THEN
        tpos = tpos + 1
        arrSP = arrSP + 1
        arrNames$(arrSP) = v$
        dimName$ = v$
        dimType$ = vt$
        stmtState = 7
        exprStop$ = ")"
      ELSE
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        PRINT prefix$ + "dim " + bn$ + ":" + vt$
      END IF
    ELSEIF t$ = "keyword" AND v$ = "PRINT" THEN
      tpos = tpos + 1
      stmtState = 1
      exprStop$ = "newline"
    ELSEIF t$ = "keyword" AND v$ = "IF" THEN
      tpos = tpos + 1
      ifSP = ifSP + 1
      ifStack(ifSP) = ifDepth
      ifDepth = 1
      stmtState = 3
      exprStop$ = "THEN"
    ELSEIF t$ = "keyword" AND v$ = "ELSEIF" THEN
      indent = indent - 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "else"
      indent = indent + 1
      tpos = tpos + 1
      ifDepth = ifDepth + 1
      stmtState = 3
      exprStop$ = "THEN"
    ELSEIF t$ = "keyword" AND v$ = "ELSE" THEN
      indent = indent - 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "else"
      indent = indent + 1
      tpos = tpos + 1
    ELSEIF t$ = "keyword" AND v$ = "END" THEN
      tpos = tpos + 1
      v$ = tv$(tpos)
      tpos = tpos + 1
      IF v$ = "IF" THEN
        ' GUARD-UNDERFLOW: a stray END IF with no open IF (ifSP = 0) must not
        ' pop ifStack OOB (ASLR garbage into ifDepth = nondeterministic end-if
        ' floods). Skip it, matching the Rust parser's unconditional orphan-END IF
        ' drop (parser.rs starts_end_if arm). Only this block-END IF path is
        ' guarded; the single-line-IF pop at the loop head is not (docs/16 P6).
        IF ifSP >= 1 THEN
          k = ifDepth
          WHILE k >= 1
            indent = indent - 1
            prefix$ = ""
            i = 1
            WHILE i <= indent
              prefix$ = prefix$ + "  "
              i = i + 1
            WEND
            PRINT prefix$ + "end if"
            k = k - 1
          WEND
          ifDepth = ifStack(ifSP)
          ifSP = ifSP - 1
        END IF
      ELSEIF v$ = "FUNCTION" THEN
        indent = 0
        PRINT "end function"
      END IF
    ELSEIF t$ = "keyword" AND v$ = "WHILE" THEN
      tpos = tpos + 1
      stmtState = 4
      exprStop$ = "newline"
    ELSEIF t$ = "keyword" AND v$ = "WEND" THEN
      indent = indent - 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "wend"
      tpos = tpos + 1
    ELSEIF t$ = "keyword" AND v$ = "DO" THEN
      tpos = tpos + 1
      IF tpos <= ntok AND tt$(tpos) = "keyword" AND (tv$(tpos) = "WHILE" OR tv$(tpos) = "UNTIL") THEN
        doMode$ = tv$(tpos)
        tpos = tpos + 1
        stmtState = 15
        exprStop$ = "newline"
      ELSE
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        PRINT prefix$ + "do"
        indent = indent + 1
      END IF
    ELSEIF t$ = "keyword" AND v$ = "LOOP" THEN
      indent = indent - 1
      tpos = tpos + 1
      IF tpos <= ntok AND tt$(tpos) = "keyword" AND (tv$(tpos) = "WHILE" OR tv$(tpos) = "UNTIL") THEN
        doMode$ = tv$(tpos)
        tpos = tpos + 1
        stmtState = 16
        exprStop$ = "newline"
      ELSE
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        PRINT prefix$ + "loop"
      END IF
    ELSEIF t$ = "keyword" AND v$ = "FOR" THEN
      tpos = tpos + 1
      forVar$ = tv$(tpos)
      tpos = tpos + 2
      stmtState = 5
      exprStop$ = "TO"
    ELSEIF t$ = "keyword" AND v$ = "NEXT" THEN
      indent = indent - 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "next"
      tpos = tpos + 2
    ELSEIF t$ = "keyword" AND v$ = "EXIT" THEN
      tpos = tpos + 2
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "exit_loop"
    ELSEIF t$ = "keyword" AND v$ = "RETURN" THEN
      tpos = tpos + 1
      IF tpos <= ntok AND tt$(tpos) = "newline" THEN
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        ' A bare RETURN lowers to GosubReturn (semantics.rs); only
        ' RETURN <expr> is a function return.
        PRINT prefix$ + "gosub_return"
      ELSE
        stmtState = 10
        exprStop$ = "newline"
      END IF
    ELSEIF t$ = "keyword" AND v$ = "GOSUB" THEN
      ' Plain `GOSUB label`; the computed form (GOSUB @tab[i]) lowers to a
      ' gosub_expr item and is not used by the selfhost sources.
      tpos = tpos + 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "gosub " + tv$(tpos)
      tpos = tpos + 1
    ELSEIF t$ = "keyword" AND v$ = "BREAK" THEN
      tpos = tpos + 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
    ELSEIF t$ = "keyword" AND v$ = "CONST" THEN
      tpos = tpos + 1
      cname$ = tv$(tpos)
      tpos = tpos + 1
      tpos = tpos + 1
      cval$ = tv$(tpos)
      tpos = tpos + 1
      PRINT "const $$" + cname$ + ":integer = integer(" + cval$ + ")"
    ELSEIF t$ = "keyword" AND v$ = "LET" THEN
      tpos = tpos + 1
    ELSEIF t$ = "keyword" AND v$ = "GOTO" THEN
      tpos = tpos + 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "goto " + tv$(tpos)
      tpos = tpos + 1
    ELSEIF t$ = "sysconst" THEN
      assignTarget$ = v$
      assignType$ = "integer"
      tpos = tpos + 2
      stmtState = 13
      exprStop$ = "newline"
    ELSEIF t$ = "ident" AND tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND tv$(tpos + 1) = ":" THEN
      ' Label definition: Rust emits a `label NAME` item at body level.
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "label " + v$
      tpos = tpos + 2
    ELSEIF t$ = "ident" AND v$ = "MID$" AND tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND tv$(tpos + 1) = "(" THEN
      ' MID$ assignment: MID$(target, start[, len]) = value
      tpos = tpos + 2
      stmtState = 18
      exprStop$ = "COMMA_OR_RPAREN"
    ELSEIF t$ = "keyword" AND (v$ = "DECLARE" OR v$ = "INTERNAL" OR v$ = "EXTERNAL") AND tpos + 1 <= ntok AND tt$(tpos + 1) = "keyword" AND tv$(tpos + 1) = "FUNCTION" THEN
      ' Prototype line (Rust parser: forward declaration, no IR item). It
      ' used to fall into the assignment arm and parse `Foo (TOKEN token)`
      ' as an expression, where an ident after an ident never advances tpos
      ' and the unclosed `(` spun the op-stack drain forever (xcol.x, every
      ' INTERNAL FUNCTION ... (TYPE name) prototype). Skip to end of line.
      WHILE tpos <= ntok AND NOT (tt$(tpos) = "newline")
        tpos = tpos + 1
      WEND
    ELSEIF t$ = "ident" THEN
      isArr = 0
      j = 1
      WHILE j <= arrSP
        IF arrNames$(j) = v$ THEN
          isArr = 1
          j = arrSP + 1
        END IF
        j = j + 1
      WEND
      IF isArr = 1 AND tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND (tv$(tpos + 1) = "(" OR tv$(tpos + 1) = "[") THEN
        arrName$ = v$
        tpos = tpos + 2
        stmtState = 8
        exprStop$ = ")"
      ELSE
        IF tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND tv$(tpos + 1) = "(" THEN
          stmtState = 11
          exprStop$ = "newline"
        ELSE
          assignTarget$ = v$
          vt$ = "integer"
          bn$ = strip_suffix$(v$)
          vt$ = ##suffixType$
          assignType$ = vt$
          assignTarget$ = bn$
          tpos = tpos + 2
          stmtState = 2
          exprStop$ = "newline"
        END IF
      END IF
    ELSEIF t$ = "shared" THEN
      assignTarget$ = v$
      vt$ = "integer"
      bn$ = strip_suffix$(v$)
      vt$ = ##suffixType$
      assignType$ = vt$
      assignTarget$ = bn$
      tpos = tpos + 2
      stmtState = 12
      exprStop$ = "newline"
    ELSE
      tpos = tpos + 1
    END IF
  ELSE
    spOp = 0
    spVal = 0
    expectOp = 0
    edone = 0
    popPrec = 99
    parenDepth = 0
    pendingOp$ = ""
    funcSP = 0
    WHILE edone = 0 OR spOp > 0
      IF edone = 1 AND popPrec >= 99 AND spOp > 0 THEN
        ' Expression ended with an unclosed `(` / call / index frame on the
        ' stack (malformed or unsupported input). Nothing below can pop it,
        ' so the drain would spin forever, allocating each turn. Discard the
        ' frame; the popped expression is emitted as-is. Balanced input
        ' never reaches this branch, so normal IR is unchanged.
        IF opStack$(spOp) = "(" OR LEFT$(opStack$(spOp), 5) = "FUNC:" OR LEFT$(opStack$(spOp), 4) = "ARR:" THEN
          IF LEFT$(opStack$(spOp), 5) = "FUNC:" AND funcSP > 0 THEN
            funcSP = funcSP - 1
          END IF
          spOp = spOp - 1
        END IF
        popPrec = 0
      END IF
      IF popPrec < 99 THEN
        stopPop = 0
        IF spOp = 0 THEN
          stopPop = 1
        ELSEIF opStack$(spOp) = "(" THEN
          stopPop = 1
        ELSEIF LEFT$(opStack$(spOp), 5) = "FUNC:" THEN
          stopPop = 1
        ELSEIF LEFT$(opStack$(spOp), 4) = "ARR:" THEN
          stopPop = 1
        ELSEIF popPrec > 0 AND opPrec(spOp) < popPrec THEN
          stopPop = 1
        END IF
        IF stopPop = 1 THEN
          popPrec = 99
          IF edone = 0 THEN
            IF pendingOp$ = ")" THEN
              IF spOp > 0 AND opStack$(spOp) = "(" THEN
                spOp = spOp - 1
                parenDepth = parenDepth - 1
                IF spOp > 0 AND LEFT$(opStack$(spOp), 5) = "FUNC:" THEN
                  spOp = spOp - 1
                  fname$ = funcName$(funcSP)
                  fnargs = spVal - funcStart(funcSP) + 1
                  funcSP = funcSP - 1
                  nargs = fnargs
                  WHILE nargs > 0
                    fargs$(nargs) = valStack$(spVal)
                    spVal = spVal - 1
                    nargs = nargs - 1
                  WEND
                  bn$ = fname$
                  IF RIGHT$(bn$, 1) = "$" THEN
                    IF bn$ <> "CHR$" AND bn$ <> "LEFT$" AND bn$ <> "RIGHT$" AND bn$ <> "MID$" AND bn$ <> "STR$" AND bn$ <> "READLINE$" AND bn$ <> "UCASE$" AND bn$ <> "LCASE$" AND bn$ <> "TRIM$" AND bn$ <> "LTRIM$" AND bn$ <> "RTRIM$" AND bn$ <> "SPACE$" AND bn$ <> "HEX$" AND bn$ <> "BIN$" AND bn$ <> "OCT$" AND bn$ <> "HEXX$" AND bn$ <> "RJUST$" AND bn$ <> "LJUST$" AND bn$ <> "CJUST$" AND bn$ <> "RCLIP$" AND bn$ <> "LCLIP$" AND bn$ <> "STUFF$" AND bn$ <> "VERSION$" AND bn$ <> "SIGNED$" AND bn$ <> "NULL$" AND bn$ <> "ERROR$" AND bn$ <> "OCTO$" AND bn$ <> "BINB$" AND bn$ <> "FORMAT$" THEN
                      bn$ = strip_suffix$(bn$)
                    END IF
                  ELSEIF RIGHT$(bn$, 1) = "%" OR RIGHT$(bn$, 1) = "!" OR RIGHT$(bn$, 1) = "#" THEN
                    bn$ = strip_suffix$(bn$)
                  END IF
                  cir$ = "call " + bn$ + "("
                  i = 1
                  WHILE i <= fnargs
                    IF i > 1 THEN
                      cir$ = cir$ + ", "
                    END IF
                    cir$ = cir$ + fargs$(i)
                    i = i + 1
                  WEND
                  cir$ = cir$ + ")"
                  spVal = spVal + 1
                  valStack$(spVal) = cir$
                  IF RIGHT$(fname$, 1) = "$" THEN
                    valType$(spVal) = "string"
                  ELSEIF RIGHT$(fname$, 1) = "!" OR RIGHT$(fname$, 1) = "#" THEN
                    valType$(spVal) = "float"
                  ELSE
                    valType$(spVal) = "integer"
                  END IF
                  expectOp = 1
                ELSEIF spOp > 0 AND LEFT$(opStack$(spOp), 4) = "ARR:" THEN
                  spOp = spOp - 1
                  fname$ = funcName$(funcSP)
                  fnargs = spVal - funcStart(funcSP) + 1
                  funcSP = funcSP - 1
                  nargs = fnargs
                  WHILE nargs > 0
                    fargs$(nargs) = valStack$(spVal)
                    spVal = spVal - 1
                    nargs = nargs - 1
                  WEND
                  vtype$ = "integer"
                  IF RIGHT$(fname$, 1) = "$" THEN
                    vtype$ = "string"
                  ELSEIF RIGHT$(fname$, 1) = "!" OR RIGHT$(fname$, 1) = "#" THEN
                    vtype$ = "float"
                  END IF
                  spVal = spVal + 1
                  valStack$(spVal) = "array_access(" + fname$ + ":" + vtype$ + "[" + fargs$(1) + "])"
                  valType$(spVal) = vtype$
                  expectOp = 1
                END IF
              END IF
              pendingOp$ = ""
            ELSEIF pendingOp$ = "," THEN
              pendingOp$ = ""
              expectOp = 0
            ELSEIF pendingOp$ <> "" THEN
              spOp = spOp + 1
              opStack$(spOp) = pendingOp$
              opPrec(spOp) = pendingPrec
              pendingOp$ = ""
              expectOp = 0
            END IF
          END IF
        ELSE
          bop$ = opStack$(spOp)
          spOp = spOp - 1
          IF bop$ = "NOT" THEN
            bleft$ = valStack$(spVal)
            valStack$(spVal) = "not(" + bleft$ + ")"
            valType$(spVal) = "integer"
          ELSE
            bright$ = valStack$(spVal)
            brt$ = valType$(spVal)
            spVal = spVal - 1
            bleft$ = valStack$(spVal)
            blt$ = valType$(spVal)
            IF bop$ = "+" OR bop$ = "-" OR bop$ = "*" OR bop$ = "/" OR bop$ = "\\" OR bop$ = "MOD" OR bop$ = "**" THEN
              bres$ = "arith(" + bleft$ + " " + bop$ + " " + bright$ + ")"
              valStack$(spVal) = bres$
              IF bop$ = "+" AND (blt$ = "string" OR brt$ = "string") THEN
                valType$(spVal) = "string"
              ELSEIF bop$ = "\\" OR bop$ = "MOD" THEN
                valType$(spVal) = "integer"
              ELSEIF blt$ = "float" OR brt$ = "float" THEN
                valType$(spVal) = "float"
              ELSE
                valType$(spVal) = "integer"
              END IF
            ELSEIF bop$ = "AND" THEN
              valStack$(spVal) = "and(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSEIF bop$ = "OR" THEN
              valStack$(spVal) = "or(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSEIF bop$ = "XOR" THEN
              valStack$(spVal) = "xor(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSEIF bop$ = "&&" THEN
              valStack$(spVal) = "land(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSEIF bop$ = "||" THEN
              valStack$(spVal) = "lor(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSEIF bop$ = "^^" THEN
              valStack$(spVal) = "lxor(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSE
              IF bop$ = "==" THEN
                bop$ = "="
              END IF
              IF bop$ = "!=" THEN
                bop$ = "<>"
              END IF
              valStack$(spVal) = "compare(" + bleft$ + " " + bop$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            END IF
          END IF
        END IF
      ELSEIF edone = 0 THEN
        t$ = tt$(tpos)
        v$ = tv$(tpos)
        isStop = 0
        IF exprStop$ = "newline" AND t$ = "newline" THEN
          isStop = 1
        ELSEIF exprStop$ = "THEN" AND t$ = "keyword" AND v$ = "THEN" THEN
          isStop = 1
        ELSEIF exprStop$ = "TO" AND t$ = "keyword" AND v$ = "TO" THEN
          isStop = 1
        ELSEIF exprStop$ = "STEP_OR_NL" AND t$ = "newline" THEN
          isStop = 1
        ELSEIF exprStop$ = "STEP_OR_NL" AND t$ = "keyword" AND v$ = "STEP" THEN
          isStop = 1
        ELSEIF exprStop$ = ")" AND t$ = "symbol" AND (v$ = ")" OR v$ = "]") AND parenDepth = 0 THEN
          isStop = 1
        ELSEIF exprStop$ = "COMMA_OR_RPAREN" AND t$ = "symbol" AND (v$ = "," OR v$ = ")" OR v$ = "]") AND parenDepth = 0 THEN
          isStop = 1
        END IF
        IF isStop = 1 THEN
          edone = 1
          popPrec = 0
        ELSEIF expectOp = 0 THEN
          IF t$ = "symbol" AND v$ = "@" THEN
            tpos = tpos + 1
            t$ = tt$(tpos)
            v$ = tv$(tpos)
          END IF
          IF t$ = "number" THEN
            spVal = spVal + 1
            isFloat = 0
            IF LEFT$(v$, 2) <> "0x" AND LEFT$(v$, 2) <> "0X" THEN
              ei = 1
              WHILE ei <= LEN(v$)
                IF ASC(MID$(v$, ei, 1)) = 46 OR ASC(MID$(v$, ei, 1)) = 101 OR ASC(MID$(v$, ei, 1)) = 69 THEN
                  isFloat = 1
                  ei = LEN(v$) + 1
                END IF
                ei = ei + 1
              WEND
            END IF
            IF isFloat = 1 THEN
              valStack$(spVal) = "float(" + v$ + ")"
              valType$(spVal) = "float"
            ELSE
              valStack$(spVal) = "integer(" + v$ + ")"
              valType$(spVal) = "integer"
            END IF
            tpos = tpos + 1
            expectOp = 1
          ELSEIF t$ = "string" THEN
            esc$ = ""
            ei = 1
            WHILE ei <= LEN(v$)
              IF ASC(MID$(v$, ei, 1)) = 92 THEN
                esc$ = esc$ + CHR$(92) + CHR$(92)
              ELSEIF ASC(MID$(v$, ei, 1)) = 34 THEN
                esc$ = esc$ + CHR$(92) + CHR$(34)
              ELSEIF ASC(MID$(v$, ei, 1)) = 9 THEN
                esc$ = esc$ + CHR$(92) + CHR$(116)
              ELSEIF ASC(MID$(v$, ei, 1)) = 10 THEN
                esc$ = esc$ + CHR$(92) + CHR$(110)
              ELSEIF ASC(MID$(v$, ei, 1)) = 13 THEN
                esc$ = esc$ + CHR$(92) + CHR$(114)
              ELSE
                esc$ = esc$ + MID$(v$, ei, 1)
              END IF
              ei = ei + 1
            WEND
            spVal = spVal + 1
            valStack$(spVal) = "string(" + CHR$(34) + esc$ + CHR$(34) + ")"
            valType$(spVal) = "string"
            tpos = tpos + 1
            expectOp = 1
          ELSEIF t$ = "ident" THEN
            iname$ = v$
            tpos = tpos + 1
            IF tpos <= ntok AND tt$(tpos) = "symbol" AND (tv$(tpos) = "(" OR tv$(tpos) = "[") THEN
              isArr = 0
              j = 1
              WHILE j <= arrSP
                IF arrNames$(j) = iname$ THEN
                  isArr = 1
                  j = arrSP + 1
                END IF
                j = j + 1
              WEND
              funcSP = funcSP + 1
              funcName$(funcSP) = iname$
              funcStart(funcSP) = spVal + 1
              spOp = spOp + 1
              IF isArr = 1 THEN
                opStack$(spOp) = "ARR:"
              ELSE
                opStack$(spOp) = "FUNC:"
              END IF
              spOp = spOp + 1
              opStack$(spOp) = "("
              parenDepth = parenDepth + 1
              tpos = tpos + 1
            ELSE
              vtype$ = "integer"
              vname$ = strip_suffix$(iname$)
              vtype$ = ##suffixType$
              spVal = spVal + 1
              valStack$(spVal) = "symbol(" + vname$ + ":" + vtype$ + ")"
              valType$(spVal) = vtype$
              expectOp = 1
            END IF
          ELSEIF t$ = "shared" THEN
            vtype$ = "integer"
            vname$ = strip_suffix$(v$)
            vtype$ = ##suffixType$
            spVal = spVal + 1
            valStack$(spVal) = "shared(##" + vname$ + ":" + vtype$ + ")"
            valType$(spVal) = vtype$
            tpos = tpos + 1
            expectOp = 1
          ELSEIF t$ = "sysconst" THEN
            vtype$ = "integer"
            ci = 1
            WHILE ci <= nConst
              IF constName$(ci) = v$ THEN
                vtype$ = constType$(ci)
                ci = nConst + 1
              END IF
              ci = ci + 1
            WEND
            spVal = spVal + 1
            ci = 1
            WHILE ci <= nConst
              IF constName$(ci) = v$ THEN
                valStack$(spVal) = "constant($$" + v$ + ":" + vtype$ + " = " + constValue$(ci) + ")"
                ci = nConst + 1
              END IF
              ci = ci + 1
            WEND
            valType$(spVal) = vtype$
            tpos = tpos + 1
            expectOp = 1
          ELSEIF t$ = "symbol" AND v$ = "(" THEN
            spOp = spOp + 1
            opStack$(spOp) = "("
            parenDepth = parenDepth + 1
            tpos = tpos + 1
          ELSEIF t$ = "keyword" AND v$ = "NOT" THEN
            spOp = spOp + 1
            opStack$(spOp) = "NOT"
            opPrec(spOp) = 3
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND (v$ = ")" OR v$ = "]") AND parenDepth > 0 THEN
            popPrec = 0
            pendingOp$ = ")"
            tpos = tpos + 1
          ELSE
            edone = 1
            popPrec = 0
          END IF
        ELSE
          IF t$ = "symbol" AND (v$ = "+" OR v$ = "-") THEN
            prec = 5
            popPrec = prec
            pendingOp$ = v$
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND (v$ = "*" OR v$ = "/" OR v$ = "\\") THEN
            prec = 6
            popPrec = prec
            pendingOp$ = v$
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "keyword" AND v$ = "MOD" THEN
            prec = 6
            popPrec = prec
            pendingOp$ = "MOD"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "power" AND v$ = "**" THEN
            prec = 7
            popPrec = prec
            pendingOp$ = "**"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND (v$ = "=" OR v$ = "==" OR v$ = "<" OR v$ = ">" OR v$ = "<=" OR v$ = ">=" OR v$ = "<>" OR v$ = "!=") THEN
            prec = 4
            popPrec = prec
            pendingOp$ = v$
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "keyword" AND v$ = "AND" THEN
            prec = 2
            popPrec = prec
            pendingOp$ = "AND"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND v$ = "&&" THEN
            prec = 2
            popPrec = prec
            pendingOp$ = "&&"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "keyword" AND v$ = "OR" THEN
            prec = 1
            popPrec = prec
            pendingOp$ = "OR"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "keyword" AND v$ = "XOR" THEN
            prec = 1
            popPrec = prec
            pendingOp$ = "XOR"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND v$ = "||" THEN
            prec = 1
            popPrec = prec
            pendingOp$ = "||"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND v$ = "^^" THEN
            prec = 1
            popPrec = prec
            pendingOp$ = "^^"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND (v$ = ")" OR v$ = "]") THEN
            popPrec = 0
            pendingOp$ = ")"
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND v$ = "," THEN
            popPrec = 0
            pendingOp$ = ","
            tpos = tpos + 1
          ELSE
            edone = 1
            popPrec = 0
          END IF
        END IF
      END IF
    WEND
    eir$ = valStack$(spVal)
    etype$ = valType$(spVal)
    IF stmtState = 1 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "print " + eir$
      stmtState = 0
    ELSEIF stmtState = 2 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "assign " + assignTarget$ + ":" + assignType$ + " = " + eir$
      stmtState = 0
    ELSEIF stmtState = 3 THEN
      tpos = tpos + 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "if " + eir$
      indent = indent + 1
      ' Check for single-line IF (statement after THEN on same line)
      IF tpos <= ntok AND NOT (tt$(tpos) = "newline") THEN
        singleLineIf = 1
      END IF
      stmtState = 0
    ELSEIF stmtState = 4 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "while " + eir$
      indent = indent + 1
      stmtState = 0
    ELSEIF stmtState = 5 THEN
      forStart$ = eir$
      tpos = tpos + 1
      stmtState = 6
      exprStop$ = "STEP_OR_NL"
    ELSEIF stmtState = 6 THEN
      forEnd$ = eir$
      IF tpos <= ntok AND tt$(tpos) = "keyword" AND tv$(tpos) = "STEP" THEN
        tpos = tpos + 1
        stmtState = 14
        exprStop$ = "newline"
      ELSE
        prefix$ = ""
        i = 1
        WHILE i <= indent
          prefix$ = prefix$ + "  "
          i = i + 1
        WEND
        vtype$ = "integer"
        vname$ = strip_suffix$(forVar$)
        vtype$ = ##suffixType$
        PRINT prefix$ + "for " + vname$ + ":" + vtype$ + " = " + forStart$ + " to " + forEnd$
        indent = indent + 1
        stmtState = 0
      END IF
    ELSEIF stmtState = 7 THEN
      tpos = tpos + 1
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "dim " + dimName$ + ":" + dimType$ + "[" + eir$ + "]"
      stmtState = 0
    ELSEIF stmtState = 8 THEN
      arrIndex$ = eir$
      tpos = tpos + 2
      stmtState = 9
      exprStop$ = "newline"
    ELSEIF stmtState = 9 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      vtype$ = "integer"
      IF RIGHT$(arrName$, 1) = "$" THEN
        vtype$ = "string"
      ELSEIF RIGHT$(arrName$, 1) = "!" OR RIGHT$(arrName$, 1) = "#" THEN
        vtype$ = "float"
      END IF
      PRINT prefix$ + "array_assign " + arrName$ + ":" + vtype$ + "[" + arrIndex$ + "] = " + eir$
      stmtState = 0
    ELSEIF stmtState = 10 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "return " + eir$
      stmtState = 0
    ELSEIF stmtState = 11 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + eir$
      stmtState = 0
    ELSEIF stmtState = 12 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      PRINT prefix$ + "shared ##" + assignTarget$ + ":" + assignType$ + " = " + eir$
      stmtState = 0
    ELSEIF stmtState = 13 THEN
      PRINT "const $$" + assignTarget$ + ":" + assignType$ + " = " + eir$
      nConst = nConst + 1
      constName$(nConst) = assignTarget$
      constType$(nConst) = assignType$
      constValue$(nConst) = eir$
      ' Every statement arm returns to state 0; this one did not, so the
      ' next token was re-parsed as this const's expression. A token the
      ' expression parser stops on without consuming then re-emitted the
      ' same const line forever (aarray_ISNODE `$$X = 0x20000000`: 5.9 M
      ' lines / 1.5 GB before the CPU cap).
      stmtState = 0
    ELSEIF stmtState = 14 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      vtype$ = "integer"
      vname$ = strip_suffix$(forVar$)
      vtype$ = ##suffixType$
      PRINT prefix$ + "for " + vname$ + ":" + vtype$ + " = " + forStart$ + " to " + forEnd$ + " step " + eir$
      indent = indent + 1
    ELSEIF stmtState = 15 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      IF doMode$ = "WHILE" THEN
        PRINT prefix$ + "do while " + eir$
      ELSE
        PRINT prefix$ + "do until " + eir$
      END IF
      indent = indent + 1
      stmtState = 0
    ELSEIF stmtState = 16 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      IF doMode$ = "WHILE" THEN
        PRINT prefix$ + "loop while " + eir$
      ELSE
        PRINT prefix$ + "loop until " + eir$
      END IF
      stmtState = 0
    ELSEIF stmtState = 18 THEN
      midTarget$ = eir$
      tpos = tpos + 1
      stmtState = 19
      exprStop$ = "COMMA_OR_RPAREN"
    ELSEIF stmtState = 19 THEN
      midStart$ = eir$
      IF tpos <= ntok AND tt$(tpos) = "symbol" AND tv$(tpos) = "," THEN
        tpos = tpos + 1
        stmtState = 20
        exprStop$ = ")"
      ELSE
        tpos = tpos + 1
        tpos = tpos + 1
        stmtState = 21
        exprStop$ = "newline"
      END IF
    ELSEIF stmtState = 20 THEN
      midLen$ = eir$
      tpos = tpos + 1
      tpos = tpos + 1
      stmtState = 21
      exprStop$ = "newline"
    ELSEIF stmtState = 21 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      IF midLen$ = "" THEN
        PRINT prefix$ + "mid_assign " + midTarget$ + " | " + midStart$ + " | " + eir$
      ELSE
        PRINT prefix$ + "mid_assign " + midTarget$ + " | " + midStart$ + " | " + midLen$ + " | " + eir$
      END IF
      midLen$ = ""
      stmtState = 0
    END IF
  END IF
WEND
END FUNCTION

FUNCTION strip_suffix$(name$)
  DIM lastChar
  lastChar = ASC(RIGHT$(name$, 1))
  IF lastChar = 36 THEN
    ##suffixType$ = "string"
    strip_suffix$ = LEFT$(name$, LEN(name$) - 1)
  ELSEIF lastChar = 37 THEN
    ##suffixType$ = "integer"
    strip_suffix$ = LEFT$(name$, LEN(name$) - 1)
  ELSEIF lastChar = 33 THEN
    ##suffixType$ = "float"
    strip_suffix$ = LEFT$(name$, LEN(name$) - 1)
  ELSEIF lastChar = 35 THEN
    ##suffixType$ = "float"
    strip_suffix$ = LEFT$(name$, LEN(name$) - 1)
  ELSE
    ##suffixType$ = "integer"
    strip_suffix$ = name$
  END IF
END FUNCTION
