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
DIM tt$(8192)
DIM tv$(8192)
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
DIM assignTarget$
DIM assignType$
DIM forVar$
DIM forStart$
DIM arrName$
DIM arrIndex$
DIM dimName$
DIM dimType$
DIM ifDepth
DIM ifStack(64)
DIM ifSP
DIM arrNames$(64)
DIM arrSP
DIM isArr
DIM lookPos
DIM parenCount
DIM params$
DIM pname$

src$ = ""
WHILE EOF() = 0
  line$ = READLINE$()
  IF EOF() = 0 THEN
    src$ = src$ + line$ + CHR$(10)
  ELSE
    src$ = src$ + line$
  END IF
WEND

ntok = 0
pos = 1
WHILE pos <= LEN(src$)
  ch = ASC(MID$(src$, pos, 1))
  IF ch = 32 OR ch = 9 OR ch = 13 THEN
    pos = pos + 1
  ELSEIF ch = 10 THEN
    ntok = ntok + 1
    tt$(ntok) = "newline"
    tv$(ntok) = ""
    pos = pos + 1
  ELSEIF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) THEN
    tok$ = ""
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF (ch >= 65 AND ch <= 90) OR (ch >= 97 AND ch <= 122) OR (ch >= 48 AND ch <= 57) OR ch = 36 OR ch = 37 THEN
          tok$ = tok$ + CHR$(ch)
          pos = pos + 1
        ELSE
          done = 1
        END IF
      END IF
    WEND
    tk$ = "ident"
    IF tok$ = "PRINT" OR tok$ = "IF" OR tok$ = "THEN" OR tok$ = "ELSE" OR tok$ = "END" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "FUNCTION" OR tok$ = "DIM" OR tok$ = "FOR" OR tok$ = "TO" OR tok$ = "NEXT" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "WHILE" OR tok$ = "WEND" OR tok$ = "RETURN" OR tok$ = "AND" OR tok$ = "OR" THEN
      tk$ = "keyword"
    ELSEIF tok$ = "NOT" OR tok$ = "EXIT" OR tok$ = "ELSEIF" OR tok$ = "VERSION" THEN
      tk$ = "keyword"
    END IF
    ntok = ntok + 1
    tt$(ntok) = tk$
    tv$(ntok) = tok$
  ELSEIF (ch >= 48 AND ch <= 57) THEN
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
    ntok = ntok + 1
    tt$(ntok) = "number"
    tv$(ntok) = tok$
  ELSEIF ch = 34 THEN
    tok$ = ""
    pos = pos + 1
    done = 0
    WHILE done = 0
      IF pos > LEN(src$) THEN
        done = 1
      ELSE
        ch = ASC(MID$(src$, pos, 1))
        IF ch = 34 THEN
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

WHILE tpos <= ntok
  IF stmtState = 0 THEN
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
            IF RIGHT$(pname$, 1) = "$" THEN
              vt$ = "string"
              pname$ = LEFT$(pname$, LEN(pname$) - 1)
            END IF
            params$ = params$ + pname$ + ":" + vt$
          END IF
          tpos = tpos + 1
        WEND
        tpos = tpos + 1
      END IF
      PRINT "function " + v$ + "(" + params$ + ") -> integer"
    ELSEIF t$ = "keyword" AND v$ = "DIM" THEN
      tpos = tpos + 1
      v$ = tv$(tpos)
      tpos = tpos + 1
      vt$ = "integer"
      bn$ = v$
      IF RIGHT$(v$, 1) = "$" THEN
        vt$ = "string"
        bn$ = LEFT$(v$, LEN(v$) - 1)
      END IF
      IF tpos <= ntok AND tt$(tpos) = "symbol" AND tv$(tpos) = "(" THEN
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
      IF isArr = 1 AND tpos + 1 <= ntok AND tt$(tpos + 1) = "symbol" AND tv$(tpos + 1) = "(" THEN
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
          bn$ = v$
          IF RIGHT$(v$, 1) = "$" THEN
            vt$ = "string"
            bn$ = LEFT$(v$, LEN(v$) - 1)
          END IF
          assignType$ = vt$
          assignTarget$ = bn$
          tpos = tpos + 2
          stmtState = 2
          exprStop$ = "newline"
        END IF
      END IF
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
                  cir$ = "call " + fname$ + "("
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
            IF bop$ = "+" OR bop$ = "-" OR bop$ = "*" OR bop$ = "/" THEN
              bres$ = "arith(" + bleft$ + " " + bop$ + " " + bright$ + ")"
              valStack$(spVal) = bres$
              IF bop$ = "+" AND (blt$ = "string" OR brt$ = "string") THEN
                valType$(spVal) = "string"
              ELSE
                valType$(spVal) = "integer"
              END IF
            ELSEIF bop$ = "AND" THEN
              valStack$(spVal) = "and(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSEIF bop$ = "OR" THEN
              valStack$(spVal) = "or(" + bleft$ + " " + bright$ + ")"
              valType$(spVal) = "integer"
            ELSE
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
        ELSEIF exprStop$ = ")" AND t$ = "symbol" AND v$ = ")" AND parenDepth = 0 THEN
          isStop = 1
        END IF
        IF isStop = 1 THEN
          edone = 1
          popPrec = 0
        ELSEIF expectOp = 0 THEN
          IF t$ = "number" THEN
            spVal = spVal + 1
            valStack$(spVal) = "integer(" + v$ + ")"
            valType$(spVal) = "integer"
            tpos = tpos + 1
            expectOp = 1
          ELSEIF t$ = "string" THEN
            spVal = spVal + 1
            valStack$(spVal) = "string(" + CHR$(34) + v$ + CHR$(34) + ")"
            valType$(spVal) = "string"
            tpos = tpos + 1
            expectOp = 1
          ELSEIF t$ = "ident" THEN
            iname$ = v$
            tpos = tpos + 1
            IF tpos <= ntok AND tt$(tpos) = "symbol" AND tv$(tpos) = "(" THEN
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
              vname$ = iname$
              IF RIGHT$(iname$, 1) = "$" THEN
                vtype$ = "string"
                vname$ = LEFT$(iname$, LEN(iname$) - 1)
              END IF
              spVal = spVal + 1
              valStack$(spVal) = "symbol(" + vname$ + ":" + vtype$ + ")"
              valType$(spVal) = vtype$
              expectOp = 1
            END IF
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
          ELSEIF t$ = "symbol" AND v$ = ")" AND parenDepth > 0 THEN
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
          ELSEIF t$ = "symbol" AND (v$ = "*" OR v$ = "/") THEN
            prec = 6
            popPrec = prec
            pendingOp$ = v$
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND (v$ = "=" OR v$ = "<" OR v$ = ">" OR v$ = "<=" OR v$ = ">=" OR v$ = "<>") THEN
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
          ELSEIF t$ = "keyword" AND v$ = "OR" THEN
            prec = 1
            popPrec = prec
            pendingOp$ = "OR"
            pendingPrec = prec
            tpos = tpos + 1
          ELSEIF t$ = "symbol" AND v$ = ")" THEN
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
      exprStop$ = "newline"
    ELSEIF stmtState = 6 THEN
      prefix$ = ""
      i = 1
      WHILE i <= indent
        prefix$ = prefix$ + "  "
        i = i + 1
      WEND
      vtype$ = "integer"
      vname$ = forVar$
      IF RIGHT$(forVar$, 1) = "$" THEN
        vname$ = LEFT$(forVar$, LEN(forVar$) - 1)
      END IF
      PRINT prefix$ + "for " + vname$ + ":" + vtype$ + " = " + forStart$ + " to " + eir$
      indent = indent + 1
      stmtState = 0
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
    END IF
  END IF
WEND
END FUNCTION
