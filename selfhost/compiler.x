VERSION "0.1"
FUNCTION Main
DIM src$
DIM line$
DIM tok$
DIM tk$
DIM pos
DIM ch
DIM ntok
DIM done
DIM tt$(65536)
DIM tv$(65536)
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
DIM fargs$(8)
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
DIM arrNames$(64)
DIM arrSP
DIM isArr
DIM lookPos
DIM parenCount
DIM params$
DIM pname$
DIM esc$
DIM ei
DIM constName$(64)
DIM constType$(64)
DIM constValue$(64)
DIM nConst
DIM ci
DIM isFloat
DIM subName$
##suffixType$ = ""
nConst = 0

DIM srcLines$(20000)
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

ntok = 0
pos = 1
WHILE pos <= LEN(src$)
  ch = ASC(MID$(src$, pos, 1))
  IF ch = 32 OR ch = 9 OR ch = 13 THEN
    pos = pos + 1
  ELSEIF ch = 39 THEN
    WHILE pos <= LEN(src$) AND ASC(MID$(src$, pos, 1)) <> 10
      pos = pos + 1
    WEND
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
    tk$ = "ident"
    IF tok$ = "PRINT" OR tok$ = "IF" OR tok$ = "THEN" OR tok$ = "ELSE" OR tok$ = "END" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "FUNCTION" OR tok$ = "DIM" OR tok$ = "FOR" OR tok$ = "TO" OR tok$ = "NEXT" OR tok$ = "STEP" OR tok$ = "DO" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "WHILE" OR tok$ = "WEND" OR tok$ = "RETURN" OR tok$ = "AND" OR tok$ = "OR" OR tok$ = "XOR" OR tok$ = "UNTIL" OR tok$ = "LOOP" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "NOT" OR tok$ = "MOD" OR tok$ = "EXIT" OR tok$ = "ELSEIF" OR tok$ = "VERSION" OR tok$ = "GOSUB" OR tok$ = "BREAK" OR tok$ = "CONST" OR tok$ = "LET" OR tok$ = "GOTO" THEN
      tk$ = "keyword"
    END IF
    ntok = ntok + 1
    tt$(ntok) = tk$
    tv$(ntok) = tok$
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

WHILE tpos <= ntok
  IF stmtState = 0 THEN
    IF singleLineIf = 2 THEN
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
        PRINT prefix$ + "return"
      ELSE
        stmtState = 10
        exprStop$ = "newline"
      END IF
    ELSEIF t$ = "keyword" AND v$ = "GOSUB" THEN
      tpos = tpos + 1
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
      tpos = tpos + 1
    ELSEIF t$ = "sysconst" THEN
      assignTarget$ = v$
      assignType$ = "integer"
      tpos = tpos + 2
      stmtState = 13
      exprStop$ = "newline"
    ELSEIF t$ = "ident" AND tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND tv$(tpos + 1) = ":" THEN
      tpos = tpos + 2
    ELSEIF t$ = "ident" AND v$ = "MID$" AND tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND tv$(tpos + 1) = "(" THEN
      ' MID$ assignment: MID$(target, start[, len]) = value
      tpos = tpos + 2
      stmtState = 18
      exprStop$ = "COMMA_OR_RPAREN"
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
