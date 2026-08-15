VERSION "0.1"
FUNCTION Main
DIM src$
DIM line$
DIM pos
DIM ch
DIM numLines
DIM i
DIM j
DIM stmt$
DIM inFunc
DIM hasMain
DIM cCode$
DIM mainBody$
DIM rest$
DIM parenPos
DIM funcName$
DIM afterParen$
DIM closeParen
DIM params$
DIM retType$
DIM fwdPos
DIM fwdLine$
DIM fwdCh
DIM fwdJ
DIM fwdStmt$
DIM fwdRest$
DIM fwdParen
DIM fwdName$
DIM fwdAfter$
DIM fwdClose
DIM fwdParams$
DIM fwdRet$
DIM fwdHash
DIM fwdColon
DIM fwdSName$
DIM fwdSAfter$
DIM fwdSPos
DIM fwdSType$

src$ = ""
WHILE EOF() = 0
  line$ = READLINE$()
  IF EOF() = 0 THEN
    src$ = src$ + line$ + CHR$(10)
  ELSE
    src$ = src$ + line$
  END IF
WEND

PRINT "#include <stdio.h>"
PRINT "#include <stdlib.h>"
PRINT "#include <string.h>"
PRINT "#include <ctype.h>"
PRINT "#include <math.h>"
PRINT ""
PRINT "static char* xb_strdup(const char* s) { size_t n = strlen(s) + 1; char* r = (char*)malloc(n); memcpy(r, s, n); return r; }"
PRINT "static char* xb_str(const char* s) { return xb_strdup(s); }"
PRINT "static char* xb_concat(const char* a, const char* b) {"
PRINT "    size_t la = strlen(a), lb = strlen(b);"
PRINT "    char* r = malloc(la + lb + 1);"
PRINT "    memcpy(r, a, la);"
PRINT "    memcpy(r + la, b, lb);"
PRINT "    r[la + lb] = 0;"
PRINT "    return r;"
PRINT "}"
PRINT "static int xb_len(const char* s) { return (int)strlen(s); }"
PRINT "static int xb_asc(const char* s) { return (unsigned char)s[0]; }"
PRINT "static char* xb_chr(int c) { char* r = malloc(2); r[0] = (char)c; r[1] = 0; return r; }"
PRINT "static char* xb_left(const char* s, int n) {"
PRINT "    int len = (int)strlen(s);"
PRINT "    if (n < 0) n = 0;"
PRINT "    if (n > len) n = len;"
PRINT "    char* r = malloc(n + 1);"
PRINT "    memcpy(r, s, n);"
PRINT "    r[n] = 0;"
PRINT "    return r;"
PRINT "}"
PRINT "static char* xb_right(const char* s, int n) {"
PRINT "    int len = (int)strlen(s);"
PRINT "    if (n < 0) n = 0;"
PRINT "    if (n > len) n = len;"
PRINT "    char* r = malloc(n + 1);"
PRINT "    memcpy(r, s + len - n, n);"
PRINT "    r[n] = 0;"
PRINT "    return r;"
PRINT "}"
PRINT "static char* xb_mid(const char* s, int start, int len) {"
PRINT "    int slen = (int)strlen(s);"
PRINT "    if (start < 1) start = 1;"
PRINT "    int off = start - 1;"
PRINT "    if (off >= slen) return xb_strdup(" + CHR$(34) + CHR$(34) + ");"
PRINT "    if (len < 0) len = slen - off;"
PRINT "    if (off + len > slen) len = slen - off;"
PRINT "    char* r = malloc(len + 1);"
PRINT "    memcpy(r, s + off, len);"
PRINT "    r[len] = 0;"
PRINT "    return r;"
PRINT "}"
PRINT "static int xb_instr(const char* s, const char* sub) {"
PRINT "    const char* p = strstr(s, sub);"
PRINT "    return p ? (int)(p - s) + 1 : 0;"
PRINT "}"
PRINT "static int xb_val(const char* s) { return atoi(s); }"
PRINT "static char* xb_str_num(int v) { char* r = malloc(16); snprintf(r, 16, " + CHR$(34) + "%d" + CHR$(34) + ", v); return r; }"
PRINT "static int xb_eof(void) {"
PRINT "    int c = fgetc(stdin);"
PRINT "    if (c == EOF) return 1;"
PRINT "    ungetc(c, stdin);"
PRINT "    return 0;"
PRINT "}"
PRINT "static char* xb_readline(void) {"
PRINT "    char buf[65536];"
PRINT "    if (!fgets(buf, sizeof(buf), stdin)) return xb_strdup(" + CHR$(34) + CHR$(34) + ");"
PRINT "    int len = (int)strlen(buf);"
PRINT "    if (len > 0 && buf[len-1] == '\n') buf[len-1] = 0;"
PRINT "    return xb_strdup(buf);"
PRINT "}"
PRINT "static char* xb_ucase(const char* s) { char* r = xb_strdup(s); for (char* p = r; *p; p++) *p = toupper((unsigned char)*p); return r; }"
PRINT "static char* xb_lcase(const char* s) { char* r = xb_strdup(s); for (char* p = r; *p; p++) *p = tolower((unsigned char)*p); return r; }"
PRINT "static char* xb_trim(const char* s) { const char* start = s; while (*start == ' ' || *start == '\t') start++; const char* end = s + strlen(s) - 1; while (end > start && (*end == ' ' || *end == '\t')) end--; int len = end - start + 1; char* r = malloc(len + 1); memcpy(r, start, len); r[len] = 0; return r; }"
PRINT "static char* xb_ltrim(const char* s) { const char* start = s; while (*start == ' ' || *start == '\t') start++; return xb_strdup(start); }"
PRINT "static char* xb_rtrim(const char* s) { int len = (int)strlen(s); while (len > 0 && (s[len-1] == ' ' || s[len-1] == '\t')) len--; char* r = malloc(len + 1); memcpy(r, s, len); r[len] = 0; return r; }"
PRINT "static char* xb_space(int n) { if (n < 0) n = 0; char* r = malloc(n + 1); memset(r, ' ', n); r[n] = 0; return r; }"
PRINT "static int xb_abs(int v) { return v < 0 ? -v : v; }"
PRINT "static int xb_sgn(int v) { return (v > 0) - (v < 0); }"
PRINT "static int xb_int(int v) { return v; }"
PRINT "static int xb_fix(int v) { return v; }"
PRINT "static int xb_max(int a, int b) { return a > b ? a : b; }"
PRINT "static int xb_min(int a, int b) { return a < b ? a : b; }"
PRINT "static void xb_print_int(int v) { printf(" + CHR$(34) + "%d\n" + CHR$(34) + ", v); }"
PRINT "static void xb_print_str(const char* s) { printf(" + CHR$(34) + "%s\n" + CHR$(34) + ", s); }"
PRINT "static void xb_print_float(double v) { printf(" + CHR$(34) + "%g\n" + CHR$(34) + ", v); }"
PRINT ""
' Build function return type map for expr_type$ lookups
##funcTypes$ = ""
##sharedDecls$ = ""
' Forward declarations: pre-scan all lines for function signatures
fwdPos = 1
WHILE fwdPos <= LEN(src$)
  fwdLine$ = ""
  WHILE fwdPos <= LEN(src$)
    fwdCh = ASC(MID$(src$, fwdPos, 1))
    fwdPos = fwdPos + 1
    IF fwdCh = 10 THEN
      EXIT WHILE
    END IF
    fwdLine$ = fwdLine$ + CHR$(fwdCh)
  WEND
  fwdJ = 1
  WHILE fwdJ <= LEN(fwdLine$)
    IF ASC(MID$(fwdLine$, fwdJ, 1)) = 32 THEN
      fwdJ = fwdJ + 1
    ELSE
      EXIT WHILE
    END IF
  WEND
  IF fwdJ <= LEN(fwdLine$) THEN
    fwdStmt$ = MID$(fwdLine$, fwdJ, LEN(fwdLine$) - fwdJ + 1)
    IF LEFT$(fwdStmt$, 9) = "function " THEN
      fwdRest$ = MID$(fwdStmt$, 10, LEN(fwdStmt$) - 9)
      fwdParen = INSTR(fwdRest$, "(")
      fwdName$ = LEFT$(fwdRest$, fwdParen - 1)
      fwdAfter$ = MID$(fwdRest$, fwdParen + 1, LEN(fwdRest$) - fwdParen)
      fwdClose = INSTR(fwdAfter$, ")")
      fwdParams$ = LEFT$(fwdAfter$, fwdClose - 1)
      fwdRet$ = MID$(fwdAfter$, fwdClose + 5, LEN(fwdAfter$) - fwdClose - 4)
      PRINT c_type$(fwdRet$) + " xb_user_" + fwdName$ + "(" + emit_params$(fwdParams$) + ");"
      ##funcTypes$ = ##funcTypes$ + fwdName$ + ":" + fwdRet$ + ","
    ELSEIF LEFT$(fwdStmt$, 7) = "shared " THEN
      fwdRest$ = MID$(fwdStmt$, 8, LEN(fwdStmt$) - 7)
      fwdHash = INSTR(fwdRest$, "#")
      IF fwdHash > 0 THEN
        fwdRest$ = MID$(fwdRest$, fwdHash + 2, LEN(fwdRest$) - fwdHash - 1)
      END IF
      fwdColon = INSTR(fwdRest$, ":")
      IF fwdColon > 0 THEN
        fwdSName$ = LEFT$(fwdRest$, fwdColon - 1)
        fwdSAfter$ = MID$(fwdRest$, fwdColon + 1, LEN(fwdRest$) - fwdColon)
        fwdSPos = INSTR(fwdSAfter$, " ")
        IF fwdSPos > 0 THEN
          fwdSType$ = LEFT$(fwdSAfter$, fwdSPos - 1)
        ELSE
          fwdSType$ = fwdSAfter$
        END IF
        IF INSTR(##sharedDecls$, ":" + fwdSName$ + ":") = 0 THEN
          ##sharedDecls$ = ##sharedDecls$ + ":" + fwdSName$ + ":"
          PRINT c_type$(fwdSType$) + " xb_shared_" + fwdSName$ + " = 0;"
        END IF
      END IF
    END IF
  END IF
WEND
PRINT ""

hasMain = 0
inFunc = 0
mainBody$ = ""
pos = 1
WHILE pos <= LEN(src$)
  line$ = ""
  WHILE pos <= LEN(src$)
    ch = ASC(MID$(src$, pos, 1))
    pos = pos + 1
    IF ch = 10 THEN
      EXIT WHILE
    END IF
    line$ = line$ + CHR$(ch)
  WEND

  j = 1
  WHILE j <= LEN(line$)
    IF ASC(MID$(line$, j, 1)) = 32 THEN
      j = j + 1
    ELSE
      EXIT WHILE
    END IF
  WEND

  IF j > LEN(line$) THEN
    ' Empty line, skip
  ELSE
    stmt$ = MID$(line$, j, LEN(line$) - j + 1)

    IF LEFT$(stmt$, 9) = "function " THEN
      inFunc = 1
      rest$ = MID$(stmt$, 10, LEN(stmt$) - 9)
      parenPos = INSTR(rest$, "(")
      funcName$ = LEFT$(rest$, parenPos - 1)
      IF funcName$ = "Main" THEN
        hasMain = 1
      END IF
      afterParen$ = MID$(rest$, parenPos + 1, LEN(rest$) - parenPos)
      closeParen = INSTR(afterParen$, ")")
      params$ = LEFT$(afterParen$, closeParen - 1)
      retType$ = MID$(afterParen$, closeParen + 5, LEN(afterParen$) - closeParen - 4)
      PRINT c_type$(retType$) + " xb_user_" + funcName$ + "(" + emit_params$(params$) + ") {"
      PRINT "    " + c_type$(retType$) + " " + c_var_name$(funcName$, retType$) + " = " + c_default$(retType$) + ";"
    ELSEIF stmt$ = "end function" THEN
      inFunc = 0
      PRINT "    return " + c_var_name$(funcName$, retType$) + ";"
      PRINT "}"
    ELSE
      cCode$ = emit_stmt$(stmt$)
      IF inFunc = 1 THEN
        PRINT cCode$
      ELSE
        mainBody$ = mainBody$ + cCode$ + CHR$(10)
      END IF
    END IF
  END IF
WEND

PRINT "int main(void) {"
IF LEN(mainBody$) > 0 THEN
  PRINT mainBody$
END IF
IF hasMain = 1 THEN
  PRINT "    xb_user_Main();"
END IF
PRINT "    fflush(stdout);"
PRINT "    return 0;"
PRINT "}"
END FUNCTION

FUNCTION c_type$(t$)
  IF t$ = "string" THEN
    c_type$ = "char*"
  ELSEIF t$ = "float" THEN
    c_type$ = "double"
  ELSE
    c_type$ = "int"
  END IF
END FUNCTION

FUNCTION c_var_name$(n$, t$)
  IF t$ = "string" THEN
    c_var_name$ = "xb_str_" + n$
  ELSE
    c_var_name$ = "xb_var_" + n$
  END IF
END FUNCTION

FUNCTION c_default$(t$)
  IF t$ = "string" THEN
    c_default$ = "xb_strdup(" + CHR$(34) + CHR$(34) + ")"
  ELSEIF t$ = "float" THEN
    c_default$ = "0.0"
  ELSE
    c_default$ = "0"
  END IF
END FUNCTION

FUNCTION c_func_name$(n$)
  IF n$ = "LEN" THEN
    c_func_name$ = "xb_len"
  ELSEIF n$ = "ASC" THEN
    c_func_name$ = "xb_asc"
  ELSEIF n$ = "CHR$" THEN
    c_func_name$ = "xb_chr"
  ELSEIF n$ = "LEFT$" THEN
    c_func_name$ = "xb_left"
  ELSEIF n$ = "RIGHT$" THEN
    c_func_name$ = "xb_right"
  ELSEIF n$ = "MID$" THEN
    c_func_name$ = "xb_mid"
  ELSEIF n$ = "INSTR" THEN
    c_func_name$ = "xb_instr"
  ELSEIF n$ = "VAL" THEN
    c_func_name$ = "xb_val"
  ELSEIF n$ = "STR$" THEN
    c_func_name$ = "xb_str_num"
  ELSEIF n$ = "UCASE$" THEN
    c_func_name$ = "xb_ucase"
  ELSEIF n$ = "LCASE$" THEN
    c_func_name$ = "xb_lcase"
  ELSEIF n$ = "TRIM$" THEN
    c_func_name$ = "xb_trim"
  ELSEIF n$ = "LTRIM$" THEN
    c_func_name$ = "xb_ltrim"
  ELSEIF n$ = "RTRIM$" THEN
    c_func_name$ = "xb_rtrim"
  ELSEIF n$ = "SPACE$" THEN
    c_func_name$ = "xb_space"
  ELSEIF n$ = "ABS" THEN
    c_func_name$ = "xb_abs"
  ELSEIF n$ = "SGN" THEN
    c_func_name$ = "xb_sgn"
  ELSEIF n$ = "INT" THEN
    c_func_name$ = "xb_int"
  ELSEIF n$ = "FIX" THEN
    c_func_name$ = "xb_fix"
  ELSEIF n$ = "MAX" THEN
    c_func_name$ = "xb_max"
  ELSEIF n$ = "MIN" THEN
    c_func_name$ = "xb_min"
  ELSEIF n$ = "READLINE$" THEN
    c_func_name$ = "xb_readline"
  ELSEIF n$ = "EOF" THEN
    c_func_name$ = "xb_eof"
  ELSE
    c_func_name$ = "xb_user_" + n$
  END IF
END FUNCTION

FUNCTION c_cmp_op$(o$)
  IF o$ = "=" THEN
    c_cmp_op$ = "=="
  ELSEIF o$ = "<>" THEN
    c_cmp_op$ = "!="
  ELSEIF o$ = "<" THEN
    c_cmp_op$ = "<"
  ELSEIF o$ = ">" THEN
    c_cmp_op$ = ">"
  ELSEIF o$ = "<=" THEN
    c_cmp_op$ = "<="
  ELSEIF o$ = ">=" THEN
    c_cmp_op$ = ">="
  ELSE
    c_cmp_op$ = "=="
  END IF
END FUNCTION

FUNCTION expr_type$(e$)
  DIM rest$
  DIM colonPos
  DIM fn$
  DIM parenPos
  DIM left$
  DIM r$
  DIM right$
  DIM op$
  DIM sp
  DIM sym$
  DIM br
  DIM ftPos
  DIM ftStart
  DIM ftEnd
  DIM ftRest$
  IF LEFT$(e$, 7) = "string(" THEN
    expr_type$ = "string"
  ELSEIF LEFT$(e$, 8) = "integer(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 6) = "float(" THEN
    expr_type$ = "float"
  ELSEIF LEFT$(e$, 7) = "symbol(" THEN
    rest$ = MID$(e$, 8, LEN(e$) - 7)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    colonPos = INSTR(rest$, ":")
    IF colonPos > 0 THEN
      expr_type$ = MID$(rest$, colonPos + 1, LEN(rest$) - colonPos)
    ELSE
      expr_type$ = "integer"
    END IF
  ELSEIF LEFT$(e$, 5) = "call " THEN
    rest$ = MID$(e$, 6, LEN(e$) - 5)
    parenPos = INSTR(rest$, "(")
    IF parenPos > 0 THEN
      fn$ = LEFT$(rest$, parenPos - 1)
    ELSE
      fn$ = rest$
    END IF
    IF fn$ = "LEN" OR fn$ = "ASC" OR fn$ = "INSTR" OR fn$ = "VAL" OR fn$ = "EOF" OR fn$ = "ABS" OR fn$ = "SGN" OR fn$ = "INT" OR fn$ = "FIX" OR fn$ = "MAX" OR fn$ = "MIN" THEN
      expr_type$ = "integer"
    ELSEIF fn$ = "CHR$" OR fn$ = "LEFT$" OR fn$ = "RIGHT$" OR fn$ = "MID$" OR fn$ = "STR$" OR fn$ = "READLINE$" OR fn$ = "UCASE$" OR fn$ = "LCASE$" OR fn$ = "TRIM$" OR fn$ = "LTRIM$" OR fn$ = "RTRIM$" OR fn$ = "SPACE$" THEN
      expr_type$ = "string"
    ELSE
      ftPos = INSTR(##funcTypes$, fn$ + ":")
      IF ftPos > 0 THEN
        ftStart = ftPos + LEN(fn$) + 1
        ftRest$ = MID$(##funcTypes$, ftStart, LEN(##funcTypes$) - ftStart + 1)
        ftEnd = INSTR(ftRest$, ",")
        IF ftEnd > 0 THEN
          expr_type$ = LEFT$(ftRest$, ftEnd - 1)
        ELSE
          expr_type$ = "integer"
        END IF
      ELSE
        expr_type$ = "integer"
      END IF
    END IF
  ELSEIF LEFT$(e$, 6) = "arith(" THEN
    rest$ = MID$(e$, 7, LEN(e$) - 6)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    r$ = after_first$(rest$)
    sp = INSTR(r$, " ")
    IF sp > 0 THEN
      op$ = LEFT$(r$, sp - 1)
      right$ = MID$(r$, sp + 1, LEN(r$) - sp)
    ELSE
      op$ = r$
      right$ = ""
    END IF
    IF op$ = "+" AND (expr_type$(left$) = "string" OR expr_type$(right$) = "string") THEN
      expr_type$ = "string"
    ELSE
      expr_type$ = "integer"
    END IF
  ELSEIF LEFT$(e$, 8) = "compare(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 4) = "not(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 4) = "and(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 3) = "or(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 13) = "array_access(" THEN
    rest$ = MID$(e$, 14, LEN(e$) - 13)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    br = INSTR(rest$, "[")
    IF br > 0 THEN
      sym$ = LEFT$(rest$, br - 1)
      colonPos = INSTR(sym$, ":")
      IF colonPos > 0 THEN
        expr_type$ = MID$(sym$, colonPos + 1, LEN(sym$) - colonPos)
      ELSE
        expr_type$ = "integer"
      END IF
    ELSE
      expr_type$ = "integer"
    END IF
  ELSEIF LEFT$(e$, 7) = "shared(" THEN
    rest$ = MID$(e$, 8, LEN(e$) - 7)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    sp = INSTR(rest$, "##")
    IF sp > 0 THEN
      rest$ = MID$(rest$, sp + 2, LEN(rest$) - sp - 1)
    END IF
    colonPos = INSTR(rest$, ":")
    IF colonPos > 0 THEN
      expr_type$ = MID$(rest$, colonPos + 1, LEN(rest$) - colonPos)
    ELSE
      expr_type$ = "integer"
    END IF
  ELSE
    expr_type$ = "integer"
  END IF
END FUNCTION

FUNCTION first_expr$(s$)
  DIM p
  DIM depth
  DIM ch
  DIM q
  DIM inQuote
  IF LEFT$(s$, 7) = "string(" THEN
    q = 9
    WHILE q <= LEN(s$)
      IF ASC(MID$(s$, q, 1)) = 34 THEN
        IF q + 1 <= LEN(s$) AND ASC(MID$(s$, q + 1, 1)) = 41 THEN
          first_expr$ = LEFT$(s$, q + 1)
          RETURN first_expr$
        END IF
      END IF
      q = q + 1
    WEND
    first_expr$ = s$
    RETURN first_expr$
  END IF
  p = INSTR(s$, "(")
  IF p = 0 THEN
    first_expr$ = s$
    RETURN first_expr$
  END IF
  depth = 1
  p = p + 1
  inQuote = 0
  WHILE p <= LEN(s$) AND depth > 0
    ch = ASC(MID$(s$, p, 1))
    IF ch = 34 THEN
      inQuote = 1 - inQuote
    ELSEIF inQuote = 0 THEN
      IF ch = 40 THEN
        depth = depth + 1
      ELSEIF ch = 41 THEN
        depth = depth - 1
      END IF
    END IF
    p = p + 1
  WEND
  first_expr$ = LEFT$(s$, p - 1)
END FUNCTION

FUNCTION after_first$(s$)
  DIM fe$
  DIM p
  fe$ = first_expr$(s$)
  p = LEN(fe$) + 1
  IF p <= LEN(s$) AND ASC(MID$(s$, p, 1)) = 32 THEN
    p = p + 1
  END IF
  after_first$ = MID$(s$, p, LEN(s$) - p + 1)
END FUNCTION

FUNCTION trim_spaces$(s$)
  DIM i
  DIM j
  i = 1
  WHILE i <= LEN(s$)
    IF ASC(MID$(s$, i, 1)) = 32 THEN
      i = i + 1
    ELSE
      EXIT WHILE
    END IF
  WEND
  j = LEN(s$)
  WHILE j >= i
    IF ASC(MID$(s$, j, 1)) = 32 THEN
      j = j - 1
    ELSE
      EXIT WHILE
    END IF
  WEND
  IF j < i THEN
    trim_spaces$ = ""
  ELSE
    trim_spaces$ = MID$(s$, i, j - i + 1)
  END IF
END FUNCTION

FUNCTION emit_expr$(e$)
  DIM t$
  DIM rest$
  DIM colonPos
  DIM varName$
  DIM varType$
  DIM left$
  DIM r$
  DIM op$
  DIM sp
  DIM right$
  DIM fn$
  DIM args$
  DIM parenPos
  DIM br

  IF LEFT$(e$, 7) = "string(" THEN
    t$ = MID$(e$, 9, LEN(e$) - 10)
    emit_expr$ = "xb_str(" + CHR$(34) + t$ + CHR$(34) + ")"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 8) = "integer(" THEN
    t$ = MID$(e$, 9, LEN(e$) - 9)
    emit_expr$ = t$
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 6) = "float(" THEN
    t$ = MID$(e$, 7, LEN(e$) - 7)
    emit_expr$ = t$
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 7) = "symbol(" THEN
    t$ = MID$(e$, 8, LEN(e$) - 7)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    colonPos = INSTR(t$, ":")
    IF colonPos > 0 THEN
      varName$ = LEFT$(t$, colonPos - 1)
      varType$ = MID$(t$, colonPos + 1, LEN(t$) - colonPos)
    ELSE
      varName$ = t$
      varType$ = "integer"
    END IF
    emit_expr$ = c_var_name$(varName$, varType$)
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 8) = "compare(" THEN
    rest$ = MID$(e$, 9, LEN(e$) - 8)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    r$ = after_first$(rest$)
    sp = INSTR(r$, " ")
    IF sp > 0 THEN
      op$ = LEFT$(r$, sp - 1)
      right$ = MID$(r$, sp + 1, LEN(r$) - sp)
    ELSE
      op$ = r$
      right$ = ""
    END IF
    IF expr_type$(left$) = "string" OR expr_type$(right$) = "string" THEN
      emit_expr$ = "(strcmp(" + emit_expr$(left$) + ", " + emit_expr$(right$) + ") " + c_cmp_op$(op$) + " 0)"
    ELSE
      emit_expr$ = "(" + emit_expr$(left$) + " " + c_cmp_op$(op$) + " " + emit_expr$(right$) + ")"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 6) = "arith(" THEN
    rest$ = MID$(e$, 7, LEN(e$) - 6)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    r$ = after_first$(rest$)
    sp = INSTR(r$, " ")
    IF sp > 0 THEN
      op$ = LEFT$(r$, sp - 1)
      right$ = MID$(r$, sp + 1, LEN(r$) - sp)
    ELSE
      op$ = r$
      right$ = ""
    END IF
    IF op$ = "+" AND (expr_type$(left$) = "string" OR expr_type$(right$) = "string") THEN
      emit_expr$ = "xb_concat(" + emit_expr$(left$) + ", " + emit_expr$(right$) + ")"
    ELSEIF op$ = "mod" THEN
      emit_expr$ = "(" + emit_expr$(left$) + " % " + emit_expr$(right$) + ")"
    ELSEIF op$ = "**" THEN
      emit_expr$ = "pow(" + emit_expr$(left$) + ", " + emit_expr$(right$) + ")"
    ELSEIF op$ = "\" THEN
      emit_expr$ = "(" + emit_expr$(left$) + " / " + emit_expr$(right$) + ")"
    ELSE
      emit_expr$ = "(" + emit_expr$(left$) + " " + op$ + " " + emit_expr$(right$) + ")"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "not(" THEN
    t$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    emit_expr$ = "(~" + emit_expr$(t$) + ")"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "and(" THEN
    rest$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "((" + emit_expr$(left$) + ") & (" + emit_expr$(right$) + "))"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 3) = "or(" THEN
    rest$ = MID$(e$, 4, LEN(e$) - 3)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "((" + emit_expr$(left$) + ") | (" + emit_expr$(right$) + "))"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 5) = "call " THEN
    rest$ = MID$(e$, 6, LEN(e$) - 5)
    parenPos = INSTR(rest$, "(")
    IF parenPos > 0 THEN
      fn$ = LEFT$(rest$, parenPos - 1)
      IF LEN(rest$) > parenPos THEN
        args$ = MID$(rest$, parenPos + 1, LEN(rest$) - parenPos - 1)
      ELSE
        args$ = ""
      END IF
    ELSE
      fn$ = rest$
      args$ = ""
    END IF
    emit_expr$ = c_func_name$(fn$) + "(" + emit_args$(args$) + ")"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 13) = "array_access(" THEN
    t$ = MID$(e$, 14, LEN(e$) - 13)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    br = INSTR(t$, "[")
    IF br > 0 THEN
      varName$ = LEFT$(t$, br - 1)
      colonPos = INSTR(varName$, ":")
      IF colonPos > 0 THEN
        varType$ = MID$(varName$, colonPos + 1, LEN(varName$) - colonPos)
        varName$ = LEFT$(varName$, colonPos - 1)
      ELSE
        varType$ = "integer"
      END IF
      t$ = MID$(t$, br + 1, LEN(t$) - br)
      IF RIGHT$(t$, 1) = "]" THEN
        t$ = LEFT$(t$, LEN(t$) - 1)
      END IF
      emit_expr$ = c_var_name$(varName$, varType$) + "[" + emit_expr$(t$) + "]"
    ELSE
      emit_expr$ = "0"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 9) = "constant(" THEN
    rest$ = MID$(e$, 10, LEN(e$) - 9)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    sp = INSTR(rest$, " = ")
    IF sp > 0 THEN
      emit_expr$ = emit_expr$(MID$(rest$, sp + 3, LEN(rest$) - sp - 2))
    ELSE
      emit_expr$ = "0"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 7) = "shared(" THEN
    t$ = MID$(e$, 8, LEN(e$) - 7)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    sp = INSTR(t$, "##")
    IF sp > 0 THEN
      t$ = MID$(t$, sp + 2, LEN(t$) - sp - 1)
    END IF
    colonPos = INSTR(t$, ":")
    IF colonPos > 0 THEN
      varName$ = LEFT$(t$, colonPos - 1)
    ELSE
      varName$ = t$
    END IF
    emit_expr$ = "xb_shared_" + varName$
    RETURN emit_expr$
  END IF

  emit_expr$ = "0"
END FUNCTION

FUNCTION emit_args$(a$)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM parts$
  DIM arg$

  IF LEN(a$) = 0 THEN
    emit_args$ = ""
    RETURN emit_args$
  END IF

  parts$ = ""
  i = 1
  start = 1
  depth = 0
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 THEN
      arg$ = MID$(a$, start, i - start)
      arg$ = trim_spaces$(arg$)
      IF LEN(parts$) > 0 THEN
        parts$ = parts$ + ", "
      END IF
      parts$ = parts$ + emit_expr$(arg$)
      start = i + 1
    END IF
    i = i + 1
  WEND

  IF start <= LEN(a$) THEN
    arg$ = MID$(a$, start, LEN(a$) - start + 1)
    arg$ = trim_spaces$(arg$)
    IF LEN(parts$) > 0 THEN
      parts$ = parts$ + ", "
    END IF
    parts$ = parts$ + emit_expr$(arg$)
  END IF

  emit_args$ = parts$
END FUNCTION

FUNCTION emit_params$(params$)
  DIM result$
  DIM rest$
  DIM commaPos
  DIM param$
  DIM colonPos
  DIM pName$
  DIM pType$

  result$ = ""
  rest$ = params$
  WHILE LEN(rest$) > 0
    commaPos = INSTR(rest$, ",")
    IF commaPos = 0 THEN
      param$ = rest$
      rest$ = ""
    ELSE
      param$ = LEFT$(rest$, commaPos - 1)
      rest$ = MID$(rest$, commaPos + 1, LEN(rest$) - commaPos)
      IF LEN(rest$) > 0 AND ASC(MID$(rest$, 1, 1)) = 32 THEN
        rest$ = MID$(rest$, 2, LEN(rest$) - 1)
      END IF
    END IF
    param$ = trim_spaces$(param$)
    IF LEN(param$) > 0 THEN
      colonPos = INSTR(param$, ":")
      IF colonPos > 0 THEN
        pName$ = LEFT$(param$, colonPos - 1)
        pType$ = MID$(param$, colonPos + 1, LEN(param$) - colonPos)
      ELSE
        pName$ = param$
        pType$ = "integer"
      END IF
      IF LEN(result$) > 0 THEN
        result$ = result$ + ", "
      END IF
      result$ = result$ + c_type$(pType$) + " " + c_var_name$(pName$, pType$)
    END IF
  WEND
  emit_params$ = result$
END FUNCTION

FUNCTION emit_stmt$(s$)
  DIM rest$
  DIM spacePos
  DIM varName$
  DIM varType$
  DIM colonPos
  DIM bracketPos
  DIM arrSize$
  DIM cExpr$
  DIM c2$
  DIM etype$
  DIM tmp$
  DIM right$
  DIM start$
  DIM end$
  DIM fn$
  DIM args$
  DIM parenPos
  DIM pName$
  DIM afterTo$
  DIM stepPos
  DIM stepVal$
  DIM cStep$
  DIM negStep
  DIM cmpOp$
  DIM pType$
  DIM hashPos
  DIM eqPos
  DIM expr$

  IF LEFT$(s$, 8) = "function" THEN
    emit_stmt$ = ""
    RETURN emit_stmt$
  END IF

  IF s$ = "end function" THEN
    emit_stmt$ = "}"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 7) = "version" THEN
    emit_stmt$ = ""
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "const" THEN
    emit_stmt$ = ""
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 7) = "shared " THEN
    rest$ = MID$(s$, 8, LEN(s$) - 7)
    hashPos = INSTR(rest$, "#")
    IF hashPos > 0 THEN
      rest$ = MID$(rest$, hashPos + 2, LEN(rest$) - hashPos - 1)
    END IF
    colonPos = INSTR(rest$, ":")
    IF colonPos > 0 THEN
      varName$ = LEFT$(rest$, colonPos - 1)
      eqPos = INSTR(rest$, "= ")
      IF eqPos > 0 THEN
        expr$ = MID$(rest$, eqPos + 2, LEN(rest$) - eqPos - 1)
        emit_stmt$ = "    xb_shared_" + varName$ + " = " + emit_expr$(expr$) + ";"
        RETURN emit_stmt$
      END IF
    END IF
    emit_stmt$ = ""
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 3) = "dim" THEN
    rest$ = MID$(s$, 5, LEN(s$) - 4)
    bracketPos = INSTR(rest$, "[")
    IF bracketPos > 0 THEN
      varName$ = LEFT$(rest$, bracketPos - 1)
      arrSize$ = MID$(rest$, bracketPos + 1, LEN(rest$) - bracketPos - 1)
      colonPos = INSTR(varName$, ":")
      IF colonPos > 0 THEN
        varType$ = MID$(varName$, colonPos + 1, LEN(varName$) - colonPos)
        varName$ = LEFT$(varName$, colonPos - 1)
      ELSE
        varType$ = "integer"
      END IF
      cExpr$ = emit_expr$(arrSize$)
      IF varType$ = "string" THEN
        emit_stmt$ = "    char* " + c_var_name$(varName$, varType$) + "[" + cExpr$ + "];" + CHR$(10) + "    for (int _i = 0; _i < " + cExpr$ + "; _i++) " + c_var_name$(varName$, varType$) + "[_i] = xb_strdup(" + CHR$(34) + CHR$(34) + ");"
      ELSE
        emit_stmt$ = "    int " + c_var_name$(varName$, varType$) + "[" + cExpr$ + "];"
      END IF
    ELSE
      colonPos = INSTR(rest$, ":")
      IF colonPos > 0 THEN
        varName$ = LEFT$(rest$, colonPos - 1)
        varType$ = MID$(rest$, colonPos + 1, LEN(rest$) - colonPos)
      ELSE
        varName$ = rest$
        varType$ = "integer"
      END IF
      IF varType$ = "string" THEN
        emit_stmt$ = "    char* " + c_var_name$(varName$, varType$) + " = xb_strdup(" + CHR$(34) + CHR$(34) + ");"
      ELSEIF varType$ = "float" THEN
        emit_stmt$ = "    double " + c_var_name$(varName$, varType$) + " = 0.0;"
      ELSE
        emit_stmt$ = "    int " + c_var_name$(varName$, varType$) + " = 0;"
      END IF
    END IF
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 12) = "array_assign" THEN
    rest$ = MID$(s$, 14, LEN(s$) - 13)
    bracketPos = INSTR(rest$, "[")
    varName$ = LEFT$(rest$, bracketPos - 1)
    colonPos = INSTR(varName$, ":")
    IF colonPos > 0 THEN
      varType$ = MID$(varName$, colonPos + 1, LEN(varName$) - colonPos)
      varName$ = LEFT$(varName$, colonPos - 1)
    ELSE
      varType$ = "integer"
    END IF
    tmp$ = MID$(rest$, bracketPos + 1, LEN(rest$) - bracketPos)
    bracketPos = INSTR(tmp$, "]")
    cExpr$ = LEFT$(tmp$, bracketPos - 1)
    spacePos = INSTR(tmp$, "= ")
    right$ = MID$(tmp$, spacePos + 2, LEN(tmp$) - spacePos - 1)
    c2$ = emit_expr$(right$)
    emit_stmt$ = "    " + c_var_name$(varName$, varType$) + "[" + emit_expr$(cExpr$) + "] = " + c2$ + ";"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 6) = "assign" THEN
    rest$ = MID$(s$, 8, LEN(s$) - 7)
    spacePos = INSTR(rest$, " = ")
    varName$ = LEFT$(rest$, spacePos - 1)
    rest$ = MID$(rest$, spacePos + 3, LEN(rest$) - spacePos - 2)
    colonPos = INSTR(varName$, ":")
    IF colonPos > 0 THEN
      varType$ = MID$(varName$, colonPos + 1, LEN(varName$) - colonPos)
      varName$ = LEFT$(varName$, colonPos - 1)
    ELSE
      varType$ = "integer"
    END IF
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    " + c_var_name$(varName$, varType$) + " = " + cExpr$ + ";"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "print" THEN
    rest$ = MID$(s$, 7, LEN(s$) - 6)
    cExpr$ = emit_expr$(rest$)
    etype$ = expr_type$(rest$)
    IF etype$ = "string" THEN
      emit_stmt$ = "    xb_print_str(" + cExpr$ + ");"
    ELSEIF etype$ = "float" THEN
      emit_stmt$ = "    xb_print_float(" + cExpr$ + ");"
    ELSE
      emit_stmt$ = "    xb_print_int(" + cExpr$ + ");"
    END IF
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 3) = "if " THEN
    rest$ = MID$(s$, 4, LEN(s$) - 3)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    if (" + cExpr$ + ") {"
    RETURN emit_stmt$
  END IF

  IF s$ = "else" THEN
    emit_stmt$ = "    } else {"
    RETURN emit_stmt$
  END IF

  IF s$ = "end if" THEN
    emit_stmt$ = "    }"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 6) = "while " THEN
    rest$ = MID$(s$, 7, LEN(s$) - 6)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    while (" + cExpr$ + ") {"
    RETURN emit_stmt$
  END IF

  IF s$ = "wend" THEN
    emit_stmt$ = "    }"
    RETURN emit_stmt$
  END IF
  IF s$ = "do" THEN
    emit_stmt$ = "    do {"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 9) = "do while " THEN
    rest$ = MID$(s$, 10, LEN(s$) - 9)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    while (" + cExpr$ + ") {"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 9) = "do until " THEN
    rest$ = MID$(s$, 10, LEN(s$) - 9)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    while (!(" + cExpr$ + ")) {"
    RETURN emit_stmt$
  END IF

  IF s$ = "loop" THEN
    emit_stmt$ = "    }"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 11) = "loop while " THEN
    rest$ = MID$(s$, 12, LEN(s$) - 11)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    } while (" + cExpr$ + ");"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 11) = "loop until " THEN
    rest$ = MID$(s$, 12, LEN(s$) - 11)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    } while (!(" + cExpr$ + "));"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 4) = "for " THEN
    rest$ = MID$(s$, 5, LEN(s$) - 4)
    spacePos = INSTR(rest$, " = ")
    varName$ = LEFT$(rest$, spacePos - 1)
    colonPos = INSTR(varName$, ":")
    IF colonPos > 0 THEN
      varType$ = MID$(varName$, colonPos + 1, LEN(varName$) - colonPos)
      varName$ = LEFT$(varName$, colonPos - 1)
    ELSE
      varType$ = "integer"
    END IF
    rest$ = MID$(rest$, spacePos + 3, LEN(rest$) - spacePos - 2)
    spacePos = INSTR(rest$, " to ")
    start$ = LEFT$(rest$, spacePos - 1)
    afterTo$ = MID$(rest$, spacePos + 4, LEN(rest$) - spacePos - 3)
    stepPos = INSTR(afterTo$, " step ")
    IF stepPos > 0 THEN
      end$ = LEFT$(afterTo$, stepPos - 1)
      stepVal$ = MID$(afterTo$, stepPos + 6, LEN(afterTo$) - stepPos - 5)
      cExpr$ = emit_expr$(start$)
      c2$ = emit_expr$(end$)
      cStep$ = emit_expr$(stepVal$)
      negStep = 0
      IF LEFT$(stepVal$, 1) = "-" THEN
        negStep = 1
      END IF
      cmpOp$ = " <= "
      IF negStep THEN
        cmpOp$ = " >= "
      END IF
      emit_stmt$ = "    for (" + c_var_name$(varName$, varType$) + " = " + cExpr$ + "; " + c_var_name$(varName$, varType$) + cmpOp$ + c2$ + "; " + c_var_name$(varName$, varType$) + " += " + cStep$ + ") {"
    ELSE
      end$ = afterTo$
      cExpr$ = emit_expr$(start$)
      c2$ = emit_expr$(end$)
      emit_stmt$ = "    for (" + c_var_name$(varName$, varType$) + " = " + cExpr$ + "; " + c_var_name$(varName$, varType$) + " <= " + c2$ + "; " + c_var_name$(varName$, varType$) + "++) {"
    END IF
    RETURN emit_stmt$
  END IF

  IF s$ = "next" THEN
    emit_stmt$ = "    }"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 7) = "return " THEN
    rest$ = MID$(s$, 8, LEN(s$) - 7)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    return " + cExpr$ + ";"
    RETURN emit_stmt$
  END IF

  IF s$ = "return" THEN
    emit_stmt$ = "    return 0;"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "call " THEN
    rest$ = MID$(s$, 6, LEN(s$) - 5)
    parenPos = INSTR(rest$, "(")
    IF parenPos > 0 THEN
      fn$ = LEFT$(rest$, parenPos - 1)
      IF LEN(rest$) > parenPos THEN
        args$ = MID$(rest$, parenPos + 1, LEN(rest$) - parenPos - 1)
      ELSE
        args$ = ""
      END IF
    ELSE
      fn$ = rest$
      args$ = ""
    END IF
    emit_stmt$ = "    xb_user_" + fn$ + "(" + emit_args$(args$) + ");"
    RETURN emit_stmt$
  END IF

  IF s$ = "exit_loop" THEN
    emit_stmt$ = "    break;"
    RETURN emit_stmt$
  END IF

  emit_stmt$ = ""
END FUNCTION
