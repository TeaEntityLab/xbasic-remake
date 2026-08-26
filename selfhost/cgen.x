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
DIM shRefPos
DIM shNameStart
DIM shColonP
DIM shCloseP
DIM shRefName$
DIM shRefType$
DIM shPat$
DIM shRP$
DIM funcBody$
DIM fwdDeclsBuf$
DIM usedSyms$
DIM dimmedSyms$
DIM fullBody$
DIM hoists$
DIM firstFunc$
DIM firstParams$
DIM emittedFuncs$
DIM skipFunc
DIM nestBlocks$
DIM inNest
DIM nfName$
DIM nfAfter$
DIM nfClose
DIM _mdSemi

src$ = ""
WHILE EOF() = 0
  line$ = READLINE$()
  IF EOF() = 0 THEN
    src$ = src$ + line$ + CHR$(10)
  ELSE
    src$ = src$ + line$
  END IF
WEND
DIM verStr$
verStr$ = ""
DIM vLine$
DIM vPos
vPos = 0
IF LEFT$(src$, 8) = "version " THEN
  vPos = 9
END IF
IF vPos = 0 THEN
  vPos = INSTR(src$, CHR$(10) + "version ")
  IF vPos > 0 THEN
    vPos = vPos + 9
  END IF
END IF
IF vPos > 0 THEN
  DIM vEnd
  vEnd = INSTR(src$, CHR$(10), vPos)
  IF vEnd = 0 THEN
    vEnd = LEN(src$) + 1
  END IF
  vLine$ = MID$(src$, vPos, vEnd - vPos)
  IF LEFT$(vLine$, 1) = CHR$(34) AND RIGHT$(vLine$, 1) = CHR$(34) THEN
    vLine$ = MID$(vLine$, 2, LEN(vLine$) - 2)
  END IF
  verStr$ = vLine$
END IF
PRINT "static const char* xb_version_str = " + CHR$(34) + verStr$ + CHR$(34) + ";"
DIM progStr$
progStr$ = ""
DIM pPos
pPos = 0
IF LEFT$(src$, 13) = "program_name " THEN
  pPos = 14
END IF
IF pPos = 0 THEN
  pPos = INSTR(src$, CHR$(10) + "program_name ")
  IF pPos > 0 THEN
    pPos = pPos + 14
  END IF
END IF
IF pPos > 0 THEN
  DIM pEnd
  pEnd = INSTR(src$, CHR$(10), pPos)
  IF pEnd = 0 THEN
    pEnd = LEN(src$) + 1
  END IF
  DIM pLine$
  pLine$ = MID$(src$, pPos, pEnd - pPos)
  IF LEFT$(pLine$, 1) = CHR$(34) AND RIGHT$(pLine$, 1) = CHR$(34) THEN
    pLine$ = MID$(pLine$, 2, LEN(pLine$) - 2)
  END IF
  progStr$ = pLine$
END IF
PRINT "static const char* xb_program_name_str = " + CHR$(34) + progStr$ + CHR$(34) + ";"

PRINT "#include <stdio.h>"
PRINT "#include <stdlib.h>"
PRINT "#include <string.h>"
PRINT "#include <math.h>"
PRINT "#include <ctype.h>"
PRINT "#include <time.h>"
PRINT "#include <stdint.h>"
PRINT "#ifndef _WIN32"
PRINT "#include <fcntl.h>"
PRINT "#include <unistd.h>"
PRINT "#endif"
PRINT "static char* xb_alloc(size_t n) { char* p = (char*)malloc(sizeof(size_t) + n + 1); *(size_t*)p = n; char* d = p + sizeof(size_t); d[n] = 0; return d; }"
PRINT "static int xb_len(const char* s) { if (!s) return 0; return (int)*((size_t*)s - 1); }"
PRINT "static char* xb_from_cstr(const char* s) { size_t n = strlen(s); char* d = xb_alloc(n); memcpy(d, s, n); return d; }"
PRINT "static char* xb_strdup(const char* s) { int n = xb_len(s); char* d = xb_alloc((size_t)n); memcpy(d, s, (size_t)n); return d; }"
PRINT "static char* xb_str(const char* s) { return xb_from_cstr(s); }"
PRINT "static char* xb_concat(const char* a, const char* b) {"
PRINT "    int la = xb_len(a), lb = xb_len(b);"
PRINT "    char* r = xb_alloc((size_t)(la + lb));"
PRINT "    memcpy(r, a, (size_t)la);"
PRINT "    memcpy(r + la, b, (size_t)lb);"
PRINT "    return r;"
PRINT "}"
PRINT "static int xb_asc(const char* s) { return (unsigned char)s[0]; }"
PRINT "static char* xb_chr(int c, int count) { if (count < 1) count = 1; char* r = xb_alloc((size_t)count); for (int i = 0; i < count; i++) r[i] = (char)c; return r; }"
PRINT "static int xb_scmp(const char* a, const char* b) { int la = xb_len(a), lb = xb_len(b); int m = la < lb ? la : lb; int r = memcmp(a, b, (size_t)m); if (r) return r; return (la > lb) - (la < lb); }"
PRINT "static char* xb_left(const char* s, int n) {"
PRINT "    int len = xb_len(s);"
PRINT "    if (n < 0) n = 0;"
PRINT "    if (n > len) n = len;"
PRINT "    char* r = xb_alloc((size_t)n);"
PRINT "    memcpy(r, s, (size_t)n);"
PRINT "    return r;"
PRINT "}"
PRINT "static char* xb_right(const char* s, int n) {"
PRINT "    int len = xb_len(s);"
PRINT "    if (n < 0) n = 0;"
PRINT "    if (n > len) n = len;"
PRINT "    char* r = xb_alloc((size_t)n);"
PRINT "    memcpy(r, s + len - n, (size_t)n);"
PRINT "    return r;"
PRINT "}"
PRINT "static char* xb_mid(const char* s, int start, int len) {"
PRINT "    int slen = xb_len(s);"
PRINT "    if (start < 1) start = 1;"
PRINT "    int off = start - 1;"
PRINT "    if (off >= slen) return xb_str(" + CHR$(34) + "" + CHR$(34) + ");"
PRINT "    if (len < 0) len = slen - off;"
PRINT "    if (off + len > slen) len = slen - off;"
PRINT "    char* r = xb_alloc((size_t)len);"
PRINT "    memcpy(r, s + off, (size_t)len);"
PRINT "    return r;"
PRINT "}"
PRINT "static int xb_instr2(const char* s, const char* sub) {"
PRINT "    const char* p = strstr(s, sub);"
PRINT "    return p ? (int)(p - s) + 1 : 0;"
PRINT "}"
PRINT "static int xb_instr3(const char* s, const char* sub, int start) {"
PRINT "    if (start < 1) start = 1;"
PRINT "    const char* base = s + start - 1;"
PRINT "    const char* p = strstr(base, sub);"
PRINT "    return p ? (int)(p - s) + 1 : 0;"
PRINT "}"
PRINT "static int xb_rinstr2(const char* s, const char* sub) {"
PRINT "    int slen = strlen(s), sublen = strlen(sub);"
PRINT "    if (sublen == 0 || sublen > slen) return 0;"
PRINT "    for (int i = slen - sublen; i >= 0; i--)"
PRINT "        if (strncmp(s + i, sub, sublen) == 0) return i + 1;"
PRINT "    return 0;"
PRINT "}"
PRINT "static int xb_rinstr3(const char* s, const char* sub, int end) {"
PRINT "    int slen = strlen(s), sublen = strlen(sub);"
PRINT "    if (sublen == 0) return 0;"
PRINT "    if (end > slen) end = slen;"
PRINT "    for (int i = end - sublen; i >= 0; i--)"
PRINT "        if (strncmp(s + i, sub, sublen) == 0) return i + 1;"
PRINT "    return 0;"
PRINT "}"
PRINT "static int xb_instri2(const char* s, const char* sub) {"
PRINT "    int slen = strlen(s), sublen = strlen(sub);"
PRINT "    if (sublen == 0 || sublen > slen) return 0;"
PRINT "    for (int i = 0; i <= slen - sublen; i++)"
PRINT "        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;"
PRINT "    return 0;"
PRINT "}"
PRINT "static int xb_instri3(const char* s, const char* sub, int start) {"
PRINT "    int slen = strlen(s), sublen = strlen(sub);"
PRINT "    if (start < 1) start = 1;"
PRINT "    if (sublen == 0) return 0;"
PRINT "    for (int i = start - 1; i <= slen - sublen; i++)"
PRINT "        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;"
PRINT "    return 0;"
PRINT "}"
PRINT "static int xb_rinstri2(const char* s, const char* sub) {"
PRINT "    int slen = strlen(s), sublen = strlen(sub);"
PRINT "    if (sublen == 0 || sublen > slen) return 0;"
PRINT "    for (int i = slen - sublen; i >= 0; i--)"
PRINT "        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;"
PRINT "    return 0;"
PRINT "}"
PRINT "static int xb_rinstri3(const char* s, const char* sub, int end) {"
PRINT "    int slen = strlen(s), sublen = strlen(sub);"
PRINT "    if (sublen == 0) return 0;"
PRINT "    if (end > slen) end = slen;"
PRINT "    for (int i = end - sublen; i >= 0; i--)"
PRINT "        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;"
PRINT "    return 0;"
PRINT "}"
PRINT "static int xb_val(const char* s) { return atoi(s); }"
PRINT "static char* xb_str_num(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%d" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_str_giant(int64_t v) { char buf[24]; snprintf(buf, 24, " + CHR$(34) + "%lld" + CHR$(34) + ", (long long)v); return xb_from_cstr(buf); }"
PRINT "static void xb_fmt_float(double v, char* out, int outn) {"
PRINT "    if (v != v) { snprintf(out, (size_t)outn, " + CHR$(34) + "NaN" + CHR$(34) + "); return; }"
PRINT "    if (v == (1.0/0.0)) { snprintf(out, (size_t)outn, " + CHR$(34) + "inf" + CHR$(34) + "); return; }"
PRINT "    if (v == -(1.0/0.0)) { snprintf(out, (size_t)outn, " + CHR$(34) + "-inf" + CHR$(34) + "); return; }"
PRINT "    if (v == 0.0) { snprintf(out, (size_t)outn, signbit(v) ? " + CHR$(34) + "-0" + CHR$(34) + " : " + CHR$(34) + "0" + CHR$(34) + "); return; }"
PRINT "    char hi[80]; snprintf(hi, sizeof hi, " + CHR$(34) + "%.40e" + CHR$(34) + ", v);"
PRINT "    const char* s = hi; int neg = 0;"
PRINT "    if (*s == '-') { neg = 1; s++; }"
PRINT "    char md[48]; int nmd = 0;"
PRINT "    md[nmd++] = *s++;"
PRINT "    if (*s == '.') { s++; while (*s && *s != 'e' && *s != 'E') md[nmd++] = *s++; }"
PRINT "    int hexp = (*s == 'e' || *s == 'E') ? atoi(s + 1) : 0;"
PRINT "    char best[48]; int bestn = 0, bestexp = 0;"
PRINT "    for (int p = 1; p <= 17; p++) {"
PRINT "        char r[48]; int rn = p, rexp = hexp;"
PRINT "        for (int i = 0; i < p; i++) r[i] = md[i];"
PRINT "        if (p < nmd && md[p] >= '5') {"
PRINT "            int i = p - 1;"
PRINT "            for (; i >= 0; i--) { if (r[i] < '9') { r[i]++; break; } r[i] = '0'; }"
PRINT "            if (i < 0) { memmove(r + 1, r, (size_t)p); r[0] = '1'; rexp++; }"
PRINT "        }"
PRINT "        while (rn > 1 && r[rn - 1] == '0') rn--;"
PRINT "        char cand[72]; int ci = 0; cand[ci++] = r[0];"
PRINT "        if (rn > 1) { cand[ci++] = '.'; for (int i = 1; i < rn; i++) cand[ci++] = r[i]; }"
PRINT "        snprintf(cand + ci, (size_t)((int)sizeof cand - ci), " + CHR$(34) + "e%d" + CHR$(34) + ", rexp);"
PRINT "        double rt = strtod(cand, 0); if (neg) rt = -rt;"
PRINT "        memcpy(best, r, (size_t)rn); bestn = rn; bestexp = rexp;"
PRINT "        if (rt == v) break;"
PRINT "    }"
PRINT "    int point = bestexp + 1; char* o = out; if (neg) *o++ = '-';"
PRINT "    if (point <= 0) { *o++ = '0'; *o++ = '.'; for (int i = 0; i < -point; i++) *o++ = '0'; for (int i = 0; i < bestn; i++) *o++ = best[i]; }"
PRINT "    else if (point >= bestn) { for (int i = 0; i < bestn; i++) *o++ = best[i]; for (int i = 0; i < point - bestn; i++) *o++ = '0'; }"
PRINT "    else { for (int i = 0; i < point; i++) *o++ = best[i]; *o++ = '.'; for (int i = point; i < bestn; i++) *o++ = best[i]; }"
PRINT "    *o = 0;"
PRINT "}"
PRINT "static char* xb_str_float(double v) { char buf[400]; xb_fmt_float(v, buf, 400); return xb_from_cstr(buf); }"
PRINT "static int xb_eof(void) {"
PRINT "    int c = fgetc(stdin);"
PRINT "    if (c == EOF) return 1;"
PRINT "    ungetc(c, stdin);"
PRINT "    return 0;"
PRINT "}"
PRINT "static char* xb_readline(void) {"
PRINT "    char buf[65536];"
PRINT "    if (!fgets(buf, sizeof(buf), stdin)) return xb_str(" + CHR$(34) + "" + CHR$(34) + ");"
PRINT "    int len = (int)strlen(buf);"
PRINT "    if (len > 0 && buf[len-1] == '" + CHR$(92) + "n') buf[len-1] = 0;"
PRINT "    return xb_from_cstr(buf);"
PRINT "}"
PRINT "static void xb_print_int(int v) { printf(" + CHR$(34) + "%d" + CHR$(92) + "n" + CHR$(34) + ", v); }"
PRINT "static void xb_print_giant(int64_t v) { printf(" + CHR$(34) + "%lld" + CHR$(92) + "n" + CHR$(34) + ", (long long)v); }"
PRINT "static void xb_print_str(const char* s) { fwrite(s, 1, (size_t)xb_len(s), stdout); putchar('" + CHR$(92) + "n'); }"
PRINT "static void xb_print_float(double v) { char buf[400]; xb_fmt_float(v, buf, 400); printf(" + CHR$(34) + "%s" + CHR$(92) + "n" + CHR$(34) + ", buf); }"
PRINT "static char* xb_ucase(const char* s) { char* r = xb_strdup(s); int n = xb_len(r); for (int i = 0; i < n; i++) r[i] = (char)toupper((unsigned char)r[i]); return r; }"
PRINT "static char* xb_lcase(const char* s) { char* r = xb_strdup(s); int n = xb_len(r); for (int i = 0; i < n; i++) r[i] = (char)tolower((unsigned char)r[i]); return r; }"
PRINT "static char* xb_trim(const char* s) { int n = xb_len(s); int a = 0; while (a < n && (s[a] == ' ' || s[a] == '" + CHR$(92) + "t')) a++; int b = n; while (b > a && (s[b-1] == ' ' || s[b-1] == '" + CHR$(92) + "t')) b--; int len = b - a; char* r = xb_alloc((size_t)len); memcpy(r, s + a, (size_t)len); return r; }"
PRINT "static char* xb_ltrim(const char* s) { int n = xb_len(s); int a = 0; while (a < n && (s[a] == ' ' || s[a] == '" + CHR$(92) + "t')) a++; int len = n - a; char* r = xb_alloc((size_t)len); memcpy(r, s + a, (size_t)len); return r; }"
PRINT "static char* xb_rtrim(const char* s) { int n = xb_len(s); while (n > 0 && (s[n-1] == ' ' || s[n-1] == '" + CHR$(92) + "t')) n--; char* r = xb_alloc((size_t)n); memcpy(r, s, (size_t)n); return r; }"
PRINT "static char* xb_space(int n) { if (n < 0) n = 0; char* r = xb_alloc((size_t)n); memset(r, ' ', (size_t)n); return r; }"
PRINT "static int xb_abs(int v) { return v < 0 ? -v : v; }"
PRINT "static double xb_fabs(double v) { return fabs(v); }"
PRINT "static int xb_sgn(int v) { return (v > 0) - (v < 0); }"
PRINT "static int xb_int(double v) { return (int)floor(v); }"
PRINT "static int xb_fix(double v) { return (int)trunc(v); }"
PRINT "static int xb_max(int a, int b) { return a > b ? a : b; }"
PRINT "static int xb_min(int a, int b) { return a < b ? a : b; }"
PRINT "static int xb_rotatel(unsigned int v, unsigned int n) { n %= 32; return (v << n) | (v >> ((32 - n) % 32)); }"
PRINT "static int xb_rotater(unsigned int v, unsigned int n) { n %= 32; return (v >> n) | (v << ((32 - n) % 32)); }"
PRINT "static int xb_dhigh(double v) { uint64_t b; memcpy(&b, &v, 8); return (int)(b >> 32); }"
PRINT "static int xb_dlow(double v) { uint64_t b; memcpy(&b, &v, 8); return (int)(b & 0xFFFFFFFF); }"
PRINT "static double xb_dmake(int hi, int lo) { uint64_t b = ((uint64_t)(unsigned)hi << 32) | (unsigned)lo; double v; memcpy(&v, &b, 8); return v; }"
PRINT "static int64_t xb_gmake(int hi, int lo) { return (int64_t)(((uint64_t)(unsigned)hi << 32) | (unsigned)lo); }"
PRINT "static double xb_smake(int v) { float f; uint32_t b = (unsigned)v; memcpy(&f, &b, 4); return (double)f; }"
PRINT "static int xb_xmake(double v) { float f = (float)v; uint32_t b; memcpy(&b, &f, 4); return (int)b; }"
PRINT "static int xb_bitfield(int w, int o) { return (w << 8) | o; }"
PRINT "static int xb_exts(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); unsigned bits = ((unsigned)v >> o) & mask; if (w<32 && (bits & (1u<<(w-1)))) bits |= ~mask; return (int)bits; }"
PRINT "static int xb_extu(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)(((unsigned)v >> o) & mask); }"
PRINT "static int xb_clr(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)((unsigned)v & ~(mask << o)); }"
PRINT "static int xb_set(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)((unsigned)v | (mask << o)); }"
PRINT "static int xb_make(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)(((unsigned)v & mask) << o); }"
PRINT "static int xb_high0(int v) { unsigned b = ~(unsigned)v; int i; for (i=31; i>=0; i--) if (b & (1u<<i)) return i; return 0; }"
PRINT "static int xb_high1(int v) { unsigned b = (unsigned)v; int i; for (i=31; i>=0; i--) if (b & (1u<<i)) return i; return 0; }"
PRINT "static int xb_ghigh(int64_t v) { return (int)(v >> 32); }"
PRINT "static int xb_glow(int64_t v) { return (int)v; }"
PRINT "static int xb_sign(double v) { return (v < 0.0) ? -1 : 1; }"
PRINT "static char* xb_binb(int v) { char buf[35]; int n = 0; if (v == 0) { buf[0] = '0'; buf[1] = 'b'; buf[2] = '0'; buf[3] = 0; return xb_from_cstr(buf); } unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } buf[0] = '0'; buf[1] = 'b'; buf[n + 2] = 0; t = (unsigned int)v; while (t) { buf[--n + 2] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_binb2(int v, int d) { char buf[35]; int n = 0; unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } if (n < d) n = d; if (v == 0 && d == 0) { buf[0] = '0'; buf[1] = 'b'; buf[2] = '0'; buf[3] = 0; return xb_from_cstr(buf); } if (v == 0) n = d; buf[0] = '0'; buf[1] = 'b'; buf[n + 2] = 0; t = (unsigned int)v; int pos = n + 1; while (pos > 1) { buf[pos--] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_octo(int v) { char buf[18]; snprintf(buf, 18, " + CHR$(34) + "0o%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_octo2(int v, int d) { char buf[20]; if (d > 0) snprintf(buf, 20, " + CHR$(34) + "0o%0*o" + CHR$(34) + ", d, v); else snprintf(buf, 20, " + CHR$(34) + "0o%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_bin2(int v, int d) { char buf[33]; int n = 0; unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } if (n < d) n = d; if (v == 0) { if (d > 0) n = d; else { buf[0] = '0'; buf[1] = 0; return xb_from_cstr(buf); } } buf[n] = 0; t = (unsigned int)v; int pos = n - 1; while (pos >= 0) { buf[pos--] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_oct2(int v, int d) { char buf[18]; if (d > 0) snprintf(buf, 18, " + CHR$(34) + "%0*o" + CHR$(34) + ", d, v); else snprintf(buf, 18, " + CHR$(34) + "%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static int xb_quit(int code) { exit(code); return 0; }"
PRINT "static char* xb_cjust(const char* s, int w) { int len = xb_len(s); if (len >= w) { char* r = xb_alloc((size_t)w); memcpy(r, s, (size_t)w); return r; } int total = w - len, left = total / 2, right = total - left; char* r = xb_alloc((size_t)w); memset(r, ' ', (size_t)left); memcpy(r + left, s, (size_t)len); memset(r + left + len, ' ', (size_t)right); return r; }"
PRINT "static char* xb_format(const char* fmt, const char* sval, int ival, double fval, int is_float, int is_str) {"
PRINT "  if (is_str) {"
PRINT "    int slen = xb_len(sval);"
PRINT "    if (fmt[0] == '&') return xb_strdup(sval);"
PRINT "    if (fmt[0] == '<' || fmt[0] == '>' || fmt[0] == '|') {"
PRINT "      int w = 0; for (int i = 0; fmt[i] == fmt[0]; i++) w++;"
PRINT "      if (slen >= w) { char* r = xb_alloc((size_t)w); memcpy(r, sval, (size_t)w); return r; }"
PRINT "      int total = w - slen, left = total / 2, right = total - left;"
PRINT "      char* r = xb_alloc((size_t)w); int pos = 0;"
PRINT "      if (fmt[0] == '>') { for (int i = 0; i < total; i++) r[pos++] = ' '; memcpy(r + pos, sval, slen); }"
PRINT "      else if (fmt[0] == '|') { for (int i = 0; i < left; i++) r[pos++] = ' '; memcpy(r + pos, sval, slen); pos += slen; for (int i = 0; i < right; i++) r[pos++] = ' '; }"
PRINT "      else { memcpy(r, sval, slen); pos += slen; for (int i = 0; i < total; i++) r[pos++] = ' '; }"
PRINT "      return r;"
PRINT "    }"
PRINT "    return xb_strdup(sval);"
PRINT "  }"
PRINT "  double val = is_float ? fval : (double)ival;"
PRINT "  int int_digits = 0, frac_digits = 0, has_decimal = 0, has_commas = 0;"
PRINT "  int dollar = 0, star_fill = 0, zero_fill = 0, leading_plus = 0, trailing_plus = 0;"
PRINT "  int trailing_minus = 0, paren_neg = 0;"
PRINT "  for (int i = 0; fmt[i]; i++) {"
PRINT "    char c = fmt[i];"
PRINT "    if (c == '#') { if (has_decimal) frac_digits++; else int_digits++; }"
PRINT "    else if (c == '.') has_decimal = 1;"
PRINT "    else if (c == ',') has_commas = 1;"
PRINT "    else if (c == '$') dollar = 1;"
PRINT "    else if (c == '*') star_fill = 1;"
PRINT "    else if (c == '0') zero_fill = 1;"
PRINT "    else if (c == '+') { if (int_digits > 0) trailing_plus = 1; else leading_plus = 1; }"
PRINT "    else if (c == '-') { if (int_digits > 0) trailing_minus = 1; }"
PRINT "    else if (c == '(') paren_neg = 1;"
PRINT "    else if (c == '_') i++;"
PRINT "  }"
PRINT "  if (int_digits == 0 && frac_digits == 0 && !star_fill && !zero_fill) { char buf[64]; snprintf(buf, 64, " + CHR$(34) + "%g" + CHR$(34) + ", val); return xb_from_cstr(buf); }"
PRINT "  int neg = val < 0.0; double abs_val = neg ? -val : val;"
PRINT "  char r[128]; r[0] = 0; int pos = 0;"
PRINT "  if (paren_neg && neg) r[pos++] = '(';"
PRINT "  else if (leading_plus) r[pos++] = neg ? '-' : '+';"
PRINT "  else if (neg && !trailing_plus && !trailing_minus) r[pos++] = '-';"
PRINT "  if (dollar) r[pos++] = '$';"
PRINT "  char numbuf[64];"
PRINT "  if (has_decimal && frac_digits > 0) snprintf(numbuf, 64, " + CHR$(34) + "%.*f" + CHR$(34) + ", frac_digits, abs_val);"
PRINT "  else snprintf(numbuf, 64, " + CHR$(34) + "%g" + CHR$(34) + ", abs_val);"
PRINT "  char* dot = strchr(numbuf, '.');"
PRINT "  int orig_int_len = dot ? (int)(dot - numbuf) : (int)strlen(numbuf);"
PRINT "  char fill = star_fill ? '*' : (zero_fill ? '0' : ' ');"
PRINT "  int commas = has_commas ? (orig_int_len - 1) / 3 : 0;"
PRINT "  int pad = int_digits > (orig_int_len + commas) ? int_digits - (orig_int_len + commas) : 0;"
PRINT "  for (int p = 0; p < pad; p++) r[pos++] = fill;"
PRINT "  if (has_commas) { for (int i = 0; i < orig_int_len; i++) { if (i > 0 && (orig_int_len - i) % 3 == 0) r[pos++] = ','; r[pos++] = numbuf[i]; } }"
PRINT "  else { memcpy(r + pos, numbuf, orig_int_len); pos += orig_int_len; }"
PRINT "  if (dot) { r[pos++] = '.'; int flen = (int)strlen(dot + 1); memcpy(r + pos, dot + 1, flen); pos += flen; }"
PRINT "  if (paren_neg && neg) r[pos++] = ')';"
PRINT "  else if (trailing_plus) r[pos++] = neg ? '-' : '+';"
PRINT "  else if (trailing_minus && neg) r[pos++] = '-';"
PRINT "  r[pos] = 0; return xb_from_cstr(r);"
PRINT "}"
PRINT "static int xb_shell(const char* cmd) { return system(cmd); }"
PRINT "static int xb_library(int n) { return 0; }"
PRINT "static char* xb_hex(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%X" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_hex2(int v, int w) { char buf[32]; if (w > 0) snprintf(buf, 32, " + CHR$(34) + "%0*X" + CHR$(34) + ", w, v); else snprintf(buf, 32, " + CHR$(34) + "%X" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_bin(int v) { char buf[33]; int n = 0; if (v == 0) { buf[0] = '0'; buf[1] = 0; return xb_from_cstr(buf); } int t = v; while (t) { n++; t >>= 1; } buf[n] = 0; t = v; while (t) { buf[--n] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_oct(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_string(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%d" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_signed(int v) { char buf[16]; if (v >= 0) snprintf(buf, 16, " + CHR$(34) + "+%d" + CHR$(34) + ", v); else snprintf(buf, 16, " + CHR$(34) + "%d" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_null(int n) { if (n < 0) n = 0; char* r = xb_alloc((size_t)n); memset(r, 0, (size_t)n); return r; }"
PRINT "static double xb_sqrt(double v) { return sqrt(v); }"
PRINT "static double xb_sin(double v) { return sin(v); }"
PRINT "static double xb_cos(double v) { return cos(v); }"
PRINT "static double xb_tan(double v) { return tan(v); }"
PRINT "static double xb_exp(double v) { return exp(v); }"
PRINT "static double xb_log(double v) { return log(v); }"
PRINT "static double xb_acos(double v) { return acos(v); }"
PRINT "static double xb_asin(double v) { return asin(v); }"
PRINT "static double xb_atan(double v) { return atan(v); }"
PRINT "static double xb_atn(double v) { return atan(v); }"
PRINT "static double xb_atan2(double a, double b) { return atan2(a, b); }"
PRINT "static double xb_log10(double v) { return log10(v); }"
PRINT "static double xb_power(double a, double b) { return pow(a, b); }"
PRINT "static double xb_sinh(double v) { return sinh(v); }"
PRINT "static double xb_cosh(double v) { return cosh(v); }"
PRINT "static double xb_tanh(double v) { return tanh(v); }"
PRINT "static double xb_asinh(double v) { return asinh(v); }"
PRINT "static double xb_acosh(double v) { return acosh(v); }"
PRINT "static double xb_atanh(double v) { return atanh(v); }"
PRINT "static double xb_exp10(double v) { return pow(10.0, v); }"
PRINT "static double xb_exp2(double v) { return pow(2.0, v); }"
PRINT "static double xb_cot(double v) { return 1.0 / tan(v); }"
PRINT "static double xb_sec(double v) { return 1.0 / cos(v); }"
PRINT "static double xb_csc(double v) { return 1.0 / sin(v); }"
PRINT "static double xb_sech(double v) { return 1.0 / cosh(v); }"
PRINT "static double xb_csch(double v) { return 1.0 / sinh(v); }"
PRINT "static double xb_coth(double v) { return 1.0 / tanh(v); }"
PRINT "static double xb_acot(double v) { return v > 1.0 ? atan(1.0/v) : M_PI_2 - atan(v); }"
PRINT "static double xb_asec(double v) { return M_PI_2 - asin(1.0/v); }"
PRINT "static double xb_acsc(double v) { return asin(1.0/v); }"
PRINT "static double xb_acoth(double v) { return atanh(1.0/v); }"
PRINT "static double xb_asech(double v) { return acosh(1.0/v); }"
PRINT "static double xb_acsch(double v) { return asinh(1.0/v); }"
PRINT "static double xb_rnd(void) { return (double)rand() / RAND_MAX; }"
PRINT "static double xb_ceil(double v) { return ceil(v); }"
PRINT "static double xb_floor(double v) { return floor(v); }"
PRINT "static double xb_round(double v) { return round(v); }"
PRINT "static double xb_timer(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); return tm->tm_hour*3600.0 + tm->tm_min*60.0 + tm->tm_sec; }"
PRINT "static char* xb_time(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char buf[9]; snprintf(buf, 9, " + CHR$(34) + "%02d:%02d:%02d" + CHR$(34) + ", tm->tm_hour, tm->tm_min, tm->tm_sec); return xb_from_cstr(buf); }"
PRINT "static char* xb_date(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char buf[11]; snprintf(buf, 11, " + CHR$(34) + "%04d-%02d-%02d" + CHR$(34) + ", tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday); return xb_from_cstr(buf); }"
PRINT "static char* xb_hexx(int v, int w) { char buf[34]; buf[0]='0'; buf[1]='x'; if (w > 0) snprintf(buf+2, 32, " + CHR$(34) + "%0*X" + CHR$(34) + ", w, v); else snprintf(buf+2, 32, " + CHR$(34) + "%X" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_rjust(const char* s, int w) { int len = xb_len(s); if (len >= w) return xb_strdup(s); char* r = xb_alloc((size_t)w); int pad = w - len; for (int i = 0; i < pad; i++) r[i] = ' '; memcpy(r + pad, s, (size_t)len); return r; }"
PRINT "static char* xb_ljust(const char* s, int w) { int len = xb_len(s); if (len >= w) return xb_strdup(s); char* r = xb_alloc((size_t)w); memcpy(r, s, (size_t)len); for (int i = len; i < w; i++) r[i] = ' '; return r; }"
PRINT "static char* xb_rclip1(const char* s) { int len = xb_len(s); while (len > 0 && isspace((unsigned char)s[len-1])) len--; char* r = xb_alloc((size_t)len); memcpy(r, s, (size_t)len); return r; }"
PRINT "static char* xb_rclip2(const char* s, int n) { int len = xb_len(s); if (n >= len) return xb_str(" + CHR$(34) + "" + CHR$(34) + "); int newlen = len - n; char* r = xb_alloc((size_t)newlen); memcpy(r, s, (size_t)newlen); return r; }"
PRINT "static char* xb_lclip1(const char* s) { int n = xb_len(s); int i = 0; while (i < n && isspace((unsigned char)s[i])) i++; int len = n - i; char* r = xb_alloc((size_t)len); memcpy(r, s + i, (size_t)len); return r; }"
PRINT "static char* xb_lclip2(const char* s, int n) { int len = xb_len(s); if (n >= len) return xb_str(" + CHR$(34) + "" + CHR$(34) + "); int nl = len - n; char* r = xb_alloc((size_t)nl); memcpy(r, s + n, (size_t)nl); return r; }"
PRINT "static int xb_inchr(const char* s, const char* set, int start) { int len = xb_len(s); for (int i = start - 1; i < len; i++) { if (strchr(set, s[i])) return i + 1; } return 0; }"
PRINT "static int xb_rinchr(const char* s, const char* set, int end) { int len = xb_len(s); int begin = end - 1; if (begin >= len) begin = len - 1; for (int i = begin; i >= 0; i--) { if (strchr(set, s[i])) return i + 1; } return 0; }"
PRINT "static int xb_inchri(const char* s, const char* set, int start) { int len = xb_len(s); char* lset = xb_strdup(set); for (char* p = lset; *p; p++) *p = (char)tolower((unsigned char)*p); for (int i = start - 1; i < len; i++) { if (strchr(lset, tolower((unsigned char)s[i]))) return i + 1; } return 0; }"
PRINT "static int xb_rinchri(const char* s, const char* set, int end) { int len = xb_len(s); int begin = end - 1; if (begin >= len) begin = len - 1; char* lset = xb_strdup(set); for (char* p = lset; *p; p++) *p = (char)tolower((unsigned char)*p); for (int i = begin; i >= 0; i--) { if (strchr(lset, tolower((unsigned char)s[i]))) return i + 1; } return 0; }"
PRINT "static int xb_inchr2(const char* s, const char* set) { return xb_inchr(s, set, 1); }"
PRINT "static int xb_rinchr2(const char* s, const char* set) { return xb_rinchr(s, set, xb_len(s)); }"
PRINT "static int xb_inchri2(const char* s, const char* set) { return xb_inchri(s, set, 1); }"
PRINT "static int xb_rinchri2(const char* s, const char* set) { return xb_rinchri(s, set, xb_len(s)); }"
PRINT "static char* xb_mid2(const char* s, int start) { int slen = xb_len(s); if (start < 1) start = 1; int off = start - 1; if (off >= slen) return xb_str(" + CHR$(34) + "" + CHR$(34) + "); int len = slen - off; char* r = xb_alloc((size_t)len); memcpy(r, s + off, (size_t)len); return r; }"
PRINT "static char* xb_stuff(const char* into, const char* from, int start, int len) { int ilen = xb_len(into); int flen = xb_len(from); int si = start - 1; if (si < 0) si = 0; if (si > ilen) si = ilen; int avail = ilen - si; int max_from = (len < 0) ? flen : (len < flen ? len : flen); int p2 = max_from < avail ? max_from : avail; char* r = xb_alloc((size_t)ilen); memcpy(r, into, (size_t)si); memcpy(r + si, from, (size_t)p2); memcpy(r + si + p2, into + si + p2, (size_t)(ilen - si - p2)); return r; }"
PRINT "static char* xb_version(int _) { (void)_; return xb_from_cstr(xb_version_str); }"
PRINT "static int xb_data_int[256]; static double xb_data_float[256]; static char* xb_data_str[256]; static int xb_data_tag[256]; static int xb_data_count = 0; static int xb_data_pos = 0;"
PRINT "static void xb_data_add_int(int v) { xb_data_tag[xb_data_count] = 0; xb_data_int[xb_data_count] = v; xb_data_count++; }"
PRINT "static void xb_data_add_float(double v) { xb_data_tag[xb_data_count] = 1; xb_data_float[xb_data_count] = v; xb_data_count++; }"
PRINT "static void xb_data_add_str(const char* v) { xb_data_tag[xb_data_count] = 2; xb_data_str[xb_data_count] = xb_from_cstr(v); xb_data_count++; }"
PRINT "static void xb_read_int(int* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int)xb_data_float[xb_data_pos]; else *v = atoi(xb_data_str[xb_data_pos]); xb_data_pos++; }"
PRINT "static void xb_read_giant(int64_t* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int64_t)xb_data_float[xb_data_pos]; else *v = (int64_t)atoll(xb_data_str[xb_data_pos]); xb_data_pos++; }"
PRINT "static void xb_read_float(double* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 1) *v = xb_data_float[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 0) *v = (double)xb_data_int[xb_data_pos]; else *v = atof(xb_data_str[xb_data_pos]); xb_data_pos++; }"
PRINT "static char* xb_read_str(void) { if (xb_data_pos >= xb_data_count) return xb_str(" + CHR$(34) + "" + CHR$(34) + "); char* r; if (xb_data_tag[xb_data_pos] == 2) r = xb_strdup(xb_data_str[xb_data_pos]); else { char buf[400]; if (xb_data_tag[xb_data_pos] == 0) snprintf(buf, 400, " + CHR$(34) + "%d" + CHR$(34) + ", xb_data_int[xb_data_pos]); else xb_fmt_float(xb_data_float[xb_data_pos], buf, 400); r = xb_from_cstr(buf); } xb_data_pos++; return r; }"
PRINT "static void xb_restore(int idx) { xb_data_pos = idx; }"
PRINT "static int xb_error_code = 0;"
PRINT "static int xb_error(int n) { int old = xb_error_code; if (n != -1) xb_error_code = n; return old; }"
PRINT "static char* xb_error_str(int n) { char buf[32]; snprintf(buf, 32, " + CHR$(34) + "error %d" + CHR$(34) + ", n); return xb_from_cstr(buf); }"
PRINT "static int xb_csize(const char* s) { const char* p = s; while (*p) p++; return (int)(p - s); }"
PRINT "static char* xb_csize_str(const char* s) { return xb_from_cstr(s); }"
PRINT "static char* xb_program_name(int _) { (void)_; return xb_from_cstr(xb_program_name_str); }"
PRINT "static FILE* xb_files[256]; static int xb_file_count = 3;"
PRINT "static int xb_open(const char* name, int mode) {"
PRINT "    int nonblock = (mode & 0x0800) != 0;"
PRINT "    int base = mode & ~0x0800;"
PRINT "    FILE* f = NULL;"
PRINT "#ifdef _WIN32"
PRINT "    (void)nonblock;"
PRINT "    if (base == 0 || base == 0x10) f = fopen(name, " + CHR$(34) + "rb" + CHR$(34) + ");"
PRINT "    else if (base == 1 || base == 3 || base == 4) f = fopen(name, " + CHR$(34) + "w+b" + CHR$(34) + ");"
PRINT "    else if (base == 2 || base == 0x20 || base == 0x30) { f = fopen(name, " + CHR$(34) + "r+b" + CHR$(34) + "); if (!f) f = fopen(name, " + CHR$(34) + "w+b" + CHR$(34) + "); }"
PRINT "    else f = fopen(name, " + CHR$(34) + "rb" + CHR$(34) + ");"
PRINT "#else"
PRINT "    int flags, access;"
PRINT "    if (base == 0 || base == 0x10) { flags = O_RDONLY; access = 0; }"
PRINT "    else if (base == 1 || base == 3) { flags = O_WRONLY | O_CREAT | O_TRUNC; access = 1; }"
PRINT "    else if (base == 2) { flags = O_RDWR | O_CREAT; access = 2; }"
PRINT "    else if (base == 4) { flags = O_RDWR | O_CREAT | O_TRUNC; access = 2; }"
PRINT "    else if (base == 0x20) { flags = O_WRONLY | O_CREAT; access = 1; }"
PRINT "    else if (base == 0x30) { flags = O_RDWR | O_CREAT; access = 2; }"
PRINT "    else { flags = O_RDONLY; access = 0; }"
PRINT "    if (nonblock) flags |= O_NONBLOCK;"
PRINT "    int fd = open(name, flags, 0666);"
PRINT "    if (fd >= 0) { f = fdopen(fd, access == 0 ? " + CHR$(34) + "rb" + CHR$(34) + " : (access == 1 ? " + CHR$(34) + "wb" + CHR$(34) + " : " + CHR$(34) + "r+b" + CHR$(34) + ")); if (!f) close(fd); }"
PRINT "#endif"
PRINT "    if (!f) return -1;"
PRINT "    if (xb_file_count >= 256) return -1;"
PRINT "    int fn = xb_file_count++;"
PRINT "    xb_files[fn] = f;"
PRINT "    return fn;"
PRINT "}"
PRINT "static int xb_close(int fn) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;"
PRINT "    int r = fclose(xb_files[fn]);"
PRINT "    xb_files[fn] = NULL;"
PRINT "    return r == 0 ? 0 : -1;"
PRINT "}"
PRINT "static int xb_lof(int fn) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;"
PRINT "    FILE* f = xb_files[fn];"
PRINT "    long cur = ftell(f);"
PRINT "    fseek(f, 0, SEEK_END);"
PRINT "    long len = ftell(f);"
PRINT "    fseek(f, cur, SEEK_SET);"
PRINT "    return (int)len;"
PRINT "}"
PRINT "static int xb_pof(int fn) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;"
PRINT "    return (int)ftell(xb_files[fn]);"
PRINT "}"
PRINT "static int xb_seek(int fn, int pos) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;"
PRINT "    return fseek(xb_files[fn], pos, SEEK_SET) == 0 ? pos : -1;"
PRINT "}"
PRINT "static int xb_write_record(int fn, int count) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn] || count < 0) return -1;"
PRINT "    if (count == 0) return 0;"
PRINT "    unsigned char* buf = (unsigned char*)calloc((size_t)count, 1);"
PRINT "    if (!buf) return -1;"
PRINT "    size_t put = fwrite(buf, 1, (size_t)count, xb_files[fn]);"
PRINT "    free(buf);"
PRINT "    if (fflush(xb_files[fn]) != 0) return -1;"
PRINT "    return put == (size_t)count ? count : -1;"
PRINT "}"
PRINT "static int xb_read_record(int fn, int count) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn] || count < 0) return -1;"
PRINT "    if (count == 0) return 0;"
PRINT "    unsigned char* buf = (unsigned char*)malloc((size_t)count);"
PRINT "    if (!buf) return -1;"
PRINT "    size_t got = fread(buf, 1, (size_t)count, xb_files[fn]);"
PRINT "    free(buf);"
PRINT "    return (int)got;"
PRINT "}"
PRINT "static char* xb_infile(int fn) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return xb_str(" + CHR$(34) + "" + CHR$(34) + ");"
PRINT "    char buf[65536];"
PRINT "    if (!fgets(buf, sizeof(buf), xb_files[fn])) return xb_str(" + CHR$(34) + "" + CHR$(34) + ");"
PRINT "    int len = (int)strlen(buf);"
PRINT "    if (len > 0 && buf[len-1] == '" + CHR$(92) + "n') buf[len-1] = 0;"
PRINT "    return xb_from_cstr(buf);"
PRINT "}"
PRINT "static char* xb_tab(int cur, int col) { if (col <= cur) return xb_str(" + CHR$(34) + "" + CHR$(34) + "); int n = col - cur; char* r = xb_alloc((size_t)n); memset(r, ' ', (size_t)n); return r; }"
PRINT "static char* xb_tab_0(int col) { return xb_tab(0, col); }"
PRINT "static int xb_isdata(const char* s) { return (s && s[0]) ? -1 : 0; }"
PRINT "static char* xb_inkey(void) {"
PRINT "    int c = getchar();"
PRINT "    if (c == EOF) return xb_str(" + CHR$(34) + "" + CHR$(34) + ");"
PRINT "    char buf[2]; buf[0] = (char)c; buf[1] = 0;"
PRINT "    return xb_from_cstr(buf);"
PRINT "}"
PRINT "static int xb_waitkey(void) { int c = getchar(); return (c == EOF) ? 0 : c; }"
PRINT "static int xb_isnode(const char* s) { return 0; }"
PRINT "static intptr_t xb_goaddr(intptr_t x) { return x; }"
PRINT "static intptr_t xb_subaddr(intptr_t x) { return x; }"
PRINT "static intptr_t xb_funcaddress(intptr_t x) { return x; }"
PRINT "static char* xb_cstring(intptr_t addr) { return addr ? xb_from_cstr((char*)addr) : xb_str(" + CHR$(34) + "" + CHR$(34) + "); }"
PRINT "static int xb_sbyteat(intptr_t addr, intptr_t off) { return (int)(*(signed char*)(addr + off)); }"
PRINT "static int xb_ubyteat(intptr_t addr, intptr_t off) { return (int)(*(unsigned char*)(addr + off)); }"
PRINT "static int xb_sshortat(intptr_t addr, intptr_t off) { return (int)(*(signed short*)(addr + off)); }"
PRINT "static int xb_ushortat(intptr_t addr, intptr_t off) { return (int)(*(unsigned short*)(addr + off)); }"
PRINT "static int xb_slongat(intptr_t addr, intptr_t off) { return (int)(*(signed int*)(addr + off)); }"
PRINT "static int xb_ulongat(intptr_t addr, intptr_t off) { return (int)(*(unsigned int*)(addr + off)); }"
PRINT "static intptr_t xb_xlongat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }"
PRINT "static intptr_t xb_giantat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }"
PRINT "static double xb_singleat(intptr_t addr, intptr_t off) { return (double)(*(float*)(addr + off)); }"
PRINT "static double xb_doubleat(intptr_t addr, intptr_t off) { return *(double*)(addr + off); }"
PRINT "static intptr_t xb_subaddrat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }"
PRINT "static intptr_t xb_goaddrat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }"
PRINT "static void xb_mid_assign(char* dst, int start, int len, const char* src) {"
PRINT "    int dlen = xb_len(dst);"
PRINT "    int slen = xb_len(src);"
PRINT "    if (start < 1 || start > dlen) return;"
PRINT "    int si = start - 1;"
PRINT "    int copy = (len < 0) ? slen : len;"
PRINT "    if (copy > slen) copy = slen;"
PRINT "    if (si + copy > dlen) copy = dlen - si;"
PRINT "    memcpy(dst + si, src, copy);"
PRINT "}"
PRINT "static void* xb_gosub_stack[256]; static int xb_gosub_sp = 0;"
IF INSTR(src$, CHR$(92) + "0") > 0 THEN
  PRINT "static char* xb_str_n(const char* s, size_t n) { char* d = xb_alloc(n); memcpy(d, s, n); return d; }"
END IF
IF INSTR(src$, "INLINE$(") > 0 THEN
  PRINT "static char* xb_inline(const char* prompt) { if (prompt) xb_print_str(prompt); return xb_readline(); }"
END IF
##funcTypes$ = ","
##funcArity$ = ""
##funcIds$ = ":"
##gosubRetCount$ = ""
##sharedDecls$ = ""
##sharedArrays$ = ""
##sharedArrDecls$ = ""
##dynNames$ = ""
##byrefDual$ = ""
##undimmed$ = ""
##fileScopeDecls$ = ""
##doStack$ = ""
##curLead$ = "0"
##constDefines$ = ""
##hadDecls$ = "0"
##selLead$ = ""
##noLead$ = "0"
##dynStr$ = ""
##strDual$ = ""
##dualUse$ = ""
##arr2d$ = ""
##scalarSeen$ = ""
##arrDimsSeen$ = ""
##fwdScalars$ = ""
##curFnArrays$ = ""
##curFnShapes$ = ""
##curParams$ = ""
##arrParams$ = ""
##funcMixed$ = ","
##curCallFn$ = ""
##byrefWB$ = ","
##curFnName$ = ""
##byrefWBCopy$ = ""
##sharedStrInits$ = ""
##inFuncScope = 0
##selectState = 0
##selectExpr$ = ""
##selectIsString = 0
##selectBraces = 0
##selectExitCount = 0
##nestFns$ = ""
##selectExitStack$ = ""
##sharedArrays$ = scan_shared_arr$(src$)
##dynNames$ = scan_dyn$(src$)
##byrefDual$ = scan_byref_dual$(src$)
##strDual$ = scan_str_dual$(src$)
##dualUse$ = scan_dual_use$(src$)
##arr2d$ = scan_arr2d$(src$)
##allStrArr$ = scan_all_strarr$(src$)
##xstArrays$ = scan_xst_arrays$(src$)
PRINT ""
IF LEN(##xstArrays$) > 0 THEN
  PRINT "static int xb_qs_gt(const uint64_t* a, int et, intptr_t i, intptr_t j, int decr, int ci) {"
  PRINT "    int c;"
  PRINT "    if (et == 1) { double x, y; memcpy(&x, &a[i], 8); memcpy(&y, &a[j], 8); c = (x > y) - (x < y); }"
  PRINT "    else if (et == 2) { const char* x = (const char*)a[i]; const char* y = (const char*)a[j];"
  PRINT "        int lx = xb_len(x), ly = xb_len(y), m = lx < ly ? lx : ly, r = 0;"
  PRINT "        for (int k = 0; k < m; k++) { unsigned char cx = (unsigned char)x[k], cy = (unsigned char)y[k]; if (ci) { if (cx>='A'&&cx<='Z') cx+=32; if (cy>='A'&&cy<='Z') cy+=32; } if (cx != cy) { r = cx < cy ? -1 : 1; break; } }"
  PRINT "        if (r == 0) r = (lx > ly) - (lx < ly); c = r; }"
  PRINT "    else { int64_t x = (int64_t)a[i], y = (int64_t)a[j]; c = (x > y) - (x < y); }"
  PRINT "    if (decr) c = -c;"
  PRINT "    return c > 0;"
  PRINT "}"
  PRINT "static int xb_quicksort(void* ap, int et, intptr_t alen, intptr_t** nd, intptr_t* nub, intptr_t low, intptr_t high, intptr_t mode) {"
  PRINT "    uint64_t* a = (uint64_t*)ap; int decr = (int)(mode & 1), ci = (int)(mode & 2);"
  PRINT "    if (low <= high && high < alen) {"
  PRINT "        intptr_t rng = high - low + 1;"
  PRINT "        intptr_t* idx = (intptr_t*)malloc((size_t)rng * sizeof(intptr_t));"
  PRINT "        for (intptr_t k = 0; k < rng; k++) idx[k] = low + k;"
  PRINT "        for (intptr_t k = 1; k < rng; k++) { intptr_t cur = idx[k]; intptr_t m = k - 1; while (m >= 0 && xb_qs_gt(a, et, idx[m], cur, decr, ci)) { idx[m+1] = idx[m]; m--; } idx[m+1] = cur; }"
  PRINT "        uint64_t* tmp = (uint64_t*)malloc((size_t)rng * 8);"
  PRINT "        for (intptr_t k = 0; k < rng; k++) tmp[k] = a[idx[k]];"
  PRINT "        for (intptr_t k = 0; k < rng; k++) a[low + k] = tmp[k];"
  PRINT "        if (nd && nub && *nub >= 0) {"
  PRINT "            *nd = (intptr_t*)realloc(*nd, (size_t)alen * sizeof(intptr_t)); *nub = alen - 1;"
  PRINT "            for (intptr_t k = 0; k < alen; k++) (*nd)[k] = k;"
  PRINT "            for (intptr_t k = 0; k < rng; k++) (*nd)[low + k] = idx[k];"
  PRINT "        }"
  PRINT "        free(idx); free(tmp);"
  PRINT "    }"
  PRINT "    return 0;"
  PRINT "}"
  PRINT "static int xb_copyarray(void* srcp, intptr_t srclen, int et, void** dst_d, intptr_t* dst_ub) {"
  PRINT "    if (!dst_d || !dst_ub) return 0;"
  PRINT "    uint64_t* src = (uint64_t*)srcp;"
  PRINT "    *dst_d = realloc(*dst_d, (size_t)(srclen < 1 ? 1 : srclen) * 8); *dst_ub = srclen - 1;"
  PRINT "    uint64_t* dst = (uint64_t*)*dst_d;"
  PRINT "    for (intptr_t k = 0; k < srclen; k++) {"
  PRINT "        if (et == 2) dst[k] = (uint64_t)(intptr_t)xb_strdup((const char*)src[k]);"
  PRINT "        else dst[k] = src[k];"
  PRINT "    }"
  PRINT "    return 0;"
  PRINT "}"
  PRINT ""
END IF
IF INSTR(src$, "XuiGetNextCallback") > 0 THEN
  PRINT "static int xb_gui_close_sent = 0;"
  PRINT "static int xb_gui_next_callback(intptr_t* grid, char** msg) {"
  PRINT "    if (!xb_gui_close_sent) { xb_gui_close_sent = 1; *grid = 1; *msg = xb_from_cstr(" + CHR$(34) + "CloseWindow" + CHR$(34) + "); return -1; }"
  PRINT "    return 0;"
  PRINT "}"
  PRINT ""
END IF
IF INSTR(src$, "GetStdHandle") > 0 OR INSTR(src$, "WriteFile") > 0 OR INSTR(src$, "ReadFile") > 0 THEN
  PRINT "static int xb_getstdhandle(int dev) { if (dev == -10) return 0; if (dev == -11) return 1; if (dev == -12) return 2; return -1; }"
  PRINT "static int xb_write_file(int h, const char* buf, int bytes, int* written, void* ov) {"
  PRINT "    (void)ov; if (written) *written = 0;"
  PRINT "    if (h != 1 && h != 2) return 0;"
  PRINT "    if (!buf || bytes <= 0) return bytes == 0 ? 1 : 0;"
  PRINT "    FILE* f = (h == 1) ? stdout : stderr;"
  PRINT "    size_t n = fwrite(buf, 1, (size_t)bytes, f);"
  PRINT "    if (h == 1) fflush(stdout);"
  PRINT "    if (written) *written = (int)n;"
  PRINT "    return (int)n == bytes ? 1 : 0;"
  PRINT "}"
  PRINT "static int xb_read_file(int h, char** buf, int bytes, int* read, void* ov) {"
  PRINT "    (void)ov; if (read) *read = 0;"
  PRINT "    if (h != 0 || !buf || bytes <= 0) return 0;"
  PRINT "    char* tmp = (char*)malloc((size_t)bytes);"
  PRINT "    if (!tmp) return 0;"
  PRINT "    size_t n = fread(tmp, 1, (size_t)bytes, stdin);"
  PRINT "    char* d = xb_alloc(n); if (n) memcpy(d, tmp, n);"
  PRINT "    free(tmp); *buf = d;"
  PRINT "    if (read) *read = (int)n;"
  PRINT "    return n > 0 ? 1 : 0;"
  PRINT "}"
  PRINT ""
END IF
IF INSTR(src$, "XgrProcessMessages") > 0 THEN
  PRINT "static void xb_xgr_process_messages(intptr_t mode) { (void)mode; exit(0); }"
  PRINT ""
END IF
' Forward declarations: pre-scan all lines for function signatures
##constDefines$ = ""
cpos = 1
WHILE cpos <= LEN(src$)
  cle = INSTR(src$, CHR$(10), cpos)
  IF cle = 0 THEN
    cle = LEN(src$) + 1
  END IF
  cln$ = trim_spaces$(MID$(src$, cpos, cle - cpos))
  cpos = cle + 1
  IF LEFT$(cln$, 6) = "const " THEN
    crest$ = MID$(cln$, 7, LEN(cln$) - 6)
    ceq = INSTR(crest$, " = ")
    IF ceq > 0 THEN
      cnm$ = LEFT$(crest$, ceq - 1)
      chp = INSTR(cnm$, "$$")
      IF chp > 0 THEN
        cnm$ = MID$(cnm$, chp + 2, LEN(cnm$) - chp)
      END IF
      ccp = INSTR(cnm$, ":")
      IF ccp > 0 THEN
        cnm$ = LEFT$(cnm$, ccp - 1)
      END IF
      cvl$ = MID$(crest$, ceq + 3, LEN(crest$) - ceq)
      cvp = INSTR(cvl$, "(")
      IF cvp > 0 THEN
        cvl$ = MID$(cvl$, cvp + 1, LEN(cvl$) - cvp - 1)
      END IF
      ##constDefines$ = ##constDefines$ + "#define XB_CONST_" + cnm$ + " " + cvl$ + CHR$(10)
    END IF
  END IF
WEND
IF LEN(##constDefines$) > 0 THEN
  PRINT ##constDefines$
END IF
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
      ##curFnName$ = fwdName$
      fwdDeclsBuf$ = fwdDeclsBuf$ + fwdName$ + CHR$(9) + fwdParams$ + CHR$(9) + fwdRet$ + CHR$(10)
      ##funcTypes$ = ##funcTypes$ + fwdName$ + ":" + fwdRet$ + ","
      ##funcIds$ = ##funcIds$ + fwdName$ + ":"
      IF INSTR(##funcArity$, ":" + fwdName$ + "=") = 0 THEN
        ##funcArity$ = ##funcArity$ + ":" + fwdName$ + "=" + param_count$(fwdParams$) + ":"
      END IF
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
          PRINT c_type$(fwdSType$) + " xb_shared_" + sanitize_ident$(fwdSName$) + " = 0;"
          IF fwdSType$ = "string" THEN
            ##sharedStrInits$ = ##sharedStrInits$ + sanitize_ident$(fwdSName$) + ","
          END IF
        END IF
      END IF
    ELSEIF LEFT$(fwdStmt$, 11) = "dim shared " THEN
      fwdRest$ = MID$(fwdStmt$, 12, LEN(fwdStmt$) - 11)
      fwdColon = INSTR(fwdRest$, ":")
      IF fwdColon > 0 THEN
        fwdSName$ = LEFT$(fwdRest$, fwdColon - 1)
        fwdSAfter$ = MID$(fwdRest$, fwdColon + 1, LEN(fwdRest$) - fwdColon)
        fwdSPos = INSTR(fwdSAfter$, "[")
        IF fwdSPos > 0 THEN
          fwdSType$ = LEFT$(fwdSAfter$, fwdSPos - 1)
        ELSE
          fwdSType$ = fwdSAfter$
        END IF
        IF INSTR(##sharedArrays$, ":" + fwdSName$ + ":") > 0 THEN
          IF INSTR(##sharedArrDecls$, ":" + fwdSName$ + ":") = 0 THEN
            ##sharedArrDecls$ = ##sharedArrDecls$ + ":" + fwdSName$ + ":"
            PRINT c_type$(fwdSType$) + "* " + c_var_name$(fwdSName$, fwdSType$) + " = 0; intptr_t xb_ub_" + sanitize_ident$(fwdSName$) + " = -1;"
            IF INSTR(##arr2d$, ":" + fwdSName$ + ":") > 0 THEN
              PRINT "intptr_t xb_d1_" + sanitize_ident$(fwdSName$) + " = 0;"
            END IF
          END IF
        END IF
      END IF
    END IF
  END IF
WEND
' Undeclared shared scalars: a `shared(##X:type)` read with no `shared X:type`
' declaration (interp defaults to 0). Rust emits `<type> xb_shared_X = 0;` at file
' scope. Scan the IR text for such refs and emit the missing global (dedup via
' ##sharedDecls$, so declared shareds are untouched).
shPat$ = "shared(##"
shRP$ = ")"
shRefPos = INSTR(src$, shPat$)
WHILE shRefPos > 0
  shNameStart = shRefPos + 9
  shColonP = INSTR(src$, ":", shNameStart)
  shCloseP = INSTR(src$, shRP$, shNameStart)
  IF shColonP > 0 AND shColonP < shCloseP THEN
    shRefName$ = MID$(src$, shNameStart, shColonP - shNameStart)
    shRefType$ = MID$(src$, shColonP + 1, shCloseP - shColonP - 1)
    IF INSTR(##sharedDecls$, ":" + shRefName$ + ":") = 0 THEN
      ##sharedDecls$ = ##sharedDecls$ + ":" + shRefName$ + ":"
      PRINT c_type$(shRefType$) + " xb_shared_" + sanitize_ident$(shRefName$) + " = 0;"
      IF shRefType$ = "string" THEN
        ##sharedStrInits$ = ##sharedStrInits$ + sanitize_ident$(shRefName$) + ","
      END IF
    END IF
  END IF
  shRefPos = INSTR(src$, shPat$, shNameStart)
WEND
' Keyword-SHARED scalar dims: `dim shared X:type` (no bracket). The
' in-function declaration is suppressed; storage is the xb_shared_X global
' declared here (dedup via ##sharedDecls$). Line-based (LEFT$ prefix check)
' so a "dim shared " STRING LITERAL inside any statement cannot match —
' whole-text INSTR would match its own pattern during self-host.
dsPos = 1
WHILE dsPos <= LEN(src$)
  dsLe = INSTR(src$, CHR$(10), dsPos)
  IF dsLe = 0 THEN
    dsLe = LEN(src$) + 1
  END IF
  dsLn$ = trim_spaces$(MID$(src$, dsPos, dsLe - dsPos))
  dsPos = dsLe + 1
  IF LEFT$(dsLn$, 11) = "dim shared " THEN
    dsRest$ = MID$(dsLn$, 12, LEN(dsLn$) - 11)
    dsColon = INSTR(dsRest$, ":")
    dsBr = INSTR(dsRest$, "[")
    IF dsColon > 1 AND (dsBr = 0 OR dsBr > dsColon) THEN
      dsRefName$ = LEFT$(dsRest$, dsColon - 1)
      dsSp = INSTR(dsRest$, " ", dsColon + 1)
      IF dsSp = 0 THEN
        dsRefType$ = MID$(dsRest$, dsColon + 1, LEN(dsRest$) - dsColon)
      ELSE
        dsRefType$ = MID$(dsRest$, dsColon + 1, dsSp - dsColon - 1)
      END IF
      IF INSTR(##sharedDecls$, ":" + dsRefName$ + ":") = 0 THEN
        ##sharedDecls$ = ##sharedDecls$ + ":" + dsRefName$ + ":"
        PRINT c_type$(dsRefType$) + " xb_shared_" + sanitize_ident$(dsRefName$) + " = 0;"
        IF dsRefType$ = "string" THEN
          ##sharedStrInits$ = ##sharedStrInits$ + sanitize_ident$(dsRefName$) + ","
        END IF
      END IF
    END IF
  END IF
WEND
##funcMixed$ = scan_mixed_byref$(src$)
##byrefWB$ = scan_byref_wb$(src$)
' Emit deferred forward declarations (now that ##byrefWB$ is set for pointer params)
DIM _fdName$
DIM _fdParams$
DIM _fdRet$
DIM _fdLine$
DIM _fdTab1
DIM _fdTab2
DIM _fdRest$
WHILE LEN(fwdDeclsBuf$) > 0
  _fdTab1 = INSTR(fwdDeclsBuf$, CHR$(9))
  _fdTab2 = INSTR(fwdDeclsBuf$, CHR$(9), _fdTab1 + 1)
  _fdLine$ = MID$(fwdDeclsBuf$, 1, INSTR(fwdDeclsBuf$, CHR$(10)) - 1)
  _fdName$ = LEFT$(_fdLine$, _fdTab1 - 1)
  _fdParams$ = MID$(_fdLine$, _fdTab1 + 1, _fdTab2 - _fdTab1 - 1)
  _fdRet$ = MID$(_fdLine$, _fdTab2 + 1, LEN(_fdLine$) - _fdTab2)
  ##curFnName$ = _fdName$
  ' CG-BYTES: parameterless prototypes use C `(void)` and a trailing blank
  ' line, matching the Rust CEmitter's forward-declaration block.
  IF LEN(trim_spaces$(_fdParams$)) = 0 THEN
    ##hadDecls$ = "1"
    PRINT c_type$(_fdRet$) + " xb_user_" + _fdName$ + "(void);"
  ELSE
    ##hadDecls$ = "1"
    PRINT c_type$(_fdRet$) + " xb_user_" + _fdName$ + "(" + emit_params$(_fdParams$) + ");"
  END IF
  _fdRest$ = MID$(fwdDeclsBuf$, INSTR(fwdDeclsBuf$, CHR$(10)) + 1, LEN(fwdDeclsBuf$) - INSTR(fwdDeclsBuf$, CHR$(10)))
  fwdDeclsBuf$ = _fdRest$
WEND
IF ##hadDecls$ = "1" THEN
  PRINT ""
END IF

##dynNames$ = scan_dyn$(src$)
##byrefDual$ = scan_byref_dual$(src$)
##undimmed$ = scan_undimmed$(src$)
##dynStr$ = scan_dynstr$(src$)
##strDual$ = scan_str_dual$(src$)
##dualUse$ = scan_dual_use$(src$)
##arr2d$ = scan_arr2d$(src$)
hasMain = 0
inFunc = 0
inNest = 0
nestBlocks$ = ""
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
    lead = j - 1
    ##curLead$ = STR$(lead)
    IF LEFT$(stmt$, 5) = "data " THEN
      DIM dataRest$
      dataRest$ = MID$(stmt$, 6, LEN(stmt$) - 5)
      DIM dataPos
      dataPos = 1
      DO
        DIM dataSpace
        dataSpace = INSTR(dataRest$, " ", dataPos)
        DIM dataToken$
        IF dataSpace = 0 THEN
          dataToken$ = MID$(dataRest$, dataPos, LEN(dataRest$) - dataPos + 1)
        ELSE
          dataToken$ = MID$(dataRest$, dataPos, dataSpace - dataPos)
        END IF
        DIM dataColon
        dataColon = INSTR(dataToken$, ":")
        IF dataColon > 0 THEN
          DIM dataType$
          DIM dataVal$
          dataType$ = LEFT$(dataToken$, dataColon - 1)
          dataVal$ = MID$(dataToken$, dataColon + 1, LEN(dataToken$) - dataColon)
          IF dataType$ = "intptr_t" THEN
            mainBody$ = mainBody$ + "    xb_data_add_int(" + dataVal$ + ");" + CHR$(10)
          ELSEIF dataType$ = "float" THEN
            mainBody$ = mainBody$ + "    xb_data_add_float(" + dataVal$ + ");" + CHR$(10)
          ELSE
            mainBody$ = mainBody$ + "    xb_data_add_str(" + CHR$(34) + dataVal$ + CHR$(34) + ");" + CHR$(10)
          END IF
        END IF
        IF dataSpace = 0 THEN
          EXIT DO
        END IF
        dataPos = dataSpace + 1
      LOOP
    ELSEIF LEFT$(stmt$, 9) = "function " THEN
      rest$ = MID$(stmt$, 10, LEN(stmt$) - 9)
      parenPos = INSTR(rest$, "(")
      nfName$ = LEFT$(rest$, parenPos - 1)
      IF inFunc = 1 THEN
        ' Nested INTERNAL FUNCTION: the frontend lowers its name as a label
        ' (label_addr(X) -> &&xb_label_X, gosub X -> goto xb_label_X). C forbids
        ' nested function definitions, so emit its body as an xb_label_<name>: block
        ' inside the parent (placed after the parent body, guarded from fall-through)
        ' and hoist its locals into the parent's shared C scope. Byte-neutral on the
        ' selfhost tools, which nest no functions.
        inNest = 1
        ##nestFns$ = ##nestFns$ + "," + nfName$
        nestBlocks$ = nestBlocks$ + "xb_label_" + nfName$ + ":" + CHR$(10)
        nfAfter$ = MID$(rest$, parenPos + 1, LEN(rest$) - parenPos)
        nfClose = INSTR(nfAfter$, ")")
        dimmedSyms$ = dimmedSyms$ + param_names$(LEFT$(nfAfter$, nfClose - 1))
      ELSE
        inFunc = 1
        funcName$ = nfName$
        IF INSTR(emittedFuncs$, ":" + funcName$ + ":") > 0 THEN
          skipFunc = 1
        ELSE
          skipFunc = 0
          emittedFuncs$ = emittedFuncs$ + ":" + funcName$ + ":"
          IF funcName$ = "Main" THEN
            hasMain = 1
          END IF
          afterParen$ = MID$(rest$, parenPos + 1, LEN(rest$) - parenPos)
          closeParen = INSTR(afterParen$, ")")
          params$ = LEFT$(afterParen$, closeParen - 1)
          IF LEN(firstFunc$) = 0 THEN
            firstFunc$ = funcName$
            firstParams$ = params$
          END IF
          retType$ = MID$(afterParen$, closeParen + 5, LEN(afterParen$) - closeParen - 4)
          ##arrParams$ = arr_param_names$(params$)
          ##curParams$ = param_names$(params$)
          ##curFnName$ = funcName$
          IF LEN(trim_spaces$(params$)) = 0 THEN
            PRINT c_type$(retType$) + " xb_user_" + funcName$ + "(void) {"
          ELSE
            PRINT c_type$(retType$) + " xb_user_" + funcName$ + "(" + emit_params$(params$) + ") {"
          END IF
          ' CGEN-BYREF-WRITEBACK: copy-in prologue for all-byref scalar params
          DIM _wbIn$
          _wbIn$ = gen_byref_cio$(params$)
          IF LEN(_wbIn$) > 0 THEN
            PRINT LEFT$(_wbIn$, LEN(_wbIn$) - 1)
          END IF
          funcBody$ = ""
          ##nestFns$ = ""
          usedSyms$ = CHR$(10)
          dimmedSyms$ = CHR$(10) + funcName$ + CHR$(10) + param_names$(params$)
          ##gosubRetCount$ = ""
          ##scalarSeen$ = ""
          ##arrDimsSeen$ = ""
          ##doStack$ = ""
          ##fwdScalars$ = ""
          ##curFnArrays$ = fn_array_dims$(src$, pos)
          ##curFnShapes$ = fn_array_shapes$(src$, pos)
          ##inFuncScope = 1
          nestBlocks$ = ""
          inNest = 0
        END IF
      END IF
    ELSEIF stmt$ = "end function" THEN
      IF inNest = 1 THEN
        nestBlocks$ = nestBlocks$ + "    if (xb_gosub_sp > xb_gosub_base) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;" + CHR$(10)
        inNest = 0
      ELSE
        inFunc = 0
        ##inFuncScope = 0
        ##curFnShapes$ = ""
        IF skipFunc = 0 THEN
          hoists$ = emit_hoists$(usedSyms$, dimmedSyms$)
          ' CG-BYTES: the return-value variable is declared only when the
          ' body actually assigns the function name; otherwise the function
          ' returns the type default directly (matching the Rust CEmitter).
          IF INSTR(funcBody$ + nestBlocks$, c_var_name$(funcName$, retType$) + " = ") > 0 THEN
            hoists$ = hoists$ + "    " + c_type$(retType$) + " " + c_var_name$(funcName$, retType$) + " = " + c_default$(retType$) + ";" + CHR$(10)
            retStmt$ = "    return " + c_var_name$(funcName$, retType$) + ";"
          ELSE
            retStmt$ = "    return " + c_default$(retType$) + ";"
          END IF
          fullBody$ = hoists$ + computed_goto_prologue$(funcBody$ + nestBlocks$) + funcBody$
          IF LEN(nestBlocks$) > 0 THEN
            fullBody$ = fullBody$ + "    if (xb_gosub_sp > xb_gosub_base) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;" + CHR$(10) + nestBlocks$
          END IF
          IF LEN(fullBody$) > 0 THEN
            PRINT LEFT$(fullBody$, LEN(fullBody$) - 1)
          END IF
          IF LEN(##byrefWBCopy$) > 0 THEN
            PRINT LEFT$(##byrefWBCopy$, LEN(##byrefWBCopy$) - 1)
          END IF
          PRINT retStmt$
          PRINT "}"
          PRINT ""
        END IF
        skipFunc = 0
        nestBlocks$ = ""
        ##nestFns$ = ""
      END IF
    ELSE
      IF skipFunc = 0 THEN
        cCode$ = emit_stmt$(stmt$)
        IF inFunc = 1 THEN
          IF LEFT$(stmt$, 4) = "dim " THEN
            IF INSTR(stmt$, "[") > 0 THEN
              ' CGEN-DIM-DEDUP: suppress only an IDENTICAL repeated native
              ' fixed-array declaration in this C function (Kittedy's two
              ' `DIM shuffle[uBlocks]` lines). Heap-backed/dynamic/shared/
              ' composite DIMs are executable resize/reset operations and must
              ' keep running. Store the exact IR line, not just the name, so a
              ' later DIM with a different bound/type is never hidden.
              DIM _adName$
              DIM _adSig$
              DIM _adNative
              _adName$ = dim_name$(stmt$)
              _adSig$ = CHR$(10) + stmt$ + CHR$(10)
              _adNative = 1
              IF INSTR(##dynNames$, ":" + _adName$ + ":") > 0 OR INSTR(##dynStr$, ":" + _adName$ + ":") > 0 OR INSTR(##strDual$, ":" + _adName$ + ":") > 0 OR INSTR(##sharedArrays$, ":" + _adName$ + ":") > 0 OR INSTR(##allStrArr$, ":" + _adName$ + ":") > 0 OR INSTR(##xstArrays$, ":" + _adName$ + ":") > 0 THEN
                _adNative = 0
              END IF
              IF _adNative = 1 THEN
                IF INSTR(##arrDimsSeen$, _adSig$) > 0 THEN
                  cCode$ = ""
                ELSE
                  ##arrDimsSeen$ = ##arrDimsSeen$ + _adSig$
                END IF
              END IF
            END IF
            IF INSTR(stmt$, "[") = 0 THEN
              IF dim_name$(stmt$) = funcName$ OR INSTR(##scalarSeen$, ":" + dim_name$(stmt$) + ":") > 0 THEN
                cCode$ = ""
              ELSEIF INSTR(cCode$, " xb_var_") > 0 OR INSTR(cCode$, " xb_str_") > 0 THEN
                IF INSTR(usedSyms$, CHR$(10) + dim_name$(stmt$) + "|") > 0 THEN
                  ##fwdScalars$ = ##fwdScalars$ + ":" + dim_name$(stmt$) + ":"
                  ##scalarSeen$ = ##scalarSeen$ + ":" + dim_name$(stmt$) + ":"
                  cCode$ = ""
                ELSE
                  ##scalarSeen$ = ##scalarSeen$ + ":" + dim_name$(stmt$) + ":"
                END IF
              END IF
            END IF
          END IF
        END IF
        IF inNest = 1 THEN
          usedSyms$ = scan_used$(stmt$, usedSyms$)
          IF LEFT$(stmt$, 4) = "dim " THEN
            dimmedSyms$ = dimmedSyms$ + dim_name$(stmt$) + CHR$(10)
          ELSEIF LEFT$(stmt$, 6) = "redim " THEN
            dimmedSyms$ = dimmedSyms$ + dim_name$(stmt$) + CHR$(10)
          END IF
          IF LEN(cCode$) > 0 THEN
            nestBlocks$ = nestBlocks$ + cCode$ + CHR$(10)
          END IF
        ELSEIF inFunc = 1 THEN
          IF ##noLead$ = "1" THEN
            ' SELECT structural lines carry their intrinsic indentation.
            ##noLead$ = "0"
          ELSEIF ##selLead$ <> "" THEN
            ' SELECT case bodies: Rust indents them at selLead+6 total.
            IF lead >= 2 THEN cCode$ = add_lead$(cCode$, VAL(##curLead$) + 2)
          ELSEIF lead >= 2 THEN
            cCode$ = add_lead$(cCode$, 2 * (lead - 2))
          END IF
          usedSyms$ = scan_used$(stmt$, usedSyms$)
          ' CG-BYTES: DO/LOOP render in the Rust CEmitter's exact shapes.
          IF LEFT$(stmt$, 3) = "do " OR stmt$ = "do" THEN
            preIsWhile$ = "0"
            postK$ = "0"
            IF LEN(stmt$) > 4 THEN
              kw$ = MID$(stmt$, 4, 5)
              IF kw$ = "while" THEN
                preIsWhile$ = "1"
                cCode$ = "    while (" + emit_expr$(trim_spaces$(MID$(stmt$, 10, LEN(stmt$) - 9))) + ") {"
              ELSEIF kw$ = "until" THEN
                preIsWhile$ = "1"
                cCode$ = "    while (!(" + emit_expr$(trim_spaces$(MID$(stmt$, 10, LEN(stmt$) - 9))) + ")) {"
              ELSE
                cCode$ = "    while (1) {"
              END IF
            ELSE
              ' Bare DO: look ahead to the matching LOOP for the post form.
              sp2 = pos
              found = 0
              WHILE sp2 <= LEN(src$) AND found = 0
                le2 = INSTR(src$, CHR$(10), sp2)
                IF le2 = 0 THEN
                  le2 = LEN(src$) + 1
                END IF
                ln2$ = MID$(src$, sp2, le2 - sp2)
                sp2 = le2 + 1
                l2 = 0
                WHILE ASC(MID$(ln2$, l2 + 1, 1)) = 32
                  l2 = l2 + 1
                WEND
                tr2$ = trim_spaces$(ln2$)
                IF l2 < lead THEN
                  EXIT WHILE
                END IF
                IF l2 = lead AND (tr2$ = "loop" OR LEFT$(tr2$, 5) = "loop ") THEN
                  found = 1
                  IF LEN(tr2$) > 4 THEN
                    kw2$ = MID$(tr2$, 6, 5)
                    IF kw2$ = "while" THEN
                      postK$ = "1"
                    ELSEIF kw2$ = "until" THEN
                      postK$ = "2"
                    END IF
                  END IF
                END IF
              WEND
              PRINT "static int dbg_bare = 1;"
              IF postK$ = "0" THEN
                cCode$ = "    while (1) {"
              ELSE
                cCode$ = "    do {"
              END IF
            END IF
            ##doStack$ = ##doStack$ + "|" + preIsWhile$ + postK$
            IF lead >= 2 THEN cCode$ = add_lead$(cCode$, 2 * (lead - 2))
            IF LEN(cCode$) > 0 THEN
              funcBody$ = funcBody$ + cCode$ + CHR$(10)
            END IF
          ELSEIF LEFT$(stmt$, 4) = "loop" THEN
            pl = LEN(##doStack$)
            pr = pl - 1
            IF pr < 1 THEN
              pr = 1
            END IF
            tok$ = MID$(##doStack$, pr, 2)
            ##doStack$ = LEFT$(##doStack$, pr - 1)
            preW$ = LEFT$(tok$, 1)
            postK$ = MID$(tok$, 2, 1)
            tr2$ = trim_spaces$(stmt$)
            cExpr$ = ""
            IF LEN(tr2$) > 4 THEN
              kw2$ = MID$(tr2$, 6, 5)
              IF kw2$ = "while" THEN
                postK$ = "1"
                cExpr$ = emit_expr$(trim_spaces$(MID$(tr2$, 11, LEN(tr2$) - 10)))
              ELSEIF kw2$ = "until" THEN
                postK$ = "2"
                cExpr$ = emit_expr$(trim_spaces$(MID$(tr2$, 11, LEN(tr2$) - 10)))
              END IF
            END IF
            IF postK$ = "1" THEN
              IF preW$ = "1" THEN
                cCode$ = "    if (!(" + cExpr$ + ")) break;" + CHR$(10) + "    }"
              ELSE
                cCode$ = "    } while ((" + cExpr$ + "));"
              END IF
            ELSEIF postK$ = "2" THEN
              IF preW$ = "1" THEN
                cCode$ = "    if ((" + cExpr$ + ")) break;" + CHR$(10) + "    }"
              ELSE
                cCode$ = "    } while (!(" + cExpr$ + "));"
              END IF
            ELSE
              cCode$ = "    }"
            END IF
            IF lead >= 2 THEN cCode$ = add_lead$(cCode$, 2 * (lead - 2))
            IF LEN(cCode$) > 0 THEN
              funcBody$ = funcBody$ + cCode$ + CHR$(10)
            END IF
          ELSE
          IF LEFT$(stmt$, 4) = "dim " THEN
            dimmedSyms$ = dimmedSyms$ + dim_name$(stmt$) + CHR$(10)
          ELSEIF LEFT$(stmt$, 6) = "redim " THEN
            dimmedSyms$ = dimmedSyms$ + dim_name$(stmt$) + CHR$(10)
          END IF
          IF LEN(cCode$) > 0 THEN
            funcBody$ = funcBody$ + cCode$ + CHR$(10)
          END IF
          END IF
        ELSE
          ' MODULE-DIM-SCOPE: a top-level fixed-size non-string array DIM
          ' becomes a file-scope static declaration so named functions can
          ' see it (C main() locals are invisible to called functions).
          ' Requires the DIM to precede the function in the IR (source order).
          IF LEFT$(stmt$, 4) = "dim " THEN
            IF INSTR(stmt$, "[") > 0 AND INSTR(stmt$, "[]") = 0 AND INSTR(stmt$, ":string") = 0 AND INSTR(stmt$, "shared") = 0 THEN
              IF LEN(cCode$) > 0 THEN
                ' cCode$ may be `decl; memset(...);` — only the DECLARATION is
                ' hoisted (executable code cannot live at file scope); any
                ' trailing statements stay in main().
                _mdSemi = INSTR(cCode$, ";")
                IF _mdSemi > 0 THEN
                  PRINT "static " + trim_spaces$(LEFT$(cCode$, _mdSemi))
                  cCode$ = MID$(cCode$, _mdSemi + 1)
                ELSE
                  PRINT "static " + cCode$
                  cCode$ = ""
                END IF
              END IF
            END IF
          END IF
          IF LEN(cCode$) > 0 THEN
            mainBody$ = mainBody$ + cCode$ + CHR$(10)
          END IF
        END IF
      END IF
    END IF
  END IF
WEND

PRINT "int main(void) {"
IF LEN(mainBody$) > 0 THEN
  PRINT LEFT$(mainBody$, LEN(mainBody$) - 1)
END IF
IF LEN(##sharedStrInits$) > 0 THEN
  DIM _ssiRest$
  DIM _ssiName$
  DIM _ssiComma
  _ssiRest$ = ##sharedStrInits$
  WHILE LEN(_ssiRest$) > 0
    _ssiComma = INSTR(_ssiRest$, ",")
    IF _ssiComma > 0 THEN
      _ssiName$ = LEFT$(_ssiRest$, _ssiComma - 1)
      _ssiRest$ = MID$(_ssiRest$, _ssiComma + 1, LEN(_ssiRest$) - _ssiComma)
    ELSE
      _ssiName$ = _ssiRest$
      _ssiRest$ = ""
    END IF
    IF LEN(_ssiName$) > 0 THEN
      PRINT "    xb_shared_" + _ssiName$ + " = xb_str(" + CHR$(34) + CHR$(34) + ");"
    END IF
  WEND
END IF
IF hasMain = 1 THEN
  PRINT "    xb_user_Main();"
ELSEIF LEN(firstFunc$) > 0 THEN
  IF LEN(trim_spaces$(firstParams$)) = 0 THEN
    PRINT "    xb_user_" + firstFunc$ + "();"
  END IF
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
    c_type$ = "intptr_t"
  END IF
END FUNCTION

FUNCTION c_var_name$(n$, t$)
  DIM sn$
  sn$ = sanitize_ident$(n$)
  ' A name ending with $ is always a string, regardless of the IR type parameter.
  ' The IR can type xbasic$ as integer in some contexts (type collision), but the
  ' $ suffix determines the C variable prefix.
  IF t$ = "string" OR RIGHT$(n$, 1) = "$" THEN
    c_var_name$ = "xb_str_" + sn$
  ELSE
    c_var_name$ = "xb_var_" + sn$
  END IF
END FUNCTION

FUNCTION c_default$(t$)
  IF t$ = "string" THEN
    c_default$ = "xb_str(" + CHR$(34) + CHR$(34) + ")"
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
    c_func_name$ = "xb_instr2"
  ELSEIF n$ = "RINSTR" THEN
    c_func_name$ = "xb_rinstr2"
  ELSEIF n$ = "INSTRI" THEN
    c_func_name$ = "xb_instri2"
  ELSEIF n$ = "RINSTRI" THEN
    c_func_name$ = "xb_rinstri2"
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
  ELSEIF n$ = "ROTATEL" THEN
    c_func_name$ = "xb_rotatel"
  ELSEIF n$ = "ROTATER" THEN
    c_func_name$ = "xb_rotater"
  ELSEIF n$ = "DHIGH" THEN
    c_func_name$ = "xb_dhigh"
  ELSEIF n$ = "DLOW" THEN
    c_func_name$ = "xb_dlow"
  ELSEIF n$ = "DMAKE" THEN
    c_func_name$ = "xb_dmake"
  ELSEIF n$ = "GMAKE" THEN
    c_func_name$ = "xb_gmake"
  ELSEIF n$ = "SMAKE" THEN
    c_func_name$ = "xb_smake"
  ELSEIF n$ = "XMAKE" THEN
    c_func_name$ = "xb_xmake"
  ELSEIF n$ = "ERROR" THEN
    c_func_name$ = "xb_error"
  ELSEIF n$ = "ERROR$" THEN
    c_func_name$ = "xb_error_str"
  ELSEIF n$ = "QUIT" THEN
    c_func_name$ = "xb_quit"
  ELSEIF n$ = "CJUST$" THEN
    c_func_name$ = "xb_cjust"
  ELSEIF n$ = "RJUST$" THEN
    c_func_name$ = "xb_rjust"
  ELSEIF n$ = "LJUST$" THEN
    c_func_name$ = "xb_ljust"
  ELSEIF n$ = "OCTO$" THEN
    c_func_name$ = "xb_octo"
  ELSEIF n$ = "BINB$" THEN
    c_func_name$ = "xb_binb"
  ELSEIF n$ = "FORMAT$" THEN
    c_func_name$ = "xb_format"
  ELSEIF n$ = "SHELL" THEN
    c_func_name$ = "xb_shell"
  ELSEIF n$ = "LIBRARY" THEN
    c_func_name$ = "xb_library"
  ELSEIF n$ = "BITFIELD" THEN
    c_func_name$ = "xb_bitfield"
  ELSEIF n$ = "EXTS" THEN
    c_func_name$ = "xb_exts"
  ELSEIF n$ = "EXTU" THEN
    c_func_name$ = "xb_extu"
  ELSEIF n$ = "CLR" THEN
    c_func_name$ = "xb_clr"
  ELSEIF n$ = "SET" THEN
    c_func_name$ = "xb_set"
  ELSEIF n$ = "MAKE" THEN
    c_func_name$ = "xb_make"
  ELSEIF n$ = "HIGH0" THEN
    c_func_name$ = "xb_high0"
  ELSEIF n$ = "HIGH1" THEN
    c_func_name$ = "xb_high1"
  ELSEIF n$ = "GHIGH" THEN
    c_func_name$ = "xb_ghigh"
  ELSEIF n$ = "GLOW" THEN
    c_func_name$ = "xb_glow"
  ELSEIF n$ = "SIGN" THEN
    c_func_name$ = "xb_sign"
  ELSEIF n$ = "HEX$" THEN
    c_func_name$ = "xb_hex"
  ELSEIF n$ = "HEXX$" THEN
    c_func_name$ = "xb_hexx"
  ELSEIF n$ = "OCT$" THEN
    c_func_name$ = "xb_oct"
  ELSEIF n$ = "BIN$" THEN
    c_func_name$ = "xb_bin"
  ELSEIF n$ = "INCHR" THEN
    c_func_name$ = "xb_inchr2"
  ELSEIF n$ = "RINCHR" THEN
    c_func_name$ = "xb_rinchr2"
  ELSEIF n$ = "INCHRI" THEN
    c_func_name$ = "xb_inchri2"
  ELSEIF n$ = "RINCHRI" THEN
    c_func_name$ = "xb_rinchri2"
  ELSEIF n$ = "STUFF$" THEN
    c_func_name$ = "xb_stuff"
  ELSEIF n$ = "RCLIP$" THEN
    c_func_name$ = "xb_rclip"
  ELSEIF n$ = "LCLIP$" THEN
    c_func_name$ = "xb_lclip"
  ELSEIF n$ = "STRING$" OR n$ = "STRING" THEN
    c_func_name$ = "xb_string"
  ELSEIF n$ = "SIGNED$" THEN
    c_func_name$ = "xb_signed"
  ELSEIF n$ = "NULL$" THEN
    c_func_name$ = "xb_null"
  ELSEIF n$ = "SQRT" THEN
    c_func_name$ = "xb_sqrt"
  ELSEIF n$ = "SIN" THEN
    c_func_name$ = "xb_sin"
  ELSEIF n$ = "COS" THEN
    c_func_name$ = "xb_cos"
  ELSEIF n$ = "TAN" THEN
    c_func_name$ = "xb_tan"
  ELSEIF n$ = "EXP" THEN
    c_func_name$ = "xb_exp"
  ELSEIF n$ = "LOG" THEN
    c_func_name$ = "xb_log"
  ELSEIF n$ = "ACOS" THEN
    c_func_name$ = "xb_acos"
  ELSEIF n$ = "ASIN" THEN
    c_func_name$ = "xb_asin"
  ELSEIF n$ = "POWER" THEN
    c_func_name$ = "xb_power"
  ELSEIF n$ = "SINH" THEN
    c_func_name$ = "xb_sinh"
  ELSEIF n$ = "COSH" THEN
    c_func_name$ = "xb_cosh"
  ELSEIF n$ = "TANH" THEN
    c_func_name$ = "xb_tanh"
  ELSEIF n$ = "ASINH" THEN
    c_func_name$ = "xb_asinh"
  ELSEIF n$ = "ACOSH" THEN
    c_func_name$ = "xb_acosh"
  ELSEIF n$ = "ATANH" THEN
    c_func_name$ = "xb_atanh"
  ELSEIF n$ = "EXP10" THEN
    c_func_name$ = "xb_exp10"
  ELSEIF n$ = "EXP2" THEN
    c_func_name$ = "xb_exp2"
  ELSEIF n$ = "COT" THEN
    c_func_name$ = "xb_cot"
  ELSEIF n$ = "SEC" THEN
    c_func_name$ = "xb_sec"
  ELSEIF n$ = "CSC" THEN
    c_func_name$ = "xb_csc"
  ELSEIF n$ = "COTH" THEN
    c_func_name$ = "xb_coth"
  ELSEIF n$ = "SECH" THEN
    c_func_name$ = "xb_sech"
  ELSEIF n$ = "CSCH" THEN
    c_func_name$ = "xb_csch"
  ELSEIF n$ = "ACOT" THEN
    c_func_name$ = "xb_acot"
  ELSEIF n$ = "ASEC" THEN
    c_func_name$ = "xb_asec"
  ELSEIF n$ = "ACSC" THEN
    c_func_name$ = "xb_acsc"
  ELSEIF n$ = "ACOTH" THEN
    c_func_name$ = "xb_acoth"
  ELSEIF n$ = "ASECH" THEN
    c_func_name$ = "xb_asech"
  ELSEIF n$ = "ACSCH" THEN
    c_func_name$ = "xb_acsch"
  ELSEIF n$ = "ATAN2" THEN
    c_func_name$ = "xb_atan2"
  ELSEIF n$ = "LOG10" THEN
    c_func_name$ = "xb_log10"
  ELSEIF n$ = "ATN" THEN
    c_func_name$ = "xb_atn"
  ELSEIF n$ = "ATAN" THEN
    c_func_name$ = "xb_atan"
  ELSEIF n$ = "CEIL" THEN
    c_func_name$ = "xb_ceil"
  ELSEIF n$ = "FLOOR" THEN
    c_func_name$ = "xb_floor"
  ELSEIF n$ = "ROUND" THEN
    c_func_name$ = "xb_round"
  ELSEIF n$ = "RND" THEN
    c_func_name$ = "xb_rnd"
  ELSEIF n$ = "TIMER" THEN
    c_func_name$ = "xb_timer"
  ELSEIF n$ = "TIME$" THEN
    c_func_name$ = "xb_time"
  ELSEIF n$ = "DATE$" THEN
    c_func_name$ = "xb_date"
  ELSEIF n$ = "INLINE$" THEN
    c_func_name$ = "xb_inline"
  ELSEIF n$ = "READLINE$" THEN
    c_func_name$ = "xb_readline"
  ELSEIF n$ = "EOF" THEN
    c_func_name$ = "xb_eof"
  ELSEIF n$ = "VERSION$" THEN
    c_func_name$ = "xb_version"
  ELSEIF n$ = "CSIZE" THEN
    c_func_name$ = "xb_csize"
  ELSEIF n$ = "CSIZE$" THEN
    c_func_name$ = "xb_csize_str"
  ELSEIF n$ = "PROGRAM$" THEN
    c_func_name$ = "xb_program_name"
  ELSEIF n$ = "OPEN" THEN
    c_func_name$ = "xb_open"
  ELSEIF n$ = "CLOSE" THEN
    c_func_name$ = "xb_close"
  ELSEIF n$ = "LOF" THEN
    c_func_name$ = "xb_lof"
  ELSEIF n$ = "POF" THEN
    c_func_name$ = "xb_pof"
  ELSEIF n$ = "SEEK" THEN
    c_func_name$ = "xb_seek"
  ELSEIF n$ = "INFILE$" THEN
    c_func_name$ = "xb_infile"
  ELSEIF n$ = "__WRITE_RECORD" THEN
    c_func_name$ = "xb_write_record"
  ELSEIF n$ = "__READ_RECORD" THEN
    c_func_name$ = "xb_read_record"
  ELSEIF n$ = "TAB" THEN
    c_func_name$ = "xb_tab_0"
  ELSEIF n$ = "ISDATA" THEN
    c_func_name$ = "xb_isdata"
  ELSEIF n$ = "INKEY$" THEN
    c_func_name$ = "xb_inkey"
  ELSEIF n$ = "WAITKEY" THEN
    c_func_name$ = "xb_waitkey"
  ELSEIF n$ = "ISNODE" THEN
    c_func_name$ = "xb_isnode"
  ELSEIF n$ = "GOADDR" THEN
    c_func_name$ = "xb_goaddr"
  ELSEIF n$ = "SUBADDR" THEN
    c_func_name$ = "xb_subaddr"
  ELSEIF n$ = "CSTRING$" THEN
    c_func_name$ = "xb_cstring"
  ELSEIF n$ = "FUNCADDRESS" THEN
    c_func_name$ = "xb_funcaddress"
  ELSEIF n$ = "SBYTEAT" THEN
    c_func_name$ = "xb_sbyteat"
  ELSEIF n$ = "UBYTEAT" THEN
    c_func_name$ = "xb_ubyteat"
  ELSEIF n$ = "SSHORTAT" THEN
    c_func_name$ = "xb_sshortat"
  ELSEIF n$ = "USHORTAT" THEN
    c_func_name$ = "xb_ushortat"
  ELSEIF n$ = "SLONGAT" THEN
    c_func_name$ = "xb_slongat"
  ELSEIF n$ = "ULONGAT" THEN
    c_func_name$ = "xb_ulongat"
  ELSEIF n$ = "XLONGAT" THEN
    c_func_name$ = "xb_xlongat"
  ELSEIF n$ = "GIANTAT" THEN
    c_func_name$ = "xb_giantat"
  ELSEIF n$ = "SINGLEAT" THEN
    c_func_name$ = "xb_singleat"
  ELSEIF n$ = "DOUBLEAT" THEN
    c_func_name$ = "xb_doubleat"
  ELSEIF n$ = "SUBADDRAT" THEN
    c_func_name$ = "xb_subaddrat"
  ELSEIF n$ = "GOADDRAT" THEN
    c_func_name$ = "xb_goaddrat"
  ELSEIF n$ = "XuiGetNextCallback" THEN
    c_func_name$ = "xb_gui_next_callback"
  ELSEIF n$ = "XgrProcessMessages" THEN
    c_func_name$ = "xb_xgr_process_messages"
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
    ' CG-BYTES: builtin result types the print/assign paths depend on
    ' (mirrors the Rust CEmitter's builtin table).
    IF fn$ = "GMAKE" OR fn$ = "GIANT" THEN
      expr_type$ = "giant"
      RETURN expr_type$
    ELSEIF fn$ = "DMAKE" OR fn$ = "SMAKE" THEN
      expr_type$ = "float"
      RETURN expr_type$
    ELSEIF fn$ = "XMAKE" THEN
      expr_type$ = "integer"
      RETURN expr_type$
    END IF
    IF fn$ = "ABS" OR fn$ = "DOUBLE" OR fn$ = "SINGLE" THEN
      DIM absArgs$
      IF parenPos > 0 THEN
        absArgs$ = MID$(rest$, parenPos + 1, LEN(rest$) - parenPos - 1)
      ELSE
        absArgs$ = ""
      END IF
      expr_type$ = expr_type$(absArgs$)
    ELSEIF fn$ = "XLONG" OR fn$ = "SBYTE" OR fn$ = "UBYTE" OR fn$ = "SSHORT" OR fn$ = "USHORT" OR fn$ = "SLONG" OR fn$ = "ULONG" OR fn$ = "GIANT" THEN
      expr_type$ = "integer"
    ELSEIF fn$ = "LEN" OR fn$ = "ASC" OR fn$ = "INSTR" OR fn$ = "RINSTR" OR fn$ = "INSTRI" OR fn$ = "RINSTRI" OR fn$ = "VAL" OR fn$ = "EOF" OR fn$ = "ABS" OR fn$ = "SGN" OR fn$ = "INT" OR fn$ = "FIX" OR fn$ = "MAX" OR fn$ = "MIN" OR fn$ = "INCHR" OR fn$ = "RINCHR" OR fn$ = "INCHRI" OR fn$ = "RINCHRI" OR fn$ = "ROTATEL" OR fn$ = "ROTATER" OR fn$ = "DHIGH" OR fn$ = "DLOW" OR fn$ = "GMAKE" OR fn$ = "XMAKE" OR fn$ = "ERROR" OR fn$ = "BITFIELD" OR fn$ = "EXTS" OR fn$ = "EXTU" OR fn$ = "CLR" OR fn$ = "SET" OR fn$ = "MAKE" OR fn$ = "HIGH0" OR fn$ = "HIGH1" OR fn$ = "GHIGH" OR fn$ = "GLOW" OR fn$ = "SIGN" OR fn$ = "QUIT" OR fn$ = "SHELL" OR fn$ = "LIBRARY" OR fn$ = "CSIZE" OR fn$ = "FUNCADDRESS" OR fn$ = "SUBADDRESS" OR fn$ = "GOADDRESS" OR fn$ = "GOADDR" OR fn$ = "SUBADDR" OR fn$ = "SBYTEAT" OR fn$ = "UBYTEAT" OR fn$ = "SSHORTAT" OR fn$ = "USHORTAT" OR fn$ = "SLONGAT" OR fn$ = "ULONGAT" OR fn$ = "XLONGAT" OR fn$ = "GIANTAT" OR fn$ = "SUBADDRAT" OR fn$ = "GOADDRAT" OR fn$ = "OPEN" OR fn$ = "CLOSE" OR fn$ = "LOF" OR fn$ = "POF" OR fn$ = "SEEK" OR fn$ = "SIZE" OR fn$ = "ISDATA" OR fn$ = "ISNODE" OR fn$ = "WAITKEY" OR fn$ = "GOADDR" OR fn$ = "SUBADDR" THEN
      expr_type$ = "integer"
    ELSEIF fn$ = "SQRT" OR fn$ = "SIN" OR fn$ = "COS" OR fn$ = "TAN" OR fn$ = "EXP" OR fn$ = "LOG" OR fn$ = "ATN" OR fn$ = "ATAN" OR fn$ = "CEIL" OR fn$ = "FLOOR" OR fn$ = "ROUND" OR fn$ = "RND" OR fn$ = "TIMER" OR fn$ = "ACOS" OR fn$ = "ASIN" OR fn$ = "ATAN2" OR fn$ = "LOG10" OR fn$ = "POWER" OR fn$ = "SINH" OR fn$ = "COSH" OR fn$ = "TANH" OR fn$ = "ASINH" OR fn$ = "ACOSH" OR fn$ = "ATANH" OR fn$ = "EXP10" OR fn$ = "EXP2" OR fn$ = "COT" OR fn$ = "SEC" OR fn$ = "CSC" OR fn$ = "COTH" OR fn$ = "SECH" OR fn$ = "CSCH" OR fn$ = "ACOT" OR fn$ = "ASEC" OR fn$ = "ACSC" OR fn$ = "ACOTH" OR fn$ = "ASECH" OR fn$ = "ACSCH" OR fn$ = "SINGLEAT" OR fn$ = "DOUBLEAT" OR fn$ = "DMAKE" OR fn$ = "SMAKE" THEN
      expr_type$ = "float"
    ELSEIF fn$ = "CHR$" OR fn$ = "LEFT$" OR fn$ = "RIGHT$" OR fn$ = "MID$" OR fn$ = "STR$" OR fn$ = "READLINE$" OR fn$ = "UCASE$" OR fn$ = "LCASE$" OR fn$ = "TRIM$" OR fn$ = "LTRIM$" OR fn$ = "RTRIM$" OR fn$ = "SPACE$" OR fn$ = "HEX$" OR fn$ = "BIN$" OR fn$ = "OCT$" OR fn$ = "STRING$" OR fn$ = "STRING" OR fn$ = "INLINE$" OR fn$ = "TIME$" OR fn$ = "DATE$" OR fn$ = "HEXX$" OR fn$ = "RJUST$" OR fn$ = "LJUST$" OR fn$ = "CJUST$" OR fn$ = "RCLIP$" OR fn$ = "LCLIP$" OR fn$ = "STUFF$" OR fn$ = "VERSION$" OR fn$ = "SIGNED$" OR fn$ = "NULL$" OR fn$ = "ERROR$" OR fn$ = "OCTO$" OR fn$ = "BINB$" OR fn$ = "FORMAT$" OR fn$ = "CSIZE$" OR fn$ = "PROGRAM$" OR fn$ = "INFILE$" OR fn$ = "TAB" OR fn$ = "INKEY$" OR fn$ = "CSTRING$" THEN
      expr_type$ = "string"
    ELSE
      ftPos = INSTR(##funcTypes$, "," + fn$ + ":")
      IF ftPos > 0 THEN
        ftStart = ftPos + 1 + LEN(fn$) + 1
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
    ELSEIF op$ = "\\" OR op$ = "mod" THEN
      expr_type$ = "integer"
    ELSEIF expr_type$(left$) = "float" OR expr_type$(right$) = "float" THEN
      expr_type$ = "float"
    ELSE
      expr_type$ = "integer"
    END IF
  ELSEIF LEFT$(e$, 8) = "compare(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 4) = "not(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 4) = "neg(" OR LEFT$(e$, 4) = "pos(" THEN
    rest$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    expr_type$ = expr_type$(rest$)
  ELSEIF LEFT$(e$, 4) = "and(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 3) = "or(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 4) = "xor(" THEN
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
  ELSEIF LEFT$(e$, 13) = "array_ubound(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 8) = "size_of(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 13) = "size_of_type(" THEN
    expr_type$ = "integer"
  ELSEIF LEFT$(e$, 11) = "label_addr(" THEN
    expr_type$ = "integer"
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
    IF inQuote = 1 AND ch = 92 THEN
      p = p + 2
    ELSE
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
    END IF
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

' CG-BYTES: re-indent an emitted statement to its IR nesting depth.
FUNCTION add_lead$(a$, extra)
  DIM out$
  DIM rest$
  DIM nl
  DIM pad$
  DIM i
  IF extra <= 0 THEN
    add_lead$ = a$
    RETURN add_lead$
  END IF
  pad$ = ""
  FOR i = 1 TO extra
    pad$ = pad$ + " "
  NEXT i
  out$ = ""
  rest$ = a$
  WHILE LEN(rest$) > 0
    nl = INSTR(rest$, CHR$(10))
    IF nl = 0 THEN
      IF LEN(trim_spaces$(rest$)) > 0 THEN
        out$ = out$ + pad$ + rest$
      END IF
      rest$ = ""
    ELSE
      ln$ = LEFT$(rest$, nl - 1)
      IF LEN(trim_spaces$(ln$)) > 0 THEN
        out$ = out$ + pad$ + ln$
      END IF
      out$ = out$ + CHR$(10)
      rest$ = MID$(rest$, nl + 1, LEN(rest$) - nl)
    END IF
  WEND
  add_lead$ = out$
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
  DIM selTy$
  DIM _sl$
  DIM _sl2$
  DIM _si
  DIM _ndShape$
  DIM _ndRank
  DIM _ndIdxRank

  IF LEFT$(e$, 7) = "string(" THEN
    t$ = MID$(e$, 9, LEN(e$) - 10)
    IF INSTR(t$, CHR$(92) + "0") > 0 THEN
      emit_expr$ = "xb_str_n(" + CHR$(34) + t$ + CHR$(34) + ", (int)sizeof(" + CHR$(34) + t$ + CHR$(34) + ") - 1)"
    ELSE
      emit_expr$ = "xb_str(" + CHR$(34) + t$ + CHR$(34) + ")"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 8) = "integer(" THEN
    t$ = MID$(e$, 9, LEN(e$) - 9)
    IF LEFT$(t$, 2) = "0x" OR LEFT$(t$, 2) = "0X" OR LEFT$(t$, 2) = "0b" OR LEFT$(t$, 2) = "0B" THEN
      emit_expr$ = "(int32_t)(" + t$ + ")"
    ELSE
      emit_expr$ = strip_zeros$(t$)
    END IF
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
    IF expr_type$(left$) = "string" AND expr_type$(right$) = "string" THEN
      emit_expr$ = "(-(xb_scmp(" + emit_expr$(left$) + ", " + emit_expr$(right$) + ") " + c_cmp_op$(op$) + " 0))"
    ELSEIF expr_type$(left$) = "string" OR expr_type$(right$) = "string" THEN
      IF expr_type$(left$) = "string" THEN
        emit_expr$ = "-((intptr_t)xb_len(" + emit_expr$(left$) + ") " + c_cmp_op$(op$) + " " + emit_expr$(right$) + ")"
      ELSE
        emit_expr$ = "-(" + emit_expr$(left$) + " " + c_cmp_op$(op$) + " (intptr_t)xb_len(" + emit_expr$(right$) + "))"
      END IF
    ELSE
      emit_expr$ = "-(" + emit_expr$(left$) + " " + c_cmp_op$(op$) + " " + emit_expr$(right$) + ")"
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
    ELSEIF op$ = "shl" THEN
      emit_expr$ = "(" + emit_expr$(left$) + " << " + emit_expr$(right$) + ")"
    ELSEIF op$ = "shr" THEN
      emit_expr$ = "(" + emit_expr$(left$) + " >> " + emit_expr$(right$) + ")"
    ELSEIF op$ = "\\" THEN
      emit_expr$ = "(" + emit_expr$(left$) + " / " + emit_expr$(right$) + ")"
    ELSE
      emit_expr$ = "(" + emit_expr$(left$) + " " + op$ + " " + emit_expr$(right$) + ")"
    END IF
    IF expr_type$(e$) = "integer" AND op$ <> "**" THEN
      emit_expr$ = "(int32_t)" + emit_expr$
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "not(" THEN
    t$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    emit_expr$ = "(int32_t)(~" + emit_expr$(t$) + ")"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "neg(" THEN
    t$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    IF expr_type$(t$) = "integer" THEN
      emit_expr$ = "(int32_t)(-" + emit_expr$(t$) + ")"
    ELSE
      emit_expr$ = "(-" + emit_expr$(t$) + ")"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "pos(" THEN
    t$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    emit_expr$ = "(+" + emit_expr$(t$) + ")"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "and(" THEN
    rest$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "(int32_t)((" + emit_expr$(left$) + ") & (" + emit_expr$(right$) + "))"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 3) = "or(" THEN
    rest$ = MID$(e$, 4, LEN(e$) - 3)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "(int32_t)((" + emit_expr$(left$) + ") | (" + emit_expr$(right$) + "))"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "xor(" THEN
    rest$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "(int32_t)((" + emit_expr$(left$) + ") ^ (" + emit_expr$(right$) + "))"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 5) = "land(" THEN
    rest$ = MID$(e$, 6, LEN(e$) - 5)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "(((" + emit_expr$(left$) + ") != 0) && ((" + emit_expr$(right$) + ") != 0)) ? -1 : 0"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 4) = "lor(" THEN
    rest$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "(((" + emit_expr$(left$) + ") != 0) || ((" + emit_expr$(right$) + ") != 0)) ? -1 : 0"
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 5) = "lxor(" THEN
    rest$ = MID$(e$, 6, LEN(e$) - 5)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "(((" + emit_expr$(left$) + ") != 0) != ((" + emit_expr$(right$) + ") != 0)) ? -1 : 0"
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
    DIM emittedArgs$
    ##curCallFn$ = fn$
    emittedArgs$ = emit_args$(args$)
    ##curCallFn$ = ""
    DIM funcName$
    funcName$ = c_func_name$(fn$)
    IF fn$ = "EOF" THEN
      emit_expr$ = "xb_eof()"
      RETURN emit_expr$
    END IF
    IF fn$ = "SBYTEAT" OR fn$ = "UBYTEAT" OR fn$ = "SSHORTAT" OR fn$ = "USHORTAT" OR fn$ = "SLONGAT" OR fn$ = "ULONGAT" OR fn$ = "XLONGAT" OR fn$ = "GIANTAT" OR fn$ = "SUBADDRAT" OR fn$ = "GOADDRAT" THEN
      ' *AT memory reads: the interpreter has no real memory and returns 0
      ' (builtin.rs); emit the zero-default (also sidesteps the 1-arg call vs
      ' 2-arg xb_*at helper mismatch). Mirrors the Rust CEmitter.
      emit_expr$ = "0"
      RETURN emit_expr$
    END IF
    IF fn$ = "SINGLEAT" OR fn$ = "DOUBLEAT" THEN
      emit_expr$ = "0.0"
      RETURN emit_expr$
    END IF
    IF fn$ = "TYPE" OR fn$ = "Type" THEN
      ' TYPE(x): the interpreter returns the value's type number (non-zero for a
      ' real value). cgen.x can't recover the IR-erased element type, but a non-zero
      ' result mirrors the interp's control flow: demos test `type <> 0` before use
      ' and the lowered type constants ($$SBYTE..$$DCOMPLEX) are all 0, so a 0 stub
      ' (unknown-call default) wrongly falls through. Same class as the *AT stub.
      emit_expr$ = "1"
      RETURN emit_expr$
    END IF
    IF fn$ = "XuiGetNextCallback" THEN
      ' Headless GUI runtime: deliver one synthetic CloseWindow, then FALSE.
      ' Only the first 2 byref args (grid, message$) are passed; the rest are
      ' dropped, matching the Rust CEmitter (c_emit_expr.rs:336-343).
      emit_expr$ = "xb_gui_next_callback(" + emit_args_n$(args$, 2) + ")"
      RETURN emit_expr$
    END IF
    IF fn$ = "GetStdHandle" THEN
      ' RT-KERNEL32: Win32-CGI stdio handles (-10 stdin, -11 stdout, -12 stderr).
      emit_expr$ = "xb_getstdhandle(" + emit_expr$(first_comma_part$(args$)) + ")"
      RETURN emit_expr$
    END IF
    IF (fn$ = "WriteFile" OR fn$ = "ReadFile") THEN
      ' RT-KERNEL32 `WriteFile/ReadFile(h, &buf$, bytes, &written, _)`: the
      ' legacy `&x` prefix lowers to a PLAIN symbol, so out-params take their
      ' addresses positionally (mirrors interp call.rs + Rust c_emit_expr).
      DIM _k32h$
      DIM _k32buf$
      DIM _k32bytes$
      DIM _k32out$
      DIM _k32bn$
      DIM _k32bt$
      DIM _k32colon
      _k32h$ = top_part$(args$, 1)
      _k32buf$ = top_part$(args$, 2)
      _k32bytes$ = top_part$(args$, 3)
      _k32out$ = top_part$(args$, 4)
      _k32bn$ = _k32out$
      _k32bt$ = "integer"
      IF LEFT$(_k32out$, 7) = "symbol(" AND RIGHT$(_k32out$, 1) = ")" THEN
        _k32bn$ = MID$(_k32out$, 8, LEN(_k32out$) - 8)
        _k32colon = INSTR(_k32bn$, ":")
        IF _k32colon > 0 THEN
          _k32bt$ = MID$(_k32bn$, _k32colon + 1, LEN(_k32bn$) - _k32colon)
          _k32bn$ = LEFT$(_k32bn$, _k32colon - 1)
        ELSE
          _k32bt$ = "integer"
        END IF
      END IF
      IF fn$ = "WriteFile" THEN
        emit_expr$ = "xb_write_file(" + emit_expr$(_k32h$) + ", " + emit_expr$(_k32buf$) + ", " + emit_expr$(_k32bytes$) + ", &" + c_var_name$(_k32bn$, _k32bt$) + ", 0)"
      ELSE
        ' ReadFile's buffer is replaced through its char** address.
        DIM _k32rbn$
        DIM _k32rbt$
        _k32rbn$ = _k32buf$
        _k32rbt$ = "string"
        IF LEFT$(_k32buf$, 7) = "symbol(" AND RIGHT$(_k32buf$, 1) = ")" THEN
          _k32rbn$ = MID$(_k32buf$, 8, LEN(_k32buf$) - 8)
          _k32colon = INSTR(_k32rbn$, ":")
          IF _k32colon > 0 THEN
            _k32rbt$ = MID$(_k32rbn$, _k32colon + 1, LEN(_k32rbn$) - _k32colon)
            _k32rbn$ = LEFT$(_k32rbn$, _k32colon - 1)
          ELSE
            _k32rbt$ = "string"
          END IF
        END IF
        emit_expr$ = "xb_read_file(" + emit_expr$(_k32h$) + ", &" + c_var_name$(_k32rbn$, _k32rbt$) + ", " + emit_expr$(_k32bytes$) + ", &" + c_var_name$(_k32bn$, _k32bt$) + ", 0)"
      END IF
      RETURN emit_expr$
    END IF
    IF fn$ = "CHR$" THEN
      DIM chrDepth
      DIM chrI
      DIM chrCommas
      DIM chrCh
      chrDepth = 0
      chrCommas = 0
      FOR chrI = 1 TO LEN(args$)
        chrCh = ASC(MID$(args$, chrI, 1))
        IF chrCh = 40 THEN
          chrDepth = chrDepth + 1
        ELSEIF chrCh = 41 THEN
          chrDepth = chrDepth - 1
        ELSEIF chrCh = 44 AND chrDepth = 0 THEN
          chrCommas = chrCommas + 1
        END IF
      NEXT chrI
      IF chrCommas = 0 THEN
        emittedArgs$ = emittedArgs$ + ", 1"
      END IF
    END IF
    IF fn$ = "INSTR" THEN
      DIM instrDepth
      DIM instrI
      DIM instrCommas
      DIM instrCh
      instrDepth = 0
      instrCommas = 0
      FOR instrI = 1 TO LEN(args$)
        instrCh = ASC(MID$(args$, instrI, 1))
        IF instrCh = 40 THEN
          instrDepth = instrDepth + 1
        ELSEIF instrCh = 41 THEN
          instrDepth = instrDepth - 1
        ELSEIF instrCh = 44 AND instrDepth = 0 THEN
          instrCommas = instrCommas + 1
        END IF
      NEXT instrI
      IF instrCommas >= 2 THEN
        funcName$ = "xb_instr3"
      END IF
    END IF
    IF fn$ = "RINSTR" THEN
      DIM rinstrDepth
      DIM rinstrI
      DIM rinstrCommas
      DIM rinstrCh
      rinstrDepth = 0
      rinstrCommas = 0
      FOR rinstrI = 1 TO LEN(args$)
        rinstrCh = ASC(MID$(args$, rinstrI, 1))
        IF rinstrCh = 40 THEN
          rinstrDepth = rinstrDepth + 1
        ELSEIF rinstrCh = 41 THEN
          rinstrDepth = rinstrDepth - 1
        ELSEIF rinstrCh = 44 AND rinstrDepth = 0 THEN
          rinstrCommas = rinstrCommas + 1
        END IF
      NEXT rinstrI
      IF rinstrCommas >= 2 THEN
        funcName$ = "xb_rinstr3"
      END IF
    END IF
    IF fn$ = "INSTRI" OR fn$ = "RINSTRI" THEN
      DIM istriDepth
      DIM istriI
      DIM istriCommas
      DIM istriCh
      istriDepth = 0
      istriCommas = 0
      FOR istriI = 1 TO LEN(args$)
        istriCh = ASC(MID$(args$, istriI, 1))
        IF istriCh = 40 THEN
          istriDepth = istriDepth + 1
        ELSEIF istriCh = 41 THEN
          istriDepth = istriDepth - 1
        ELSEIF istriCh = 44 AND istriDepth = 0 THEN
          istriCommas = istriCommas + 1
        END IF
      NEXT istriI
      IF istriCommas >= 2 THEN
        IF fn$ = "INSTRI" THEN
          funcName$ = "xb_instri3"
        ELSE
          funcName$ = "xb_rinstri3"
        END IF
      END IF
    END IF
    IF fn$ = "ABS" THEN
      IF expr_type$(args$) = "float" THEN
        funcName$ = "xb_fabs"
      END IF
    END IF
    IF fn$ = "INCHR" OR fn$ = "RINCHR" OR fn$ = "INCHRI" OR fn$ = "RINCHRI" THEN
      DIM ichrDepth
      DIM ichrI
      DIM ichrCommas
      DIM ichrCh
      ichrDepth = 0
      ichrCommas = 0
      FOR ichrI = 1 TO LEN(args$)
        ichrCh = ASC(MID$(args$, ichrI, 1))
        IF ichrCh = 40 THEN
          ichrDepth = ichrDepth + 1
        ELSEIF ichrCh = 41 THEN
          ichrDepth = ichrDepth - 1
        ELSEIF ichrCh = 44 AND ichrDepth = 0 THEN
          ichrCommas = ichrCommas + 1
        END IF
      NEXT ichrI
      IF ichrCommas >= 2 THEN
        IF fn$ = "INCHR" THEN
          funcName$ = "xb_inchr"
        ELSEIF fn$ = "RINCHR" THEN
          funcName$ = "xb_rinchr"
        ELSEIF fn$ = "INCHRI" THEN
          funcName$ = "xb_inchri"
        ELSE
          funcName$ = "xb_rinchri"
        END IF
      END IF
    END IF
    IF fn$ = "DOUBLE" OR fn$ = "SINGLE" THEN
      DIM dargType$
      dargType$ = expr_type$(args$)
      IF dargType$ = "string" THEN
        emit_expr$ = "atof(" + emittedArgs$ + ")"
      ELSEIF dargType$ = "integer" THEN
        emit_expr$ = "(double)(" + emittedArgs$ + ")"
      ELSEIF fn$ = "GIANT" THEN
        emit_expr$ = "(int64_t)(" + emittedArgs$ + ")"
      ELSE
        emit_expr$ = "(" + emittedArgs$ + ")"
      END IF
      RETURN emit_expr$
    END IF
    IF fn$ = "XLONG" OR fn$ = "SBYTE" OR fn$ = "UBYTE" OR fn$ = "SSHORT" OR fn$ = "USHORT" OR fn$ = "SLONG" OR fn$ = "ULONG" OR fn$ = "GIANT" THEN
      DIM xargType$
      xargType$ = expr_type$(args$)
      IF xargType$ = "string" THEN
        emit_expr$ = "atoi(" + emittedArgs$ + ")"
      ELSEIF xargType$ = "float" THEN
        emit_expr$ = "(int)(" + emittedArgs$ + ")"
      ELSEIF fn$ = "GIANT" THEN
        emit_expr$ = "(int64_t)(" + emittedArgs$ + ")"
      ELSE
        emit_expr$ = "(" + emittedArgs$ + ")"
      END IF
      RETURN emit_expr$
    END IF
    IF fn$ = "HEXX$" THEN
      DIM hexxCommas
      hexxCommas = 0
      DIM hexxI
      DIM hexxDepth
      hexxDepth = 0
      FOR hexxI = 1 TO LEN(args$)
        DIM hexxCh
        hexxCh = ASC(MID$(args$, hexxI, 1))
        IF hexxCh = 40 THEN
          hexxDepth = hexxDepth + 1
        ELSEIF hexxCh = 41 THEN
          hexxDepth = hexxDepth - 1
        ELSEIF hexxCh = 44 AND hexxDepth = 0 THEN
          hexxCommas = hexxCommas + 1
        END IF
      NEXT hexxI
      IF hexxCommas = 0 THEN
        emittedArgs$ = emittedArgs$ + ", 0"
      END IF
    END IF
    IF fn$ = "HEX$" THEN
      DIM hexCommas
      hexCommas = 0
      DIM hexI
      DIM hexDepth
      hexDepth = 0
      FOR hexI = 1 TO LEN(args$)
        DIM hexCh
        hexCh = ASC(MID$(args$, hexI, 1))
        IF hexCh = 40 THEN
          hexDepth = hexDepth + 1
        ELSEIF hexCh = 41 THEN
          hexDepth = hexDepth - 1
        ELSEIF hexCh = 44 AND hexDepth = 0 THEN
          hexCommas = hexCommas + 1
        END IF
      NEXT hexI
      IF hexCommas = 1 THEN
        funcName$ = "xb_hex2"
      END IF
    END IF
    IF fn$ = "BIN$" OR fn$ = "OCT$" OR fn$ = "BINB$" OR fn$ = "OCTO$" THEN
      DIM binCommas
      binCommas = 0
      DIM binI
      DIM binDepth
      binDepth = 0
      FOR binI = 1 TO LEN(args$)
        DIM binCh
        binCh = ASC(MID$(args$, binI, 1))
        IF binCh = 40 THEN
          binDepth = binDepth + 1
        ELSEIF binCh = 41 THEN
          binDepth = binDepth - 1
        ELSEIF binCh = 44 AND binDepth = 0 THEN
          binCommas = binCommas + 1
        END IF
      NEXT binI
      IF binCommas = 1 THEN
        IF fn$ = "BIN$" THEN
          funcName$ = "xb_bin2"
        ELSEIF fn$ = "OCT$" THEN
          funcName$ = "xb_oct2"
        ELSEIF fn$ = "BINB$" THEN
          funcName$ = "xb_binb2"
        ELSEIF fn$ = "OCTO$" THEN
          funcName$ = "xb_octo2"
        END IF
      END IF
    END IF
    IF fn$ = "STUFF$" THEN
      DIM stuffCommas
      stuffCommas = 0
      DIM stuffI
      DIM stuffDepth
      stuffDepth = 0
      FOR stuffI = 1 TO LEN(args$)
        DIM stuffCh
        stuffCh = ASC(MID$(args$, stuffI, 1))
        IF stuffCh = 40 THEN
          stuffDepth = stuffDepth + 1
        ELSEIF stuffCh = 41 THEN
          stuffDepth = stuffDepth - 1
        ELSEIF stuffCh = 44 AND stuffDepth = 0 THEN
          stuffCommas = stuffCommas + 1
        END IF
      NEXT stuffI
      IF stuffCommas = 2 THEN
        emittedArgs$ = emittedArgs$ + ", -1"
      END IF
    END IF
    IF fn$ = "RCLIP$" OR fn$ = "LCLIP$" THEN
      DIM clipCommas
      clipCommas = 0
      DIM clipI
      DIM clipDepth
      clipDepth = 0
      FOR clipI = 1 TO LEN(args$)
        DIM clipCh
        clipCh = ASC(MID$(args$, clipI, 1))
        IF clipCh = 40 THEN
          clipDepth = clipDepth + 1
        ELSEIF clipCh = 41 THEN
          clipDepth = clipDepth - 1
        ELSEIF clipCh = 44 AND clipDepth = 0 THEN
          clipCommas = clipCommas + 1
        END IF
      NEXT clipI
      IF clipCommas = 0 THEN
        IF fn$ = "RCLIP$" THEN
          funcName$ = "xb_rclip1"
        ELSE
          funcName$ = "xb_lclip1"
        END IF
      ELSE
        IF fn$ = "RCLIP$" THEN
          funcName$ = "xb_rclip2"
        ELSE
          funcName$ = "xb_lclip2"
        END IF
      END IF
    END IF
    IF fn$ = "MID$" THEN
      DIM midCommas
      midCommas = 0
      DIM midI
      DIM midDepth
      midDepth = 0
      FOR midI = 1 TO LEN(args$)
        DIM midCh
        midCh = ASC(MID$(args$, midI, 1))
        IF midCh = 40 THEN
          midDepth = midDepth + 1
        ELSEIF midCh = 41 THEN
          midDepth = midDepth - 1
        ELSEIF midCh = 44 AND midDepth = 0 THEN
          midCommas = midCommas + 1
        END IF
      NEXT midI
      IF midCommas = 1 THEN
        funcName$ = "xb_mid2"
      END IF
    END IF
    IF fn$ = "STR$" THEN
      IF expr_type$(args$) = "float" THEN
        funcName$ = "xb_str_float"
      END IF
    END IF
    IF fn$ = "FORMAT$" THEN
      DIM fmtSplitPos
      fmtSplitPos = 0
      DIM fmtDepth2
      fmtDepth2 = 0
      DIM fmtI2
      FOR fmtI2 = 1 TO LEN(args$)
        DIM fmtCh2
        fmtCh2 = ASC(MID$(args$, fmtI2, 1))
        IF fmtCh2 = 40 THEN
          fmtDepth2 = fmtDepth2 + 1
        ELSEIF fmtCh2 = 41 THEN
          fmtDepth2 = fmtDepth2 - 1
        ELSEIF fmtCh2 = 44 AND fmtDepth2 = 0 THEN
          fmtSplitPos = fmtI2
          EXIT FOR
        END IF
      NEXT fmtI2
      DIM fmtArg1$
      DIM fmtArg2$
      IF fmtSplitPos > 0 THEN
        fmtArg1$ = trim_spaces$(LEFT$(args$, fmtSplitPos - 1))
        fmtArg2$ = trim_spaces$(MID$(args$, fmtSplitPos + 1, LEN(args$) - fmtSplitPos))
      ELSE
        fmtArg1$ = trim_spaces$(args$)
        fmtArg2$ = ""
      END IF
      DIM fmtE1$
      DIM fmtE2$
      fmtE1$ = emit_expr$(fmtArg1$)
      fmtE2$ = emit_expr$(fmtArg2$)
      DIM fmtArgType$
      fmtArgType$ = expr_type$(fmtArg2$)
      IF fmtArgType$ = "string" THEN
        emit_expr$ = funcName$ + "(" + fmtE1$ + ", " + fmtE2$ + ", 0, 0.0, 0, 1)"
      ELSEIF fmtArgType$ = "float" THEN
        emit_expr$ = funcName$ + "(" + fmtE1$ + ", NULL, 0, " + fmtE2$ + ", 1, 0)"
      ELSE
        emit_expr$ = funcName$ + "(" + fmtE1$ + ", NULL, " + fmtE2$ + ", 0.0, 0, 0)"
      END IF
      RETURN emit_expr$
    END IF
    IF fn$ = "EXTS" OR fn$ = "EXTU" OR fn$ = "CLR" OR fn$ = "SET" OR fn$ = "MAKE" THEN
      DIM bitopCommas
      bitopCommas = 0
      DIM bitopI
      DIM bitopDepth
      bitopDepth = 0
      FOR bitopI = 1 TO LEN(args$)
        DIM bitopCh
        bitopCh = ASC(MID$(args$, bitopI, 1))
        IF bitopCh = 40 THEN
          bitopDepth = bitopDepth + 1
        ELSEIF bitopCh = 41 THEN
          bitopDepth = bitopDepth - 1
        ELSEIF bitopCh = 44 AND bitopDepth = 0 THEN
          bitopCommas = bitopCommas + 1
        END IF
      NEXT bitopI
      IF bitopCommas = 1 THEN
        emittedArgs$ = emittedArgs$ + ", -99999"
      END IF
    END IF
    IF fn$ = "RIGHT$" OR fn$ = "LEFT$" THEN
      DIM rlCommas
      DIM rlI
      DIM rlDepth
      DIM rlCh
      rlCommas = 0
      rlDepth = 0
      FOR rlI = 1 TO LEN(args$)
        rlCh = ASC(MID$(args$, rlI, 1))
        IF rlCh = 40 THEN
          rlDepth = rlDepth + 1
        ELSEIF rlCh = 41 THEN
          rlDepth = rlDepth - 1
        ELSEIF rlCh = 44 AND rlDepth = 0 THEN
          rlCommas = rlCommas + 1
        END IF
      NEXT rlI
      IF rlCommas = 0 THEN
        emittedArgs$ = emittedArgs$ + ", 0"
      END IF
    END IF
    IF INSTR(##funcTypes$, "," + fn$ + ":") = 0 THEN
      IF funcName$ = "xb_user_" + fn$ THEN
        IF RIGHT$(fn$, 1) = "$" THEN
          emit_expr$ = "xb_str(" + CHR$(34) + CHR$(34) + ")"
        ELSE
          emit_expr$ = "0"
        END IF
        RETURN emit_expr$
      END IF
    END IF
    IF INSTR(##funcTypes$, "," + fn$ + ":") > 0 THEN
      ##curCallFn$ = fn$
      emit_expr$ = funcName$ + "(" + emit_args_n$(args$, VAL(arity_of$(fn$))) + ")"
      ##curCallFn$ = ""
    ELSE
      emit_expr$ = funcName$ + "(" + emittedArgs$ + ")"
    END IF
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
      IF (INSTR(##undimmed$, ":" + varName$ + ":") > 0 OR is_xfn_dyn$(varName$) = "1") AND INSTR(##sharedArrays$, ":" + varName$ + ":") = 0 THEN
        emit_expr$ = c_default$(varType$)
        RETURN emit_expr$
      END IF
      t$ = MID$(t$, br + 1, LEN(t$) - br)
      IF RIGHT$(t$, 1) = "]" THEN
        t$ = LEFT$(t$, LEN(t$) - 1)
      END IF
      _ndShape$ = shape_of$(varName$)
      _ndRank = top_part_count(_ndShape$)
      _ndIdxRank = top_part_count(t$)
      IF _ndRank >= 3 AND INSTR(t$, ",") > 0 AND (INSTR(##dynNames$, ":" + varName$ + ":") > 0 OR INSTR(##dynStr$, ":" + varName$ + ":") > 0 OR INSTR(##sharedArrays$, ":" + varName$ + ":") > 0 OR INSTR(##allStrArr$, ":" + varName$ + ":") > 0 OR INSTR(##xstArrays$, ":" + varName$ + ":") > 0) THEN
        IF _ndRank = _ndIdxRank THEN
          emit_expr$ = c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_flat_nd$(t$, _ndShape$) + "]"
        ELSE
          emit_expr$ = c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_expr$(first_comma_part$(t$)) + "]"
        END IF
      ELSEIF INSTR(t$, ",") > 0 AND INSTR(##arr2d$, ":" + varName$ + ":") > 0 AND (INSTR(##dynNames$, ":" + varName$ + ":") > 0 OR INSTR(##dynStr$, ":" + varName$ + ":") > 0 OR INSTR(##sharedArrays$, ":" + varName$ + ":") > 0 OR INSTR(##allStrArr$, ":" + varName$ + ":") > 0 OR INSTR(##xstArrays$, ":" + varName$ + ":") > 0) THEN
        emit_expr$ = c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_flat2d$(t$, "xb_d1_" + sanitize_ident$(varName$) + bd$(varName$)) + "]"
      ELSEIF INSTR(t$, ",") > 0 AND INSTR(##arr2d$, ":" + varName$ + ":") = 0 THEN
        emit_expr$ = c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_expr$(first_comma_part$(t$)) + "]"
      ELSE
        emit_expr$ = c_var_name$(varName$, varType$) + bd$(varName$) + emit_msub$(t$, 0)
      END IF
    ELSE
      emit_expr$ = "0"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 13) = "array_ubound(" THEN
    t$ = MID$(e$, 14, LEN(e$) - 13)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    colonPos = INSTR(t$, ":")
    IF colonPos > 0 THEN
      varType$ = MID$(t$, colonPos + 1, LEN(t$) - colonPos)
      varName$ = LEFT$(t$, colonPos - 1)
    ELSE
      varType$ = "integer"
      varName$ = t$
    END IF
    IF INSTR(##sharedArrays$, ":" + varName$ + ":") > 0 THEN
      emit_expr$ = "(int)xb_ub_" + sanitize_ident$(varName$)
    ELSEIF INSTR(##undimmed$, ":" + varName$ + ":") > 0 OR is_xfn_dyn$(varName$) = "1" THEN
      IF varType$ = "string" THEN
        emit_expr$ = "(xb_len(" + c_var_name$(varName$, varType$) + ") - 1)"
      ELSE
        emit_expr$ = "(-1)"
      END IF
    ELSEIF INSTR(##strDual$, ":" + varName$ + ":") > 0 THEN
      emit_expr$ = "(int)xb_ub_" + sanitize_ident$(varName$) + bd$(varName$)
    ELSEIF INSTR(##allStrArr$, ":" + varName$ + ":") > 0 AND INSTR(##strDual$, ":" + varName$ + ":") = 0 THEN
      emit_expr$ = "(int)xb_ub_" + sanitize_ident$(varName$)
    ELSEIF INSTR(##dynStr$, ":" + varName$ + ":") > 0 THEN
      emit_expr$ = "(int)xb_ub_" + sanitize_ident$(varName$)
    ELSEIF INSTR(##dynNames$, ":" + varName$ + ":") > 0 THEN
      IF INSTR(##byrefDual$, ":" + varName$ + ":") > 0 AND INSTR(CHR$(10) + ##curParams$, CHR$(10) + varName$ + CHR$(10)) > 0 THEN
        emit_expr$ = "(int)(sizeof(" + c_var_name$(varName$, varType$) + bd$(varName$) + ")/sizeof(" + c_var_name$(varName$, varType$) + bd$(varName$) + "[0])-1)"
      ELSE
        emit_expr$ = "(int)xb_ub_" + sanitize_ident$(varName$) + bd$(varName$)
      END IF
    ELSEIF INSTR(##xstArrays$, ":" + varName$ + ":") > 0 AND INSTR(##dynNames$, ":" + varName$ + ":") = 0 AND INSTR(##allStrArr$, ":" + varName$ + ":") = 0 THEN
      emit_expr$ = "(int)xb_ub_" + sanitize_ident$(varName$)
    ELSE
      emit_expr$ = "(int)(sizeof(" + c_var_name$(varName$, varType$) + ")/sizeof(" + c_var_name$(varName$, varType$) + "[0])-1)"
    END IF
    RETURN emit_expr$
  END IF
  IF LEFT$(e$, 8) = "size_of(" THEN
    t$ = MID$(e$, 9, LEN(e$) - 8)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    colonPos = INSTR(t$, ":")
    IF colonPos > 0 THEN
      varType$ = MID$(t$, colonPos + 1, LEN(t$) - colonPos)
      varName$ = LEFT$(t$, colonPos - 1)
    ELSE
      varType$ = "integer"
      varName$ = t$
    END IF
    IF varType$ = "integer" THEN
      emit_expr$ = "(int)(sizeof(" + c_var_name$(varName$, varType$) + ")/sizeof(intptr_t)) * 4"
    ELSE
      emit_expr$ = "(int)(sizeof(" + c_var_name$(varName$, varType$) + ")/sizeof(intptr_t)) * 8"
    END IF
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 13) = "size_of_type(" THEN
    t$ = MID$(e$, 14, LEN(e$) - 13)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    IF t$ = "integer" THEN
      emit_expr$ = "4"
    ELSEIF t$ = "float" THEN
      emit_expr$ = "8"
    ELSE
      emit_expr$ = "8"
    END IF
    RETURN emit_expr$
  END IF
  IF LEFT$(e$, 11) = "label_addr(" THEN
    DIM labelName$
    labelName$ = MID$(e$, 12, LEN(e$) - 11)
    IF RIGHT$(labelName$, 1) = ")" THEN
      labelName$ = LEFT$(labelName$, LEN(labelName$) - 1)
    END IF
    IF INSTR(##nestFns$ + ",", "," + labelName$ + ",") > 0 THEN
      emit_expr$ = "0"
    ELSE
      emit_expr$ = "((intptr_t)&&xb_label_" + labelName$ + ")"
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

  IF LEFT$(e$, 9) = "funcaddr(" THEN
    t$ = MID$(e$, 10, LEN(e$) - 9)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    emit_expr$ = func_id_of$(t$)
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
    emit_expr$ = "xb_shared_" + sanitize_ident$(varName$)
    RETURN emit_expr$
  END IF

  IF LEFT$(e$, 6) = "byref(" THEN
    t$ = MID$(e$, 7, LEN(e$) - 6)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    IF LEFT$(t$, 9) = "shared(" + "##" THEN
      t$ = MID$(t$, 10, LEN(t$) - 10)
      colonPos = INSTR(t$, ":")
      IF colonPos > 0 THEN
        varName$ = LEFT$(t$, colonPos - 1)
      ELSE
        varName$ = t$
      END IF
      emit_expr$ = "&xb_shared_" + sanitize_ident$(varName$)
      RETURN emit_expr$
    END IF
    IF LEFT$(t$, 7) = "symbol(" THEN
      t$ = MID$(t$, 8, LEN(t$) - 7)
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
      ' Mixed-function check: if callee has mixed byref/byval calls,
      ' emit value directly (no &) to match Rust CEmitter (c_emit.rs:659-680).
      IF LEN(##curCallFn$) > 0 AND INSTR(##funcMixed$, "," + ##curCallFn$ + ",") > 0 THEN
        IF RIGHT$(varName$, 1) = "$" OR varType$ = "string" THEN
          emit_expr$ = c_var_name$(varName$, "string")
        ELSE
          emit_expr$ = c_var_name$(varName$, "integer")
        END IF
        RETURN emit_expr$
      END IF
      IF INSTR(##byrefDual$, ":" + varName$ + ":") > 0 THEN
        IF RIGHT$(varName$, 1) = "$" OR varType$ = "string" THEN
          emit_expr$ = "&" + c_var_name$(varName$, "string")
        ELSE
          emit_expr$ = "&" + c_var_name$(varName$, "integer")
        END IF
        RETURN emit_expr$
      ELSEIF RIGHT$(varName$, 1) = "$" OR varType$ = "string" THEN
        emit_expr$ = "&" + c_var_name$(varName$, "string")
        RETURN emit_expr$
      ELSE
        emit_expr$ = "&" + c_var_name$(varName$, "integer")
        RETURN emit_expr$
      END IF
    END IF
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
    IF ch = 34 THEN
      ' Skip string literal (Rust {:?} format: "..." with \" escapes)
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
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

' Emit one or more C subscripts for an array Dim/access/assign. `a$` is the raw
' comma-separated dim/index list from the IR (`d0,d1` or `i0,i1`); commas inside
' parens (a call index like `Add(1, 2)`) are skipped via a paren-depth counter,
' exactly like emit_args$. Each top-level part becomes a native C bracket:
' isDim <> 0 -> `[(EXPR) + 1]` (element count = declared size + 1); else `[EXPR]`.
' A single part reproduces the historical 1-D emission byte-for-byte (selfhost /
' v0.1 are all 1-D); 2+ parts emit a native C multi-dim array `a[i][j]`, matching
' the interpreter's row-major `a[i,j]` semantics.
FUNCTION emit_msub$(a$, isDim)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM out$
  DIM part$
  out$ = ""
  i = 1
  start = 1
  depth = 0
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 THEN
      part$ = trim_spaces$(MID$(a$, start, i - start))
      IF isDim <> 0 THEN
        out$ = out$ + "[(" + emit_expr$(part$) + ") + 1]"
      ELSE
        out$ = out$ + "[" + emit_expr$(part$) + "]"
      END IF
      start = i + 1
    END IF
    i = i + 1
  WEND
  part$ = trim_spaces$(MID$(a$, start, LEN(a$) - start + 1))
  IF isDim <> 0 THEN
    out$ = out$ + "[(" + emit_expr$(part$) + ") + 1]"
  ELSE
    out$ = out$ + "[" + emit_expr$(part$) + "]"
  END IF
  emit_msub$ = out$
END FUNCTION

' Extract the first top-level comma-separated part of `a$` (paren-depth aware).
' Used to drop extra indices on 2-D+ access to a 1-D array (Rust CEmitter's
' 1-D approximation: when the declared dim count != index count, only the first
' index is emitted).
FUNCTION first_comma_part$(a$)
  DIM i
  DIM ch
  DIM depth
  i = 1
  depth = 0
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 THEN
      first_comma_part$ = trim_spaces$(LEFT$(a$, i - 1))
      RETURN first_comma_part$
    END IF
    i = i + 1
  WEND
  first_comma_part$ = a$
END FUNCTION

' Total element count for a multi-dim array Dim: the product `((d0)+1)*((d1)+1)*...`
' over the comma-separated dims (parens skipped like emit_msub$/emit_args$). Used to
' flat-init a native 2-D `char*` array (`((char**)a)[_i] = ""`) since its storage is
' contiguous. Single-dim callers keep the historical 1-D path (never reach here).
FUNCTION emit_mtotal$(a$)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM out$
  DIM part$
  out$ = ""
  i = 1
  start = 1
  depth = 0
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 THEN
      part$ = trim_spaces$(MID$(a$, start, i - start))
      IF LEN(out$) > 0 THEN
        out$ = out$ + " * "
      END IF
      out$ = out$ + "((" + emit_expr$(part$) + ") + 1)"
      start = i + 1
    END IF
    i = i + 1
  WEND
  part$ = trim_spaces$(MID$(a$, start, LEN(a$) - start + 1))
  IF LEN(out$) > 0 THEN
    out$ = out$ + " * "
  END IF
  out$ = out$ + "((" + emit_expr$(part$) + ") + 1)"
  emit_mtotal$ = out$
END FUNCTION

' Row-major flat index for a 2-D dyn-array access/assign: given the raw `i0,i1` index
' list and the runtime 2nd-dim var `d1v$` (`xb_d1_X`), emit `(i0) * (d1v + 1) + (i1)`
' (splits on the first top-level comma; paren-depth aware). 2-D only — higher ranks are
' rare and fall through to the caller's native path.
FUNCTION emit_flat2d$(a$, d1v$)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM i0$
  DIM i1$
  DIM found
  i = 1
  start = 1
  depth = 0
  found = 0
  i0$ = ""
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 AND found = 0 THEN
      i0$ = trim_spaces$(MID$(a$, start, i - start))
      start = i + 1
      found = 1
    END IF
    i = i + 1
  WEND
  i1$ = trim_spaces$(MID$(a$, start, LEN(a$) - start + 1))
  emit_flat2d$ = "(" + emit_expr$(i0$) + ") * (" + d1v$ + " + 1) + (" + emit_expr$(i1$) + ")"
END FUNCTION

' Count top-level comma-separated expressions (paren/string aware).
FUNCTION top_part_count(a$)
  DIM i
  DIM ch
  DIM depth
  DIM n
  IF LEN(a$) = 0 THEN
    top_part_count = 0
    RETURN top_part_count
  END IF
  i = 1
  depth = 0
  n = 1
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 THEN
      n = n + 1
    END IF
    i = i + 1
  WEND
  top_part_count = n
END FUNCTION

' Return one 1-based top-level comma-separated expression.
FUNCTION top_part$(a$, want)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM part
  DIM found$
  i = 1
  depth = 0
  start = 1
  part = 1
  found$ = ""
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 THEN
      IF part = want THEN
        found$ = trim_spaces$(MID$(a$, start, i - start))
        i = LEN(a$) + 1
      ELSE
        part = part + 1
        start = i + 1
      END IF
    END IF
    i = i + 1
  WEND
  IF LEN(found$) = 0 AND part = want THEN
    found$ = trim_spaces$(MID$(a$, start, LEN(a$) - start + 1))
  END IF
  top_part$ = found$
END FUNCTION

' General row-major flat offset. Shape and access ranks must match.
' Mirrors Rust: sum(ik * product((dm)+1 for m>k)).
FUNCTION emit_flat_nd$(indices$, dims$)
  DIM ni
  DIM nd
  DIM k
  DIM j
  DIM out$
  ni = top_part_count(indices$)
  nd = top_part_count(dims$)
  IF ni <> nd OR ni = 0 THEN
    emit_flat_nd$ = emit_expr$(first_comma_part$(indices$))
    RETURN emit_flat_nd$
  END IF
  out$ = ""
  FOR k = 1 TO ni
    IF LEN(out$) > 0 THEN
      out$ = out$ + " + "
    END IF
    out$ = out$ + "(" + emit_expr$(top_part$(indices$, k)) + ")"
    FOR j = k + 1 TO nd
      out$ = out$ + " * ((" + emit_expr$(top_part$(dims$, j)) + ")+1)"
    NEXT j
  NEXT k
  emit_flat_nd$ = "(" + out$ + ")"
END FUNCTION

' The 2nd-dimension size expression of a multi-dim Dim's bracket (`a,b` -> emit b),
' captured into `xb_d1_X` at the DIM for row-major flattening. 2-D (splits on the first
' top-level comma); paren-depth aware.
FUNCTION emit_d1$(a$)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM found
  DIM p2$
  i = 1
  start = 1
  depth = 0
  found = 0
  WHILE i <= LEN(a$)
    ch = ASC(MID$(a$, i, 1))
    IF ch = 34 THEN
      i = i + 1
      WHILE i <= LEN(a$)
        ch = ASC(MID$(a$, i, 1))
        IF ch = 92 THEN
          i = i + 2
        ELSEIF ch = 34 THEN
          EXIT WHILE
        ELSE
          i = i + 1
        END IF
      WEND
    ELSEIF ch = 40 THEN
      depth = depth + 1
    ELSEIF ch = 41 THEN
      depth = depth - 1
    ELSEIF ch = 44 AND depth = 0 AND found = 0 THEN
      start = i + 1
      found = 1
    END IF
    i = i + 1
  WEND
  p2$ = trim_spaces$(MID$(a$, start, LEN(a$) - start + 1))
  emit_d1$ = emit_expr$(p2$)
END FUNCTION

FUNCTION emit_params$(params$)
  DIM result$
  DIM rest$
  DIM commaPos
  DIM param$
  DIM colonPos
  DIM pName$
  DIM pType$
  DIM i
  DIM j
  DIM pCount
  DIM pNames$[32]
  DIM pTypes$[32]
  DIM pIsStr[32]
  DIM isDup
  DIM baseName$
  ' First pass: parse all parameters into arrays for dup detection
  pCount = 0
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
        pNames$[pCount] = LEFT$(param$, colonPos - 1)
        pTypes$[pCount] = MID$(param$, colonPos + 1, LEN(param$) - colonPos)
      ELSE
        pNames$[pCount] = param$
        pTypes$[pCount] = "integer"
      END IF
      pIsStr[pCount] = 0
      IF INSTR(pTypes$[pCount], "string") > 0 THEN
        pIsStr[pCount] = 1
      END IF
      pCount = pCount + 1
    END IF
  WEND
  ' Second pass: emit with original logic + duplicate detection
  result$ = ""
  FOR i = 0 TO pCount - 1
    IF LEN(result$) > 0 THEN
      result$ = result$ + ", "
    END IF
    pName$ = pNames$[i]
    pType$ = pTypes$[i]
    ' Strip [] suffix for array params and emit as pointer
    DIM _isArrParam
    _isArrParam = 0
    IF RIGHT$(pType$, 2) = "[]" THEN
      _isArrParam = 1
      pType$ = LEFT$(pType$, LEN(pType$) - 2)
    END IF
    ' Build base C name — byref-dual and str-dual ARRAY params get _arr suffix.
    ' A scalar param (e.g. line:string) must NOT get _arr even if the name is in
    ' ##byrefDual$ from a different function's array param of the same name.
    IF _isArrParam = 1 AND (INSTR(##byrefDual$, ":" + pName$ + ":") > 0 OR INSTR(##strDual$, ":" + pName$ + ":") > 0) THEN
      baseName$ = c_var_name$(pName$, pType$) + bd$(pName$)
    ELSE
      baseName$ = c_var_name$(pName$, pType$)
    END IF
    ' Check for duplicate (later param with same name and same string-ness)
    isDup = 0
    FOR j = i + 1 TO pCount - 1
      IF pNames$[j] = pName$ AND pIsStr[j] = pIsStr[i] THEN
        isDup = 1
      END IF
    NEXT j
    IF isDup = 1 THEN
      baseName$ = baseName$ + "__dup" + STR$(i)
    END IF
    ' Emit: array params and byref-dual/str-dual ARRAY params get pointer
    IF _isArrParam = 1 THEN
      result$ = result$ + c_type$(pType$) + "* " + baseName$
    ELSEIF INSTR(##byrefWB$, "," + ##curFnName$ + ",") > 0 THEN
      ' CGEN-BYREF-WRITEBACK: all-byref scalar param → pointer with _ref suffix
      result$ = result$ + c_type$(pType$) + "* " + baseName$ + "_ref"
    ELSE
      result$ = result$ + c_type$(pType$) + " " + baseName$
    END IF
  NEXT i
  emit_params$ = result$
END FUNCTION

' --- Undeclared-local hoisting (CGEN-SELFHOST-PARITY) ---
' XBasic auto-declares a scalar on first use; the selfhost tools always DIM
' theirs, but real programs don't. These helpers collect every scalar a function
' USES (`symbol(n:t)` reads, `for`/`assign` targets) minus what it DECLARES (DIM/
' REDIM names, params, the return-value name), and emit a C declaration for the
' remainder at the function prologue - mirroring the Rust CEmitter's
' `emit_hoisted_scalars`. Byte-neutral on the selfhost tools (they have 0
' undeclared locals, so nothing is hoisted); the sync suite gates that invariant.
FUNCTION add_sym$(acc$, nm$, ty$)
  add_sym$ = acc$
  IF LEN(nm$) = 0 THEN
    RETURN add_sym$
  END IF
  IF INSTR(nm$, "[") > 0 THEN
    RETURN add_sym$
  END IF
  DIM want$
  DIM rest2$
  DIM e2$
  DIM nl2
  DIM b2
  DIM en2$
  DIM et2$
  want$ = c_var_name$(nm$, ty$)
  rest2$ = acc$
  WHILE LEN(rest2$) > 0
    nl2 = INSTR(rest2$, CHR$(10))
    IF nl2 = 1 THEN
      rest2$ = MID$(rest2$, 2, LEN(rest2$) - 1)
    ELSEIF nl2 > 1 THEN
      e2$ = LEFT$(rest2$, nl2 - 1)
      rest2$ = MID$(rest2$, nl2 + 1, LEN(rest2$) - nl2)
      b2 = INSTR(e2$, "|")
      IF b2 > 0 THEN
        en2$ = LEFT$(e2$, b2 - 1)
        et2$ = MID$(e2$, b2 + 1, LEN(e2$) - b2)
        IF c_var_name$(en2$, et2$) = want$ THEN
          RETURN add_sym$
        END IF
      END IF
    ELSE
      rest2$ = ""
    END IF
  WEND
  add_sym$ = acc$ + nm$ + "|" + ty$ + CHR$(10)
END FUNCTION

FUNCTION scan_used$(s$, acc$)
  DIM rest$
  DIM p
  DIM nm$
  DIM ty$
  DIM cp
  DIM ep
  DIM out$
  DIM fpart$
  out$ = acc$
  rest$ = s$
  p = INSTR(rest$, "symbol(")
  WHILE p > 0
    rest$ = MID$(rest$, p + 7, LEN(rest$) - p - 6)
    cp = INSTR(rest$, ":")
    ep = INSTR(rest$, ")")
    IF cp > 0 THEN
      IF ep > cp THEN
        nm$ = LEFT$(rest$, cp - 1)
        ty$ = MID$(rest$, cp + 1, ep - cp - 1)
        out$ = add_sym$(out$, nm$, ty$)
      END IF
    END IF
    p = INSTR(rest$, "symbol(")
  WEND
  IF LEFT$(s$, 4) = "for " THEN
    fpart$ = MID$(s$, 5, LEN(s$) - 4)
    ep = INSTR(fpart$, " = ")
    IF ep > 0 THEN
      fpart$ = LEFT$(fpart$, ep - 1)
    END IF
    cp = INSTR(fpart$, ":")
    IF cp > 0 THEN
      nm$ = trim_spaces$(LEFT$(fpart$, cp - 1))
      ty$ = trim_spaces$(MID$(fpart$, cp + 1, LEN(fpart$) - cp))
      out$ = add_sym$(out$, nm$, ty$)
    END IF
  END IF
  IF LEFT$(s$, 7) = "assign " THEN
    fpart$ = MID$(s$, 8, LEN(s$) - 7)
    ep = INSTR(fpart$, " = ")
    IF ep > 0 THEN
      fpart$ = LEFT$(fpart$, ep - 1)
    END IF
    cp = INSTR(fpart$, ":")
    IF cp > 0 THEN
      nm$ = trim_spaces$(LEFT$(fpart$, cp - 1))
      ty$ = trim_spaces$(MID$(fpart$, cp + 1, LEN(fpart$) - cp))
      out$ = add_sym$(out$, nm$, ty$)
    END IF
  END IF
  rest$ = s$
  p = INSTR(rest$, "array_access" + CHR$(40))
  WHILE p > 0
    rest$ = MID$(rest$, p + 13, LEN(rest$) - p - 12)
    cp = INSTR(rest$, ":")
    IF cp > 0 THEN
      nm$ = LEFT$(rest$, cp - 1)
      IF RIGHT$(nm$, 1) = "$" THEN
        bp = INSTR(rest$, "[")
        IF bp > cp THEN
          ty$ = MID$(rest$, cp + 1, bp - cp - 1)
        ELSE
          ty$ = "string"
        END IF
        out$ = add_sym$(out$, nm$, ty$)
      END IF
    END IF
    p = INSTR(rest$, "array_access" + CHR$(40))
  WEND
  IF LEFT$(s$, 12) = "array_assign " THEN
    fpart$ = MID$(s$, 13, LEN(s$) - 12)
    cp = INSTR(fpart$, ":")
    IF cp > 0 THEN
      nm$ = trim_spaces$(LEFT$(fpart$, cp - 1))
      IF RIGHT$(nm$, 1) = "$" THEN
        bp = INSTR(fpart$, "[")
        IF bp > cp THEN
          ty$ = MID$(fpart$, cp + 1, bp - cp - 1)
        ELSE
          ty$ = "string"
        END IF
        out$ = add_sym$(out$, nm$, ty$)
      END IF
    END IF
  END IF
  IF LEFT$(s$, 5) = "swap " THEN
    fpart$ = MID$(s$, 6, LEN(s$) - 5)
    sp = INSTR(fpart$, " ")
    WHILE sp > 0
      part$ = LEFT$(fpart$, sp - 1)
      cp = INSTR(part$, ":")
      IF cp > 0 THEN
        nm$ = trim_spaces$(LEFT$(part$, cp - 1))
        ty$ = trim_spaces$(MID$(part$, cp + 1, LEN(part$) - cp))
        out$ = add_sym$(out$, nm$, ty$)
      END IF
      fpart$ = MID$(fpart$, sp + 1, LEN(fpart$) - sp)
      sp = INSTR(fpart$, " ")
    WEND
    cp = INSTR(fpart$, ":")
    IF cp > 0 THEN
      nm$ = trim_spaces$(LEFT$(fpart$, cp - 1))
      ty$ = trim_spaces$(MID$(fpart$, cp + 1, LEN(fpart$) - cp))
      out$ = add_sym$(out$, nm$, ty$)
    END IF
  END IF
  scan_used$ = out$
END FUNCTION

FUNCTION dim_name$(s$)
  DIM r$
  DIM p
  r$ = s$
  IF LEFT$(r$, 4) = "dim " THEN
    r$ = MID$(r$, 5, LEN(r$) - 4)
  ELSEIF LEFT$(r$, 6) = "redim " THEN
    r$ = MID$(r$, 7, LEN(r$) - 6)
  END IF
  IF LEFT$(r$, 7) = "shared " THEN
    r$ = MID$(r$, 8, LEN(r$) - 7)
  END IF
  p = INSTR(r$, ":")
  IF p > 0 THEN
    r$ = LEFT$(r$, p - 1)
  END IF
  p = INSTR(r$, "[")
  IF p > 0 THEN
    r$ = LEFT$(r$, p - 1)
  END IF
  dim_name$ = trim_spaces$(r$)
END FUNCTION

FUNCTION param_names$(p$)
  DIM out$
  DIM rest$
  DIM cm
  DIM one$
  DIM cp
  DIM nm$
  out$ = ""
  rest$ = p$
  WHILE LEN(rest$) > 0
    cm = INSTR(rest$, ",")
    IF cm > 0 THEN
      one$ = LEFT$(rest$, cm - 1)
      rest$ = MID$(rest$, cm + 1, LEN(rest$) - cm)
    ELSE
      one$ = rest$
      rest$ = ""
    END IF
    one$ = trim_spaces$(one$)
    IF LEFT$(one$, 1) = "@" THEN
      one$ = MID$(one$, 2, LEN(one$) - 1)
    END IF
    cp = INSTR(one$, ":")
    IF cp > 0 THEN
      nm$ = LEFT$(one$, cp - 1)
    ELSE
      nm$ = one$
    END IF
    cp = INSTR(nm$, "[")
    IF cp > 0 THEN
      nm$ = LEFT$(nm$, cp - 1)
    END IF
    nm$ = trim_spaces$(nm$)
    IF LEN(nm$) > 0 THEN
      out$ = out$ + nm$ + CHR$(10)
    END IF
  WEND
  param_names$ = out$
END FUNCTION
' Extract names of ARRAY parameters (type contains []) from a raw IR param list.
' Returns newline-delimited names, matching param_names$ format.
FUNCTION arr_param_names$(p$)
  DIM out$
  DIM rest$
  DIM cm
  DIM one$
  DIM cp
  DIM nm$
  DIM ty$
  out$ = ""
  rest$ = p$
  WHILE LEN(rest$) > 0
    cm = INSTR(rest$, ",")
    IF cm > 0 THEN
      one$ = LEFT$(rest$, cm - 1)
      rest$ = MID$(rest$, cm + 1, LEN(rest$) - cm)
    ELSE
      one$ = rest$
      rest$ = ""
    END IF
    one$ = trim_spaces$(one$)
    IF LEFT$(one$, 1) = "@" THEN
      one$ = MID$(one$, 2, LEN(one$) - 1)
    END IF
    cp = INSTR(one$, ":")
    IF cp > 0 THEN
      nm$ = LEFT$(one$, cp - 1)
      ty$ = MID$(one$, cp + 1, LEN(one$) - cp)
    ELSE
      nm$ = one$
      ty$ = ""
    END IF
    cp = INSTR(nm$, "[")
    IF cp > 0 THEN
      nm$ = LEFT$(nm$, cp - 1)
    END IF
    nm$ = trim_spaces$(nm$)
    IF LEN(nm$) > 0 AND INSTR(ty$, "[]") > 0 THEN
      out$ = out$ + nm$ + CHR$(10)
    END IF
  WEND
  arr_param_names$ = out$
END FUNCTION

' Number of parameters in a raw IR param list (0 for empty), as a decimal string.
' A `$` function is used deliberately: cgen.x forward-references its functions, and
' an integer-returning `name(args)` call before its definition would misparse as an
' array access (`xb_var_name[...]`); the `$` suffix makes it unambiguously a call.
FUNCTION param_count$(p$)
  DIM names$
  DIM i
  DIM n
  names$ = param_names$(p$)
  n = 0
  FOR i = 1 TO LEN(names$)
    IF ASC(MID$(names$, i, 1)) = 10 THEN
      n = n + 1
    END IF
  NEXT i
  param_count$ = STR$(n)
END FUNCTION

' Declared parameter count of a user function (forward-pass table) as a decimal
' string, or "-1" if unknown (a builtin / external - do not reconcile its arity).
FUNCTION arity_of$(fn$)
  DIM p
  DIM rest$
  DIM cp
  p = INSTR(##funcArity$, ":" + fn$ + "=")
  IF p = 0 THEN
    arity_of$ = "-1"
    RETURN arity_of$
  END IF
  rest$ = MID$(##funcArity$, p + LEN(fn$) + 2, LEN(##funcArity$) - p - LEN(fn$) - 1)
  cp = INSTR(rest$, ":")
  IF cp > 0 THEN
    rest$ = LEFT$(rest$, cp - 1)
  END IF
  arity_of$ = rest$
END FUNCTION

' Emit a user call's args reconciled to the callee's declared arity `n`,
' mirroring the interpreter (`params.zip(args)`: extra args dropped unevaluated)
' and the Rust CEmitter's emit_call_args (missing padded with a zero-default).
' Paren-aware split like emit_args$. A matching count reproduces emit_args$ exactly.
FUNCTION emit_args_n$(a$, n)
  DIM i
  DIM ch
  DIM depth
  DIM start
  DIM parts$
  DIM arg$
  DIM emitted
  parts$ = ""
  emitted = 0
  IF LEN(a$) > 0 THEN
    i = 1
    start = 1
    depth = 0
    WHILE i <= LEN(a$)
      ch = ASC(MID$(a$, i, 1))
      IF ch = 34 THEN
        i = i + 1
        WHILE i <= LEN(a$)
          ch = ASC(MID$(a$, i, 1))
          IF ch = 92 THEN
            i = i + 2
          ELSEIF ch = 34 THEN
            EXIT WHILE
          ELSE
            i = i + 1
          END IF
        WEND
      ELSEIF ch = 40 THEN
        depth = depth + 1
      ELSEIF ch = 41 THEN
        depth = depth - 1
      ELSEIF ch = 44 AND depth = 0 THEN
        arg$ = trim_spaces$(MID$(a$, start, i - start))
        IF emitted < n THEN
          IF LEN(parts$) > 0 THEN
            parts$ = parts$ + ", "
          END IF
          parts$ = parts$ + emit_expr$(arg$)
          emitted = emitted + 1
        END IF
        start = i + 1
      END IF
      i = i + 1
    WEND
    arg$ = trim_spaces$(MID$(a$, start, LEN(a$) - start + 1))
    IF emitted < n THEN
      IF LEN(parts$) > 0 THEN
        parts$ = parts$ + ", "
      END IF
      parts$ = parts$ + emit_expr$(arg$)
      emitted = emitted + 1
    END IF
  END IF
  WHILE emitted < n
    IF LEN(parts$) > 0 THEN
      parts$ = parts$ + ", "
    END IF
    parts$ = parts$ + "0"
    emitted = emitted + 1
  WEND
  emit_args_n$ = parts$
END FUNCTION

FUNCTION emit_hoists$(used$, dimmed$)
  DIM out$
  DIM rest$
  DIM nlpos
  DIM entry$
  DIM bar
  DIM nm$
  DIM ty$
  out$ = ""
  rest$ = used$
  WHILE LEN(rest$) > 0
    nlpos = INSTR(rest$, CHR$(10))
    IF nlpos = 1 THEN
      rest$ = MID$(rest$, 2, LEN(rest$) - 1)
    ELSEIF nlpos > 1 THEN
      entry$ = LEFT$(rest$, nlpos - 1)
      rest$ = MID$(rest$, nlpos + 1, LEN(rest$) - nlpos)
      bar = INSTR(entry$, "|")
      IF bar > 0 THEN
        nm$ = LEFT$(entry$, bar - 1)
        ty$ = MID$(entry$, bar + 1, LEN(entry$) - bar)
        IF INSTR(dimmed$, CHR$(10) + nm$ + CHR$(10)) = 0 OR INSTR(##fwdScalars$, ":" + nm$ + ":") > 0 THEN
          IF INSTR(##allStrArr$, ":" + nm$ + ":") > 0 AND INSTR(##strDual$, ":" + nm$ + ":") = 0 AND RIGHT$(nm$, 1) = "$" THEN
            IF INSTR(out$, "char** " + c_var_name$(nm$, "string") + " = 0;") = 0 THEN
              out$ = out$ + "    char** " + c_var_name$(nm$, "string") + " = 0; intptr_t xb_ub_" + sanitize_ident$(nm$) + " = -1;" + CHR$(10)
            END IF
          ELSEIF INSTR(##xstArrays$, ":" + nm$ + ":") > 0 AND INSTR(##allStrArr$, ":" + nm$ + ":") = 0 AND INSTR(##dynNames$, ":" + nm$ + ":") = 0 THEN
            IF INSTR(out$, " xb_var_" + sanitize_ident$(nm$) + " = 0; intptr_t xb_ub_") = 0 THEN
              out$ = out$ + "    intptr_t* xb_var_" + sanitize_ident$(nm$) + " = 0; intptr_t xb_ub_" + sanitize_ident$(nm$) + " = -1;" + CHR$(10)
            END IF
          ELSE
            out$ = out$ + "    " + c_type$(ty$) + " " + c_var_name$(nm$, ty$) + " = " + c_default$(ty$) + ";" + CHR$(10)
          END IF
        END IF
      END IF
    ELSE
      rest$ = ""
    END IF
  WEND
  ' Dyn-array decls (CGEN-DYN-ARRAY): a name DIM'd as both a scalar and a 1D integer
  ' array (##dynNames$) becomes one dyn pointer + ubound, so the two DIMs no longer
  ' emit conflicting C declarations (the scalar DIM emits nothing, the array DIM
  ' calloc's). Byte-neutral on the selfhost tools (they DIM no arrays -> ##dynNames$
  ' empty). Mirrors the Rust CEmitter's dyn-pointer scheme.
  rest$ = dimmed$
  WHILE LEN(rest$) > 0
    nlpos = INSTR(rest$, CHR$(10))
    IF nlpos = 1 THEN
      rest$ = MID$(rest$, 2, LEN(rest$) - 1)
    ELSEIF nlpos > 1 THEN
      entry$ = LEFT$(rest$, nlpos - 1)
      rest$ = MID$(rest$, nlpos + 1, LEN(rest$) - nlpos)
      IF INSTR(##strDual$, ":" + entry$ + ":") > 0 THEN
        IF INSTR(CHR$(10) + ##curParams$, CHR$(10) + entry$ + CHR$(10)) = 0 THEN
          IF INSTR(out$, "    char* " + c_var_name$(entry$, "string") + " = xb_str(" + CHR$(34) + CHR$(34) + "); char** ") = 0 THEN
            out$ = out$ + "    char* " + c_var_name$(entry$, "string") + " = xb_str(" + CHR$(34) + CHR$(34) + "); char** " + c_var_name$(entry$, "string") + "_arr = 0; intptr_t xb_ub_" + sanitize_ident$(entry$) + "_arr = -1;" + CHR$(10)
          END IF
        ELSE
          IF INSTR(out$, "char* " + c_var_name$(entry$, "string") + " = xb_str(" + CHR$(34) + CHR$(34) + "); intptr_t xb_ub_" + sanitize_ident$(entry$) + "_arr") = 0 THEN
            out$ = out$ + "    char* " + c_var_name$(entry$, "string") + " = xb_str(" + CHR$(34) + CHR$(34) + "); intptr_t xb_ub_" + sanitize_ident$(entry$) + "_arr = -1;" + CHR$(10)
          END IF
        END IF
      ELSEIF INSTR(##allStrArr$, ":" + entry$ + ":") > 0 AND INSTR(##dynStr$, ":" + entry$ + ":") = 0 AND INSTR(##strDual$, ":" + entry$ + ":") = 0 AND INSTR(CHR$(10) + ##arrParams$, CHR$(10) + entry$ + CHR$(10)) = 0 THEN
        IF INSTR(out$, "char** " + c_var_name$(entry$, "string") + " = 0;") = 0 THEN
          out$ = out$ + "    char** " + c_var_name$(entry$, "string") + " = 0; intptr_t xb_ub_" + sanitize_ident$(entry$) + " = -1;" + CHR$(10)
        END IF
      ELSEIF INSTR(##allStrArr$, ":" + entry$ + ":") > 0 AND INSTR(##dynStr$, ":" + entry$ + ":") = 0 AND INSTR(##strDual$, ":" + entry$ + ":") = 0 THEN
        IF INSTR(out$, "intptr_t xb_ub_" + sanitize_ident$(entry$) + " = -1;") = 0 THEN
          out$ = out$ + "    intptr_t xb_ub_" + sanitize_ident$(entry$) + " = -1;" + CHR$(10)
        END IF
      ELSEIF INSTR(##dynStr$, ":" + entry$ + ":") > 0 THEN
        IF INSTR(out$, " " + c_var_name$(entry$, "string") + " = 0; intptr_t xb_ub_") = 0 THEN
          out$ = out$ + "    char** " + c_var_name$(entry$, "string") + " = 0; intptr_t xb_ub_" + sanitize_ident$(entry$) + " = -1;" + CHR$(10)
        END IF
      ELSEIF INSTR(##dynNames$, ":" + entry$ + ":") > 0 THEN
        IF INSTR(##byrefDual$, ":" + entry$ + ":") > 0 OR INSTR(##dualUse$, ":" + entry$ + ":") > 0 THEN
          DIM _dt$
          _dt$ = dyn_type$(entry$)
          IF INSTR(out$, "    " + c_type$(_dt$) + " xb_var_" + sanitize_ident$(entry$) + " = " + c_default$(_dt$) + ";" + CHR$(10)) = 0 THEN
            IF INSTR(CHR$(10) + ##curParams$, CHR$(10) + entry$ + CHR$(10)) = 0 THEN
              out$ = out$ + "    " + c_type$(_dt$) + "* xb_var_" + sanitize_ident$(entry$) + "_arr = 0; intptr_t xb_ub_" + sanitize_ident$(entry$) + "_arr = -1;" + CHR$(10)
            ELSE
              out$ = out$ + "    intptr_t xb_ub_" + sanitize_ident$(entry$) + "_arr = -1;" + CHR$(10)
            END IF
            IF INSTR(CHR$(10) + ##curParams$, CHR$(10) + entry$ + CHR$(10)) = 0 OR INSTR(CHR$(10) + ##arrParams$, CHR$(10) + entry$ + CHR$(10)) > 0 THEN
              out$ = out$ + "    " + c_type$(_dt$) + " xb_var_" + sanitize_ident$(entry$) + " = " + c_default$(_dt$) + ";" + CHR$(10)
            END IF
          END IF
        ELSE
          DIM _dt2$
          _dt2$ = dyn_type$(entry$)
          IF INSTR(out$, " xb_var_" + sanitize_ident$(entry$) + " = 0; intptr_t xb_ub_") = 0 THEN
            out$ = out$ + "    " + c_type$(_dt2$) + "* xb_var_" + sanitize_ident$(entry$) + " = 0; intptr_t xb_ub_" + sanitize_ident$(entry$) + " = -1;" + CHR$(10)
          END IF
        END IF
      ELSEIF INSTR(##byrefDual$, ":" + entry$ + ":") > 0 AND (INSTR(CHR$(10) + ##curParams$, CHR$(10) + entry$ + CHR$(10)) = 0 OR INSTR(CHR$(10) + ##arrParams$, CHR$(10) + entry$ + CHR$(10)) > 0) THEN
        ' Array param used as scalar but NOT in ##dynNames$ — emit scalar facet only.
        ' The array facet comes from the parameter (xb_var_X_arr / xb_str_X$_arr).
        ' Skip if entry$ is a scalar param of the current function (no redefinition).
        IF RIGHT$(entry$, 1) = "$" THEN
          IF INSTR(out$, "    char* " + c_var_name$(entry$, "string") + " = xb_str(" + CHR$(34) + CHR$(34) + ");") = 0 THEN
            out$ = out$ + "    char* " + c_var_name$(entry$, "string") + " = xb_str(" + CHR$(34) + CHR$(34) + ");" + CHR$(10)
          END IF
        ELSE
          IF INSTR(out$, "    intptr_t xb_var_" + sanitize_ident$(entry$) + " = 0;") = 0 THEN
            out$ = out$ + "    intptr_t xb_var_" + sanitize_ident$(entry$) + " = 0;" + CHR$(10)
          END IF
        END IF
      ELSEIF INSTR(##xstArrays$, ":" + entry$ + ":") > 0 AND INSTR(##dynNames$, ":" + entry$ + ":") = 0 AND INSTR(##allStrArr$, ":" + entry$ + ":") = 0 AND INSTR(##strDual$, ":" + entry$ + ":") = 0 THEN
        IF INSTR(out$, " xb_var_" + sanitize_ident$(entry$) + " = 0; intptr_t xb_ub_") = 0 THEN
          out$ = out$ + "    intptr_t* xb_var_" + sanitize_ident$(entry$) + " = 0; intptr_t xb_ub_" + sanitize_ident$(entry$) + " = -1;" + CHR$(10)
        END IF
      END IF
      IF INSTR(##arr2d$, ":" + entry$ + ":") > 0 THEN
        IF INSTR(##dynStr$, ":" + entry$ + ":") > 0 OR INSTR(##dynNames$, ":" + entry$ + ":") > 0 OR INSTR(##allStrArr$, ":" + entry$ + ":") > 0 THEN
          IF INSTR(out$, "xb_d1_" + sanitize_ident$(entry$) + bd$(entry$) + " = ") = 0 THEN
            out$ = out$ + "    intptr_t xb_d1_" + sanitize_ident$(entry$) + bd$(entry$) + " = 0;" + CHR$(10)
          END IF
        END IF
      END IF
    ELSE
      rest$ = ""
    END IF
  WEND
  emit_hoists$ = out$
END FUNCTION

' Pre-scan ONE top-level function's body (from `fromPos`, just past its `function `
' line) for the names it DIMs as arrays (`dim X[`/`redim X[`), including any nested
' functions' array DIMs (they share the parent's C scope). Depth-tracked so it stops
' at the matching `end function`. Used to scope dyn-array handling per-function: a dyn
' name used in a function that does NOT DIM it as an array here (a separate top-level
' function's local, e.g. awindow's `text$` DIM'd in XitMain but UBOUND'd in the
' separate XitMainCode) is a distinct undimmed local, matching the interpreter (and
' the Rust CEmitter). Returns a `:name:` set.
FUNCTION fn_array_dims$(s$, fromPos)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM depth
  DIM r$
  DIM bp
  DIM nm$
  DIM cp
  res$ = ""
  p = fromPos
  depth = 1
  WHILE p <= LEN(s$) AND depth > 0
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 9) = "function " THEN
      depth = depth + 1
    ELSEIF ln$ = "end function" THEN
      depth = depth - 1
    ELSEIF LEFT$(ln$, 4) = "dim " OR LEFT$(ln$, 6) = "redim " THEN
      IF LEFT$(ln$, 4) = "dim " THEN
        r$ = MID$(ln$, 5, LEN(ln$) - 4)
      ELSE
        r$ = MID$(ln$, 7, LEN(ln$) - 6)
      END IF
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        cp = INSTR(nm$, ":")
        IF cp > 0 THEN
          nm$ = LEFT$(nm$, cp - 1)
        END IF
        IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
          res$ = res$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
  WEND
  fn_array_dims$ = res$
END FUNCTION

' Current-function multi-dimensional shapes as newline-delimited
' `name|raw-dim-list` entries. Used only for rank 3+ flat arrays; rank-2
' keeps the historical xb_d1_ path byte-for-byte.
FUNCTION fn_array_shapes$(s$, fromPos)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM depth
  DIM r$
  DIM bp
  DIM rb
  DIM nm$
  DIM cp
  DIM dims$
  res$ = ""
  p = fromPos
  depth = 1
  WHILE p <= LEN(s$) AND depth > 0
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 9) = "function " THEN
      depth = depth + 1
    ELSEIF ln$ = "end function" THEN
      depth = depth - 1
    ELSEIF LEFT$(ln$, 4) = "dim " OR LEFT$(ln$, 6) = "redim " THEN
      IF LEFT$(ln$, 4) = "dim " THEN
        r$ = MID$(ln$, 5, LEN(ln$) - 4)
      ELSE
        r$ = MID$(ln$, 7, LEN(ln$) - 6)
      END IF
      IF LEFT$(r$, 7) = "shared " THEN
        r$ = MID$(r$, 8, LEN(r$) - 7)
      END IF
      bp = INSTR(r$, "[")
      rb = INSTR(r$, "]", bp + 1)
      IF bp > 0 AND rb > bp THEN
        dims$ = MID$(r$, bp + 1, rb - bp - 1)
        IF top_part_count(dims$) > 1 THEN
          nm$ = LEFT$(r$, bp - 1)
          cp = INSTR(nm$, ":")
          IF cp > 0 THEN
            nm$ = LEFT$(nm$, cp - 1)
          END IF
          IF INSTR(res$, CHR$(10) + nm$ + "|") = 0 THEN
            res$ = res$ + CHR$(10) + nm$ + "|" + dims$ + CHR$(10)
          END IF
        END IF
      END IF
    END IF
  WEND
  fn_array_shapes$ = res$
END FUNCTION

FUNCTION shape_of$(n$)
  DIM p
  DIM start
  DIM e
  p = INSTR(##curFnShapes$, CHR$(10) + n$ + "|")
  IF p = 0 THEN
    shape_of$ = ""
    RETURN shape_of$
  END IF
  start = p + LEN(n$) + 2
  e = INSTR(##curFnShapes$, CHR$(10), start)
  IF e = 0 THEN
    e = LEN(##curFnShapes$) + 1
  END IF
  shape_of$ = MID$(##curFnShapes$, start, e - start)
END FUNCTION

' True when `n$` is a dyn-array name (##dynStr$/##dynNames$, program-wide) that is
' NOT array-DIM'd in the CURRENT function (##curFnArrays$) while inside a function
' (##inFuncScope). Such a use is a distinct undimmed local in this scope (the array
' lives in another function), so callers fold it to the undimmed default instead of
' emitting the dyn `xb_ub_`/`xb_var_` names that are only declared where it IS DIM'd.
FUNCTION is_xfn_dyn$(n$)
  is_xfn_dyn$ = ""
  IF ##inFuncScope = 1 THEN
    IF INSTR(##curFnArrays$, ":" + n$ + ":") = 0 THEN
      IF INSTR(##dynStr$, ":" + n$ + ":") > 0 OR INSTR(##dynNames$, ":" + n$ + ":") > 0 OR INSTR(##strDual$, ":" + n$ + ":") > 0 THEN
        is_xfn_dyn$ = "1"
      END IF
    END IF
  END IF
END FUNCTION

' Scan the whole IR for dyn-array names: a name DIM'd as BOTH a scalar (`dim X:t`)
' AND a 1-D integer array (`dim X:integer[..]`, no comma) needs the dyn-pointer
' scheme (a scalar decl + a fixed-array decl for the same C name is a cc
' "redefinition"). Returns a `:name:` set. Program-wide (mirrors the Rust CEmitter);
' byte-neutral on the selfhost tools, which DIM no arrays.
' Scan call sites: returns ",FN,FN," for functions with mixed byref/byval calls.
' A function is "mixed" if any call passes a non-byref arg at any position.
' For mixed functions, byref args are emitted as values (no &) to match
' the Rust CEmitter's call-site driven approach (c_emit.rs:115-131).
FUNCTION scan_mixed_byref$(s$)
  DIM msPat$
  DIM msSP
  DIM msCP
  DIM msNS
  DIM msPP
  DIM msFN$
  DIM msD
  DIM msI2
  DIM msC2
  DIM msAA$
  DIM msAP
  DIM msAS
  DIM msAD
  DIM msAC
  DIM msOneArg$
  DIM msHasByval
  DIM msRes$
  msPat$ = "call "
  msSP = 1
  msRes$ = ","
  WHILE msSP <= LEN(s$)
    msCP = INSTR(s$, msPat$, msSP)
    IF msCP = 0 THEN
      EXIT WHILE
    END IF
    msNS = msCP + 5
    msPP = INSTR(s$, CHR$(40), msNS)
    IF msPP = 0 THEN
      msSP = msNS
    ELSE
      msFN$ = MID$(s$, msNS, msPP - msNS)
      msD = 1
      msI2 = msPP + 1
      WHILE msI2 <= LEN(s$) AND msD > 0
        msC2 = ASC(MID$(s$, msI2, 1))
        IF msC2 = 40 THEN
          msD = msD + 1
        ELSEIF msC2 = 41 THEN
          msD = msD - 1
        END IF
        msI2 = msI2 + 1
      WEND
      msAA$ = MID$(s$, msPP + 1, msI2 - msPP - 2)
      IF LEN(msAA$) > 0 THEN
        msAP = 1
        msAS = 1
        msAD = 0
        msHasByval = 0
        WHILE msAP <= LEN(msAA$)
          msAC = ASC(MID$(msAA$, msAP, 1))
          IF msAC = 40 THEN
            msAD = msAD + 1
          ELSEIF msAC = 41 THEN
            msAD = msAD - 1
          ELSEIF msAC = 44 AND msAD = 0 THEN
            msOneArg$ = MID$(msAA$, msAS, msAP - msAS)
            IF LEFT$(msOneArg$, 6) <> "byref" + CHR$(40) THEN
              msHasByval = 1
            END IF
            msAS = msAP + 1
          END IF
          msAP = msAP + 1
        WEND
        msOneArg$ = MID$(msAA$, msAS, LEN(msAA$) - msAS + 1)
        IF LEFT$(msOneArg$, 6) <> "byref" + CHR$(40) THEN
          msHasByval = 1
        END IF
        IF msHasByval = 1 THEN
          IF INSTR(msRes$, "," + msFN$ + ",") = 0 THEN
            msRes$ = msRes$ + msFN$ + ","
          END IF
        END IF
      END IF
      msSP = msI2
    END IF
  WEND
  scan_mixed_byref$ = msRes$
END FUNCTION

' CGEN-BYREF-WRITEBACK: scan for user-defined functions where ALL calls pass ALL
' args as byref (and the function is NOT in ##funcMixed$). Returns ",FN," for each.
' Such functions get pointer params (T *X_ref) with copy-in/copy-out.
FUNCTION scan_byref_wb$(s$)
  DIM wbPat$
  DIM wbSP
  DIM wbCP
  DIM wbNS
  DIM wbPP
  DIM wbFN$
  DIM wbD
  DIM wbI2
  DIM wbC2
  DIM wbAA$
  DIM wbAP
  DIM wbAS
  DIM wbAD
  DIM wbAC
  DIM wbOneArg$
  DIM wbHasByval
  DIM wbRes$
  wbPat$ = "call "
  wbSP = 1
  wbRes$ = ","
  WHILE wbSP <= LEN(s$)
    wbCP = INSTR(s$, wbPat$, wbSP)
    IF wbCP = 0 THEN
      EXIT WHILE
    END IF
    wbNS = wbCP + 5
    wbPP = INSTR(s$, CHR$(40), wbNS)
    IF wbPP = 0 THEN
      wbSP = wbNS
    ELSE
      wbFN$ = MID$(s$, wbNS, wbPP - wbNS)
      ' Only user-defined functions (in ##funcTypes$)
      IF INSTR(##funcTypes$, "," + wbFN$ + ":") > 0 THEN
        wbD = 1
        wbI2 = wbPP + 1
        WHILE wbI2 <= LEN(s$) AND wbD > 0
          wbC2 = ASC(MID$(s$, wbI2, 1))
          IF wbC2 = 40 THEN
            wbD = wbD + 1
          ELSEIF wbC2 = 41 THEN
            wbD = wbD - 1
          END IF
          wbI2 = wbI2 + 1
        WEND
        wbAA$ = MID$(s$, wbPP + 1, wbI2 - wbPP - 2)
        IF LEN(wbAA$) > 0 THEN
          wbAP = 1
          wbAS = 1
          wbAD = 0
          wbHasByval = 0
          WHILE wbAP <= LEN(wbAA$)
            wbAC = ASC(MID$(wbAA$, wbAP, 1))
            IF wbAC = 40 THEN
              wbAD = wbAD + 1
            ELSEIF wbAC = 41 THEN
              wbAD = wbAD - 1
            ELSEIF wbAC = 44 AND wbAD = 0 THEN
              wbOneArg$ = MID$(wbAA$, wbAS, wbAP - wbAS)
              IF LEFT$(wbOneArg$, 6) <> "byref" + CHR$(40) THEN
                wbHasByval = 1
              END IF
              wbAS = wbAP + 1
            END IF
            wbAP = wbAP + 1
          WEND
          wbOneArg$ = MID$(wbAA$, wbAS, LEN(wbAA$) - wbAS + 1)
          IF LEFT$(wbOneArg$, 6) <> "byref" + CHR$(40) THEN
            wbHasByval = 1
          END IF
          IF wbHasByval = 0 THEN
            IF INSTR(##funcMixed$, "," + wbFN$ + ",") = 0 THEN
              IF INSTR(wbRes$, "," + wbFN$ + ",") = 0 THEN
                wbRes$ = wbRes$ + wbFN$ + ","
              END IF
            END IF
          END IF
        END IF
        wbSP = wbI2
      ELSE
        wbSP = wbNS
      END IF
    END IF
  WEND
  scan_byref_wb$ = wbRes$
END FUNCTION

' CGEN-BYREF-WRITEBACK: generate copy-in lines for the current function's
' all-byref scalar params. Stores copy-out lines in ##byrefWBCopy$.
' Returns copy-in lines (each ending with CHR$(10)), or "" if not a WB function.
FUNCTION gen_byref_cio$(params$)
  DIM gioIn$
  DIM gioOut$
  DIM gioRest$
  DIM gioCm
  DIM gioOne$
  DIM gioCp
  DIM gioNm$
  DIM gioTy$
  DIM gioArr$
  DIM gioCName$
  gioIn$ = ""
  gioOut$ = ""
  IF INSTR(##byrefWB$, "," + ##curFnName$ + ",") = 0 THEN
    ##byrefWBCopy$ = ""
    gen_byref_cio$ = ""
    RETURN gen_byref_cio$
  END IF
  gioArr$ = arr_param_names$(params$)
  gioRest$ = params$
  WHILE LEN(gioRest$) > 0
    gioCm = INSTR(gioRest$, ",")
    IF gioCm > 0 THEN
      gioOne$ = LEFT$(gioRest$, gioCm - 1)
      gioRest$ = MID$(gioRest$, gioCm + 1, LEN(gioRest$) - gioCm)
    ELSE
      gioOne$ = gioRest$
      gioRest$ = ""
    END IF
    gioOne$ = trim_spaces$(gioOne$)
    IF LEFT$(gioOne$, 1) = "@" THEN
      gioOne$ = MID$(gioOne$, 2, LEN(gioOne$) - 1)
    END IF
    gioCp = INSTR(gioOne$, ":")
    IF gioCp > 0 THEN
      gioNm$ = LEFT$(gioOne$, gioCp - 1)
      gioTy$ = MID$(gioOne$, gioCp + 1, LEN(gioOne$) - gioCp)
    ELSE
      gioNm$ = gioOne$
      gioTy$ = "integer"
    END IF
    ' Skip array params (type contains [])
    IF INSTR(gioTy$, "[]") = 0 THEN
      ' Skip if name is in arr_param_names (array param without [] in type)
      IF INSTR(gioArr$, gioNm$ + CHR$(10)) = 0 THEN
        gioCName$ = c_var_name$(gioNm$, gioTy$)
        gioIn$ = gioIn$ + "    " + c_type$(gioTy$) + " " + gioCName$ + " = *" + gioCName$ + "_ref;" + CHR$(10)
        gioOut$ = gioOut$ + "    *" + gioCName$ + "_ref = " + gioCName$ + ";" + CHR$(10)
      END IF
    END IF
  WEND
  ##byrefWBCopy$ = gioOut$
  gen_byref_cio$ = gioIn$
END FUNCTION

FUNCTION scan_dyn$(s$)
  DIM sc$
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM cp
  DIM bp
  DIM ty$
  DIM sub$
  DIM nSym$
  DIM nBy$
  DIM before$
  DIM ci
  DIM cch
  DIM cdepth
  DIM ncomma
  sc$ = ""
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      IF INSTR(r$, "[") = 0 THEN
        nm$ = r$
        cp = INSTR(nm$, ":")
        IF cp > 0 THEN
          nm$ = LEFT$(nm$, cp - 1)
        END IF
        sc$ = sc$ + ":" + nm$ + ":"
      END IF
    END IF
  WEND
  ' Also treat a name USED as a bare scalar (`symbol(X)` NOT inside `byref(`) as a
  ' "scalar" facet. Then an array indexed after an `IF X == 0` null-check and used
  ' before its DIM (the nested-fn `Sub[]` dispatch array) becomes ONE dyn pointer
  ' (0 before calloc, non-0 after) rather than a scalar+`_arr` split — the single
  ' pointer matches the interpreter's single-slot semantics and the null check, and
  ' avoids the case-B regression. Needles use CHR$(40) for `(` to dodge the arg
  ' splitter's string-literal blind spot (CGEN-ARGSPLIT-STRLIT).
  nSym$ = "symbol" + CHR$(40)
  nBy$ = "byref" + CHR$(40)
  p = INSTR(s$, nSym$)
  WHILE p > 0
    before$ = ""
    IF p > 6 THEN
      before$ = MID$(s$, p - 6, 6)
    END IF
    IF before$ <> nBy$ THEN
      le = INSTR(MID$(s$, p + 7, LEN(s$) - p - 6), ":")
      IF le > 0 THEN
        nm$ = MID$(s$, p + 7, le - 1)
        IF INSTR(sc$, ":" + nm$ + ":") = 0 THEN
          sc$ = sc$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
    p = INSTR(s$, nSym$, p + 7)
  WEND
  ' Also treat SWAP operands as scalar context: `swap X:type Y:type` uses both
  ' X and Y as scalars. A name DIM'd as an array AND swapped (adatadim) becomes
  ' dual-use, matching the Rust CEmitter's walk_items Swap arm.
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 5) = "swap " THEN
      rest$ = MID$(ln$, 6, LEN(ln$) - 5)
      sp = INSTR(rest$, " ")
      WHILE sp > 0
        part$ = LEFT$(rest$, sp - 1)
        cp = INSTR(part$, ":")
        IF cp > 0 THEN
          part$ = LEFT$(part$, cp - 1)
        END IF
        IF INSTR(sc$, ":" + part$ + ":") = 0 THEN
          sc$ = sc$ + ":" + part$ + ":"
        END IF
        rest$ = MID$(rest$, sp + 1, LEN(rest$) - sp)
        sp = INSTR(rest$, " ")
      WEND
      cp = INSTR(rest$, ":")
      IF cp > 0 THEN
        rest$ = LEFT$(rest$, cp - 1)
      END IF
      IF INSTR(sc$, ":" + rest$ + ":") = 0 THEN
        sc$ = sc$ + ":" + rest$ + ":"
      END IF
    END IF
  WEND
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        ty$ = ""
        cp = INSTR(nm$, ":")
        IF cp > 0 THEN
          ty$ = MID$(nm$, cp + 1, LEN(nm$) - cp)
          nm$ = LEFT$(nm$, cp - 1)
        END IF
        sub$ = MID$(r$, bp + 1, LEN(r$) - bp)
        ncomma = 0
        cdepth = 0
        ci = 1
        WHILE ci <= LEN(sub$)
          cch = ASC(MID$(sub$, ci, 1))
          IF cch = 34 THEN
            ci = ci + 1
            WHILE ci <= LEN(sub$)
              cch = ASC(MID$(sub$, ci, 1))
              IF cch = 92 THEN
                ci = ci + 2
              ELSEIF cch = 34 THEN
                EXIT WHILE
              ELSE
                ci = ci + 1
              END IF
            WEND
          ELSEIF cch = 40 THEN
            cdepth = cdepth + 1
          ELSEIF cch = 41 THEN
            cdepth = cdepth - 1
          ELSEIF cch = 44 AND cdepth = 0 THEN
            ncomma = ncomma + 1
          END IF
          ci = ci + 1
        WEND
        IF ty$ = "integer" OR ty$ = "float" THEN
          IF INSTR(sc$, ":" + nm$ + ":") > 0 THEN
            IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
              res$ = res$ + ":" + nm$ + ":" + ty$ + ":"
            END IF
          END IF
        END IF
      END IF
    END IF
  WEND
  scan_dyn$ = res$
END FUNCTION

' Byref-dual names (CGEN-BYREF-DUAL): a name in ##dynNames$ (dual-DIM scalar+array)
' that is ALSO a parameter of some user function. XBasic passes arrays by-ref, so such
' a name needs the Rust CEmitter's dual-use split: an ARRAY facet `xb_var_X_arr` (the
' by-ref param, a pointer) plus a distinct SCALAR facet `xb_var_X`. Without it the array
' param decl `xb_var_X` collides with the scalar-facet hoist decl (a cc "redefinition").
' The set (dynNames ∩ user-fn-param) is EMPTY on every faithful demo and the selfhost
' tools (verified), so gating the split to it is byte-neutral there.
FUNCTION scan_byref_dual$(s$)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM fp
  DIM cp2
  DIM params$
  DIM names$
  DIM nlp
  DIM nm2$
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 9) = "function " THEN
      fp = INSTR(ln$, "(")
      IF fp > 0 THEN
        params$ = MID$(ln$, fp + 1, LEN(ln$) - fp)
        cp2 = INSTR(params$, ")")
        IF cp2 > 0 THEN
          params$ = LEFT$(params$, cp2 - 1)
        END IF
        ' Parse each param: only ARRAY params (type contains []) that are in
        ' ##dynNames$ qualify for byref-dual. A scalar param like line:string
        ' must NOT trigger byref-dual even if the name is in ##dynNames$.
        DIM _prest$
        DIM _pcm
        DIM _pone$
        DIM _pcp
        DIM _pnm$
        DIM _pty$
        _prest$ = params$
        WHILE LEN(_prest$) > 0
          _pcm = INSTR(_prest$, ",")
          IF _pcm > 0 THEN
            _pone$ = LEFT$(_prest$, _pcm - 1)
            _prest$ = MID$(_prest$, _pcm + 1, LEN(_prest$) - _pcm)
          ELSE
            _pone$ = _prest$
            _prest$ = ""
          END IF
          _pone$ = trim_spaces$(_pone$)
          IF LEFT$(_pone$, 1) = "@" THEN
            _pone$ = MID$(_pone$, 2, LEN(_pone$) - 1)
          END IF
          _pcp = INSTR(_pone$, ":")
          IF _pcp > 0 THEN
            _pnm$ = LEFT$(_pone$, _pcp - 1)
            _pty$ = MID$(_pone$, _pcp + 1, LEN(_pone$) - _pcp)
          ELSE
            _pnm$ = _pone$
            _pty$ = ""
          END IF
          _pcp = INSTR(_pnm$, "[")
          IF _pcp > 0 THEN
            _pnm$ = LEFT$(_pnm$, _pcp - 1)
          END IF
          _pnm$ = trim_spaces$(_pnm$)
          IF LEN(_pnm$) > 0 AND INSTR(_pty$, "[]") > 0 THEN
            ' Condition 1: name is in ##dynNames$ (DIM'd as both scalar+array)
            IF INSTR(##dynNames$, ":" + _pnm$ + ":") > 0 THEN
              IF INSTR(res$, ":" + _pnm$ + ":") = 0 THEN
                res$ = res$ + ":" + _pnm$ + ":"
              END IF
            ' Condition 2: array param also used as scalar (symbol(name:...))
            ' in the IR — needs _arr split even without ##dynNames$.
            ' Only for non-string names (no $ suffix): string names like grid$
            ' appear as byref(symbol(grid$:...)) in call args, which would
            ' falsely match. String dual-use is handled by ##strDual$.
            ELSEIF RIGHT$(_pnm$, 1) <> "$" AND INSTR(s$, "symbol(" + _pnm$ + ":") > 0 THEN
              IF INSTR(res$, ":" + _pnm$ + ":") = 0 THEN
                res$ = res$ + ":" + _pnm$ + ":"
              END IF
            END IF
          END IF
        WEND
      END IF
    END IF
  WEND
  scan_byref_dual$ = res$
END FUNCTION

' General dual-use (CGEN-DUALUSE): a name in ##dynNames$ (dual-DIM scalar+array)
' that appears in BOTH `symbol(name:...)` (scalar context) AND `array_access(name:...`
' (array context) in the IR. Such a name needs the _arr split: scalar facet
' `xb_var_X` + array facet `xb_var_X_arr`, mirroring the Rust CEmitter's
' collect_dual_use. Catches gif's `hash`/`raw` (DIM'd as both, used as both in
' the same expression like hash[hash]). Filtered by ##dynNames$ so pure-array
' names that are also scalar-read (handled by the dyn-pointer) are excluded.
' EMPTY on selfhost tools (no array_access in their IR) -> byte-neutral.
FUNCTION scan_dual_use$(s$)
  DIM scalarSet$
  DIM arraySet$
  DIM res$
  DIM p
  DIM sp
  DIM cp
  DIM nm$
  DIM nc$
  scalarSet$ = ""
  arraySet$ = ""
  p = 1
  WHILE p <= LEN(s$)
    sp = INSTR(s$, "symbol" + CHR$(40), p)
    IF sp = 0 THEN
      p = LEN(s$) + 1
    ELSE
      IF sp + 7 <= LEN(s$) THEN
        nc$ = MID$(s$, sp + 7, 1)
        IF nc$ <> CHR$(34) THEN
          cp = INSTR(s$, ":", sp + 7)
          IF cp > 0 THEN
            nm$ = MID$(s$, sp + 7, cp - sp - 7)
            IF INSTR(scalarSet$, ":" + nm$ + ":") = 0 THEN
              scalarSet$ = scalarSet$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      END IF
      p = sp + 1
    END IF
  WEND
  p = 1
  WHILE p <= LEN(s$)
    sp = INSTR(s$, "array_access" + CHR$(40), p)
    IF sp = 0 THEN
      p = LEN(s$) + 1
    ELSE
      IF sp + 13 <= LEN(s$) THEN
        nc$ = MID$(s$, sp + 13, 1)
        IF nc$ <> CHR$(34) THEN
          cp = INSTR(s$, ":", sp + 13)
          IF cp > 0 THEN
            nm$ = MID$(s$, sp + 13, cp - sp - 13)
            IF INSTR(arraySet$, ":" + nm$ + ":") = 0 THEN
              arraySet$ = arraySet$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      END IF
      p = sp + 1
    END IF
  WEND
  p = 1
  WHILE p <= LEN(s$)
    sp = INSTR(s$, "array_assign ", p)
    IF sp = 0 THEN
      p = LEN(s$) + 1
    ELSE
      IF sp + 13 <= LEN(s$) THEN
        nc$ = MID$(s$, sp + 13, 1)
        IF nc$ <> CHR$(34) THEN
          cp = INSTR(s$, ":", sp + 13)
          IF cp > 0 THEN
            nm$ = MID$(s$, sp + 13, cp - sp - 13)
            IF INSTR(arraySet$, ":" + nm$ + ":") = 0 THEN
              arraySet$ = arraySet$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      END IF
      p = sp + 1
    END IF
  WEND
  ' Also treat SWAP operands as scalar context (matching Rust walk_items Swap arm):
  ' `swap X:type Y:type` makes X and Y scalar-use. A name DIM'd as an array AND
  ' swapped (adatadim) becomes dual-use even without array_access.
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 5) = "swap " THEN
      rest$ = MID$(ln$, 6, LEN(ln$) - 5)
      sp = INSTR(rest$, " ")
      WHILE sp > 0
        part$ = LEFT$(rest$, sp - 1)
        cp = INSTR(part$, ":")
        IF cp > 0 THEN
          part$ = LEFT$(part$, cp - 1)
        END IF
        IF INSTR(scalarSet$, ":" + part$ + ":") = 0 THEN
          scalarSet$ = scalarSet$ + ":" + part$ + ":"
        END IF
        rest$ = MID$(rest$, sp + 1, LEN(rest$) - sp)
        sp = INSTR(rest$, " ")
      WEND
      cp = INSTR(rest$, ":")
      IF cp > 0 THEN
        rest$ = LEFT$(rest$, cp - 1)
      END IF
      IF INSTR(scalarSet$, ":" + rest$ + ":") = 0 THEN
        scalarSet$ = scalarSet$ + ":" + rest$ + ":"
      END IF
    END IF
  WEND
  ' Also treat a sized array DIM as array context (matching Rust array_dims):
  ' `dim X:type[N]` makes X array-use even without array_access (adatadim).
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        cp = INSTR(nm$, ":")
        IF cp > 0 THEN
          nm$ = LEFT$(nm$, cp - 1)
        END IF
        IF INSTR(arraySet$, ":" + nm$ + ":") = 0 THEN
          arraySet$ = arraySet$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
  WEND
  res$ = ""
  p = 1
  WHILE p <= LEN(scalarSet$)
    sp = INSTR(scalarSet$, ":", p + 1)
    IF sp = 0 THEN
      sp = LEN(scalarSet$) + 1
    END IF
    nm$ = MID$(scalarSet$, p + 1, sp - p - 1)
    p = sp + 1
    IF LEN(nm$) > 0 THEN
      IF INSTR(arraySet$, ":" + nm$ + ":") > 0 THEN
        IF INSTR(##dynNames$, ":" + nm$ + ":") > 0 THEN
          IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
            res$ = res$ + ":" + nm$ + ":"
          END IF
        END IF
      END IF
    END IF
  WEND
  scan_dual_use$ = res$
END FUNCTION

' The C-name suffix for the ARRAY facet of a byref-dual name (`_arr`), else "".
' Array-context sites (dyn decl, calloc, access, assign, ubound) append bd$(X);
FUNCTION bd$(n$)
  ' of the current function (##arrParams$) — otherwise a local array in another
  ' function with the same name as a byref-dual param gets wrongly suffixed.
  IF INSTR(##strDual$, ":" + n$ + ":") > 0 OR INSTR(##dualUse$, ":" + n$ + ":") > 0 THEN
    bd$ = "_arr"
  ELSEIF INSTR(##byrefDual$, ":" + n$ + ":") > 0 AND INSTR(CHR$(10) + ##arrParams$, CHR$(10) + n$ + CHR$(10)) > 0 THEN
    bd$ = "_arr"
  ELSE
    bd$ = ""
  END IF
END FUNCTION
' Get the element type of a ##dynNames$ entry. ##dynNames$ entries are
' :name:type: pairs. Returns "integer" if not found or type unknown.
FUNCTION dyn_type$(n$)
  DIM pos
  DIM rest$
  DIM cp
  pos = INSTR(##dynNames$, ":" + n$ + ":")
  IF pos = 0 THEN
    dyn_type$ = "integer"
    RETURN dyn_type$
  END IF
  rest$ = MID$(##dynNames$, pos + LEN(n$) + 2, LEN(##dynNames$) - pos - LEN(n$) - 1)
  cp = INSTR(rest$, ":")
  IF cp > 0 THEN
    dyn_type$ = LEFT$(rest$, cp - 1)
  ELSE
    dyn_type$ = "integer"
  END IF
END FUNCTION

' Scan the IR for UNDIMMED arrays: a name used as an array (`array_access(X:` /
' `array_assign X:`) but never DIM'd as one (`dim X:t[`). The interpreter has no real
' slot for it (an un-DIMmed read → type default; a write → no real store, evaluated
' for side-effects only), so cgen.x folds accesses to the default and assigns to
' `(void)(value)` — mirroring the Rust CEmitter (e.g. abuffer's `func[]` filled by a
' stubbed Xui builtin). Returns a `:name:` set. Needles use CHR$(40) for `(`.
FUNCTION scan_undimmed$(s$)
  DIM ad$
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM bp
  DIM e
  DIM nAcc$
  DIM nAsn$
  ad$ = ""
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        e = INSTR(nm$, ":")
        IF e > 0 THEN
          nm$ = LEFT$(nm$, e - 1)
        END IF
        ad$ = ad$ + ":" + nm$ + ":"
      END IF
    END IF
  WEND
  nAcc$ = "array_access" + CHR$(40)
  nAsn$ = "array_assign "
  p = INSTR(s$, nAcc$)
  WHILE p > 0
    e = INSTR(MID$(s$, p + 13, LEN(s$) - p - 12), ":")
    IF e > 0 THEN
      nm$ = MID$(s$, p + 13, e - 1)
      IF INSTR(ad$, ":" + nm$ + ":") = 0 THEN
        IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
          res$ = res$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
    p = INSTR(s$, nAcc$, p + 13)
  WEND
  p = INSTR(s$, nAsn$)
  WHILE p > 0
    e = INSTR(MID$(s$, p + 13, LEN(s$) - p - 12), ":")
    IF e > 0 THEN
      nm$ = MID$(s$, p + 13, e - 1)
      IF INSTR(ad$, ":" + nm$ + ":") = 0 THEN
        IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
          res$ = res$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
    p = INSTR(s$, nAsn$, p + 13)
  WEND
  nAcc$ = "array_ubound" + CHR$(40)
  p = INSTR(s$, nAcc$)
  WHILE p > 0
    e = INSTR(MID$(s$, p + 13, LEN(s$) - p - 12), ":")
    IF e > 0 THEN
      nm$ = MID$(s$, p + 13, e - 1)
      IF INSTR(ad$, ":" + nm$ + ":") = 0 THEN
        IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
          res$ = res$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
    p = INSTR(s$, nAcc$, p + 13)
  WEND
  scan_undimmed$ = res$
END FUNCTION

' Scan the IR for STRING dyn arrays: a `string` name array-DIM'd 2+ times (a REDIM /
' repeated `dim X$:string[..]` in a function) would emit two fixed `char* X$[n]`
' declarations -> cc "redefinition". Such a name lowers to ONE dyn `char**` pointer
' (calloc per DIM), mirroring the Rust CEmitter (e.g. awindow's `text$[]` menu-label
' array). Not scalar-used (no `_arr` split needed). Returns a `:name:` set.
FUNCTION scan_dynstr$(s$)
  DIM seen$
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM bp
  DIM e
  seen$ = ""
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        e = INSTR(nm$, ":")
        IF e > 0 THEN
          IF MID$(nm$, e + 1, LEN(nm$) - e) = "string" THEN
            nm$ = LEFT$(nm$, e - 1)
            IF INSTR(seen$, ":" + nm$ + ":") > 0 THEN
              IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
                res$ = res$ + ":" + nm$ + ":"
              END IF
            ELSE
              seen$ = seen$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      END IF
    END IF
  WEND
  scan_dynstr$ = res$
END FUNCTION

' All names DIM'd as a string array (`dim X:string[...]`), regardless of how
' many times. Used to distinguish string arrays from scalar strings in
' emit_hoists$ loop 1 when hoisting to functions where the array is used but
' not DIM'd. Returns a `:name:` set.
FUNCTION scan_all_strarr$(s$)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM bp
  DIM e
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        e = INSTR(nm$, ":")
        IF e > 0 THEN
          IF MID$(nm$, e + 1, LEN(nm$) - e) = "string" THEN
            nm$ = LEFT$(nm$, e - 1)
            IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
              res$ = res$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      END IF
    END IF
  WEND
  scan_all_strarr$ = res$
END FUNCTION
' Scan IR for arrays passed to XstQuickSort/XstCopyArray at positions 0-1.
' These arrays need to be dynamic (calloc'd) because the C runtime reallocs
' the index array. Returns `:name:type:` entries.
FUNCTION scan_xst_arrays$(s$)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM args$
  DIM sp
  DIM depth
  DIM i
  DIM c
  DIM startPos
  DIM part$
  DIM sym$
  DIM nm$
  DIM tp$
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 18) = "call XstQuickSort(" OR LEFT$(ln$, 18) = "call XstCopyArray(" THEN
      sp = INSTR(ln$, "(")
      args$ = MID$(ln$, sp + 1, LEN(ln$) - sp - 1)
      depth = 0
      startPos = 1
      FOR i = 1 TO LEN(args$)
        c = ASC(MID$(args$, i, 1))
        IF c = 40 THEN
          depth = depth + 1
        ELSEIF c = 41 THEN
          depth = depth - 1
        ELSEIF c = 44 AND depth = 0 THEN
          part$ = trim_spaces$(MID$(args$, startPos, i - startPos))
          sym$ = extract_byref_sym$(part$)
          sp = INSTR(sym$, ":")
          IF sp > 0 THEN
            nm$ = LEFT$(sym$, sp - 1)
            tp$ = MID$(sym$, sp + 1, LEN(sym$) - sp)
            IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
              res$ = res$ + ":" + nm$ + ":" + tp$ + ":"
            END IF
          END IF
          startPos = i + 1
        END IF
      NEXT i
      part$ = trim_spaces$(MID$(args$, startPos, LEN(args$) - startPos + 1))
      sym$ = extract_byref_sym$(part$)
      sp = INSTR(sym$, ":")
      IF sp > 0 THEN
        nm$ = LEFT$(sym$, sp - 1)
        tp$ = MID$(sym$, sp + 1, LEN(sym$) - sp)
        IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
          res$ = res$ + ":" + nm$ + ":" + tp$ + ":"
        END IF
      END IF
    END IF
  WEND
  scan_xst_arrays$ = res$
END FUNCTION

' STRING scalar+array dual-use (CGEN-STRDUAL): a name DIM'd as BOTH a scalar
' string (`dim X:string`) AND a string array (`dim X:string[N]`) — the string
' analog of the integer ##dynNames$ / byref-dual `_arr` split. The interpreter
' treats X as one variable that becomes an array after the re-DIM; C needs two
' facets: a scalar `char* xb_str_X` and a heap array `char** xb_str_X_arr`. The
' array-context sites get the `_arr` suffix (via bd$); scalar uses stay bare.
' EMPTY on all faithful demos + selfhost tools (they never scalar+array a string)
' -> byte-neutral. Returns a `:name:` set.
FUNCTION scan_str_dual$(s$)
  DIM scal$
  DIM arr$
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM bp
  DIM e
  scal$ = ""
  arr$ = ""
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        e = INSTR(nm$, ":")
        IF e > 0 THEN
          IF MID$(nm$, e + 1, LEN(nm$) - e) = "string" THEN
            nm$ = LEFT$(nm$, e - 1)
            IF INSTR(scal$, ":" + nm$ + ":") > 0 AND INSTR(res$, ":" + nm$ + ":") = 0 THEN
              res$ = res$ + ":" + nm$ + ":"
            END IF
            IF INSTR(arr$, ":" + nm$ + ":") = 0 THEN
              arr$ = arr$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      ELSE
        e = INSTR(r$, ":")
        IF e > 0 THEN
          IF MID$(r$, e + 1, LEN(r$) - e) = "string" THEN
            nm$ = LEFT$(r$, e - 1)
            IF INSTR(arr$, ":" + nm$ + ":") > 0 AND INSTR(res$, ":" + nm$ + ":") = 0 THEN
              res$ = res$ + ":" + nm$ + ":"
            END IF
            IF INSTR(scal$, ":" + nm$ + ":") = 0 THEN
              scal$ = scal$ + ":" + nm$ + ":"
            END IF
          END IF
        END IF
      END IF
    END IF
  WEND
  scan_str_dual$ = res$
END FUNCTION

' Collect names DIM'd as a SHARED array (`dim shared X:t[...]`) into a `:X:` set.
' Shared arrays lower to `dim shared X:t` (scalar form, from `SHARED X[]`) + a sized
' `dim shared X:t[N]` (the actual DIM); the array-form is the reliable marker. Rust's
' CEmitter hoists these to file-scope heap globals (`T* xb_var_X = 0; intptr_t xb_ub_X`)
' shared across every function; cgen.x mirrors that (the selfhost corpus has none).
FUNCTION scan_shared_arr$(s$)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM bp
  DIM e
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 11) = "dim shared " THEN
      r$ = MID$(ln$, 12, LEN(ln$) - 11)
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        nm$ = LEFT$(r$, bp - 1)
        e = INSTR(nm$, ":")
        IF e > 0 THEN
          nm$ = LEFT$(nm$, e - 1)
        END IF
        IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
          res$ = res$ + ":" + nm$ + ":"
        END IF
      END IF
    END IF
  WEND
  scan_shared_arr$ = res$
END FUNCTION

' Collect names DIM'd as a multi-dim array (`dim X:t[a,b...]`, a top-level comma in the
' bracket) into a `:X:` set. Dyn (REDIM'd) multi-dim arrays are stored as a flat 1-D
' heap block (`T* xb_var_X`) and accessed row-major `X[i*(d1+1)+j]`, mirroring the Rust
' CEmitter; the 2nd-dim count `d1` is captured at the DIM into a runtime `xb_d1_X`.
' Fixed multi-dim arrays keep native C `[i][j]`. Byte-neutral on the selfhost tools
' (all their arrays are 1-D). `[`-depth + paren-depth aware so `X[Foo(1,2)]` is 1-D.
FUNCTION scan_arr2d$(s$)
  DIM res$
  DIM p
  DIM le
  DIM ln$
  DIM r$
  DIM nm$
  DIM bp
  DIM e
  DIM q
  DIM ch2
  DIM depth2
  DIM hasComma
  res$ = ""
  p = 1
  WHILE p <= LEN(s$)
    le = INSTR(s$, CHR$(10), p)
    IF le = 0 THEN
      le = LEN(s$) + 1
    END IF
    ln$ = trim_spaces$(MID$(s$, p, le - p))
    p = le + 1
    IF LEFT$(ln$, 4) = "dim " THEN
      r$ = MID$(ln$, 5, LEN(ln$) - 4)
      IF LEFT$(r$, 7) = "shared " THEN
        r$ = MID$(r$, 8, LEN(r$) - 7)
      END IF
      bp = INSTR(r$, "[")
      IF bp > 0 THEN
        hasComma = 0
        depth2 = 0
        q = bp + 1
        WHILE q <= LEN(r$)
          ch2 = ASC(MID$(r$, q, 1))
          IF ch2 = 40 THEN
            depth2 = depth2 + 1
          ELSEIF ch2 = 41 THEN
            depth2 = depth2 - 1
          ELSEIF ch2 = 44 AND depth2 = 0 THEN
            hasComma = 1
          END IF
          q = q + 1
        WEND
        IF hasComma = 1 THEN
          nm$ = LEFT$(r$, bp - 1)
          e = INSTR(nm$, ":")
          IF e > 0 THEN
            nm$ = LEFT$(nm$, e - 1)
          END IF
          IF INSTR(res$, ":" + nm$ + ":") = 0 THEN
            res$ = res$ + ":" + nm$ + ":"
          END IF
        END IF
      END IF
    END IF
  WEND
  scan_arr2d$ = res$
END FUNCTION

' Function address id (CGEN-FUNCADDR): `&Func` / `funcaddr(Func)` is NOT a machine
' address but a synthetic 1-based id in program declaration order, matching the interp
' (eval.rs `function_id`), the Rust CEmitter, and LLVM. `##funcIds$` is the ordered
' `:`-delimited name list built by the forward-decl pass (program declaration order);
' return the 1-based position of `target$`, else "0" (unknown -> 0, like Rust's
' is_unknown_call path). A `##` global so it is reachable from `emit_expr` (the local
' `src$` is not). Byte-neutral on the selfhost tools (they emit 0 funcaddr).
FUNCTION func_id_of$(target$)
  DIM p
  DIM colon
  DIM seg$
  DIM id
  id = 0
  func_id_of$ = "0"
  p = 2
  WHILE p <= LEN(##funcIds$)
    colon = INSTR(##funcIds$, ":", p)
    IF colon = 0 THEN
      colon = LEN(##funcIds$) + 1
    END IF
    seg$ = MID$(##funcIds$, p, colon - p)
    id = id + 1
    IF seg$ = target$ THEN
      func_id_of$ = STR$(id)
      p = LEN(##funcIds$) + 1
    ELSE
      p = colon + 1
    END IF
  WEND
END FUNCTION

' Replace every occurrence of `n$` in `h$` with `r$` (cgen.x has no built-in).
FUNCTION replace$(h$, n$, r$)
  DIM out$
  DIM rest$
  DIM p
  out$ = ""
  rest$ = h$
  IF LEN(n$) = 0 THEN
    replace$ = h$
    RETURN replace$
  END IF
  p = INSTR(rest$, n$)
  WHILE p > 0
    out$ = out$ + LEFT$(rest$, p - 1) + r$
    rest$ = MID$(rest$, p + LEN(n$), LEN(rest$) - p - LEN(n$) + 1)
    p = INSTR(rest$, n$)
  WEND
  out$ = out$ + rest$
  replace$ = out$
END FUNCTION

' Map the identifier chars that are illegal in a C identifier to a distinct suffix,
' mirroring the Rust CEmitter's sanitize_c_ident. `.` (composite-member access, e.g.
' `dog.name`) becomes `_` — this backend flattens composite members to distinct
' locals rather than emitting C structs, so every declaration and use maps the same
' way. The XBasic type suffixes `#!@&%` each map to a distinct `_x` (the type already
' lives in the `xb_var_`/`xb_str_` prefix). `$` is left (a gcc/clang identifier
' extension the runtime already relies on). Byte-neutral on the selfhost tools (they
' use no `.`- or `#!@&%`-bearing names).
FUNCTION sanitize_ident$(n$)
  DIM r$
  r$ = replace$(n$, ".", "_")
  r$ = replace$(r$, "#", "_d")
  r$ = replace$(r$, "!", "_f")
  r$ = replace$(r$, "@", "_a")
  r$ = replace$(r$, "&", "_l")
  r$ = replace$(r$, "%", "_h")
  sanitize_ident$ = r$
END FUNCTION
' Extract name:type from a byref(symbol(X:type)) arg. Returns "name:type" or "".
FUNCTION extract_byref_sym$(arg$)
  DIM r$
  DIM sp
  DIM inner$
  r$ = ""
  IF LEFT$(arg$, 7) = "byref(s" AND INSTR(arg$, "symbol(") > 0 THEN
    sp = INSTR(arg$, "symbol(")
    inner$ = MID$(arg$, sp + 7, LEN(arg$) - sp - 7)
    IF RIGHT$(inner$, 1) = ")" THEN
      inner$ = LEFT$(inner$, LEN(inner$) - 1)
    END IF
    IF RIGHT$(inner$, 1) = ")" THEN
      inner$ = LEFT$(inner$, LEN(inner$) - 1)
    END IF
    r$ = inner$
  END IF
  extract_byref_sym$ = r$
END FUNCTION

' Strip leading zeros from a decimal integer literal (keeping one digit + any
' sign), so `08`/`09` are not emitted as invalid C octal constants.
FUNCTION strip_zeros$(n$)
  DIM neg$
  DIM d$
  DIM i
  ' Only DECIMAL leading zeros are the C-octal hazard. Leave hex (`0x..`/`0X..`)
  ' and binary (`0b..`/`0B..`, a gcc/clang extension the interp + Rust CEmitter
  ' both accept) and anything else (empty) exactly as-is.
  IF INSTR(n$, "x") > 0 THEN
    strip_zeros$ = n$
    RETURN strip_zeros$
  END IF
  IF INSTR(n$, "X") > 0 THEN
    strip_zeros$ = n$
    RETURN strip_zeros$
  END IF
  IF INSTR(n$, "b") > 0 THEN
    strip_zeros$ = n$
    RETURN strip_zeros$
  END IF
  IF INSTR(n$, "B") > 0 THEN
    strip_zeros$ = n$
    RETURN strip_zeros$
  END IF
  neg$ = ""
  d$ = n$
  IF LEFT$(d$, 1) = "-" THEN
    neg$ = "-"
    d$ = MID$(d$, 2, LEN(d$) - 1)
  END IF
  IF LEN(d$) = 0 THEN
    strip_zeros$ = n$
    RETURN strip_zeros$
  END IF
  i = 1
  WHILE i < LEN(d$) AND ASC(MID$(d$, i, 1)) = 48
    i = i + 1
  WEND
  d$ = MID$(d$, i, LEN(d$) - i + 1)
  strip_zeros$ = neg$ + d$
END FUNCTION

' Per-function unique suffix for a gosub-return label. `GOSUB Print` emits a
' `xb_gosub_ret_Print:` label; N gosubs to the same target in one function would
' emit N identical labels (C "redefinition of label"). First occurrence keeps the
' bare name (byte-identical to the historical single-gosub case that the selfhost
' tools use), repeats get `_2`, `_3`, ... `##gosubRetCount$` is reset per function.
FUNCTION gosub_ret_suffix$(name$)
  DIM p
  DIM rest$
  DIM cp
  DIM cnt
  p = INSTR(##gosubRetCount$, ":" + name$ + "=")
  IF p = 0 THEN
    ##gosubRetCount$ = ##gosubRetCount$ + ":" + name$ + "=1:"
    gosub_ret_suffix$ = ""
    RETURN gosub_ret_suffix$
  END IF
  rest$ = MID$(##gosubRetCount$, p + LEN(name$) + 2, LEN(##gosubRetCount$) - p - LEN(name$) - 1)
  cp = INSTR(rest$, ":")
  cnt = VAL(LEFT$(rest$, cp - 1))
  ##gosubRetCount$ = replace$(##gosubRetCount$, ":" + name$ + "=" + STR$(cnt) + ":", ":" + name$ + "=" + STR$(cnt + 1) + ":")
  gosub_ret_suffix$ = "_" + STR$(cnt + 1)
END FUNCTION

' Computed-GOTO prologue (mirrors the Rust CEmitter's emit_computed_goto_prologue).
' A bare `goto *expr` (a `GosubReturn` bare-RETURN dispatch or a `goto_expr`) needs
' an address-of-label somewhere in the function for C to accept the indirect goto.
' `gosub`/`gosub_expr` emit `&&xb_gosub_ret_*` and satisfy it on their own; a
' function whose only computed goto is a bare RETURN or `goto_expr` has none, so we
' emit an unreachable dummy-label block. No-op when the body already emits a
' `&&xb_gosub_ret_` or has no computed goto -> byte-identical on the self-host corpus
' (whose lone bare RETURN sits in a `gosub` function).
FUNCTION computed_goto_prologue$(body$)
  DIM p$
  p$ = ""
  IF INSTR(body$, "xb_gosub_sp") > 0 THEN
    p$ = "    int xb_gosub_base = xb_gosub_sp;" + CHR$(10)
  END IF
  IF INSTR(body$, "goto *") > 0 THEN
    IF INSTR(body$, "&&xb_gosub_ret_") = 0 THEN
      p$ = p$ + "    if (0) { void* _xb_la = &&_xb_cg_dummy; (void)_xb_la; _xb_cg_dummy: (void)0; }" + CHR$(10)
    END IF
  END IF
  computed_goto_prologue$ = p$
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
  DIM atIsFloat
  DIM sp
  DIM expr$
  DIM _ndShape$
  DIM _ndRank
  DIM _ndIdxRank

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
  IF LEFT$(s$, 12) = "program_name" THEN
    emit_stmt$ = ""
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "const" THEN
    ' CG-BYTES: constants emit Rust-style #define lines (XB_CONST_<name>).
    rest$ = MID$(s$, 7, LEN(s$) - 6)
    eqPos = INSTR(rest$, " = ")
    IF eqPos > 0 THEN
      nm$ = LEFT$(rest$, eqPos - 1)
      hashPos = INSTR(nm$, "$$")
      IF hashPos > 0 THEN
        nm$ = MID$(nm$, hashPos + 2, LEN(nm$) - hashPos)
      END IF
      ' Strip an embedded type suffix (`$$XBSysLinux:integer`).
      cp2 = INSTR(nm$, ":")
      IF cp2 > 0 THEN
        nm$ = LEFT$(nm$, cp2 - 1)
      END IF
      val$ = MID$(rest$, eqPos + 3, LEN(rest$) - eqPos)
      vp = INSTR(val$, "(")
      IF LEFT$(val$, 8) = "integer(" OR LEFT$(val$, 6) = "float(" THEN
        val$ = MID$(val$, vp + 1, LEN(val$) - vp - 1)
      END IF
      ' Collected by the const pre-scan below.
    END IF
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
        emit_stmt$ = "    xb_shared_" + sanitize_ident$(varName$) + " = " + emit_expr$(expr$) + ";"
        RETURN emit_stmt$
      END IF
    END IF
    emit_stmt$ = ""
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 3) = "dim" THEN
    rest$ = MID$(s$, 5, LEN(s$) - 4)
    IF LEFT$(rest$, 7) = "shared " THEN
      rest$ = MID$(rest$, 8, LEN(rest$) - 7)
      bracketPos = INSTR(rest$, "[")
      IF bracketPos > 0 THEN
        varName$ = LEFT$(rest$, bracketPos - 1)
        arrSize$ = MID$(rest$, bracketPos + 1, LEN(rest$) - bracketPos - 1)
      ELSE
        varName$ = rest$
        arrSize$ = ""
      END IF
      colonPos = INSTR(varName$, ":")
      IF colonPos > 0 THEN
        varType$ = MID$(varName$, colonPos + 1, LEN(varName$) - colonPos)
        varName$ = LEFT$(varName$, colonPos - 1)
      ELSE
        varType$ = "integer"
      END IF
      IF bracketPos = 0 THEN
        ' Keyword-SHARED scalar: storage is the file-scope xb_shared_ global
        ' (pre-scanned below); a local declaration would shadow it.
        emit_stmt$ = ""
        RETURN emit_stmt$
      END IF
      IF INSTR(##sharedArrays$, ":" + varName$ + ":") > 0 THEN
        IF bracketPos > 0 THEN
          IF INSTR(arrSize$, ",") > 0 AND INSTR(##arr2d$, ":" + varName$ + ":") > 0 THEN
            emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; " + c_var_name$(varName$, varType$) + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + " + 1), sizeof(" + c_type$(varType$) + ")); xb_d1_" + sanitize_ident$(varName$) + " = (" + emit_d1$(arrSize$) + ");"
          ELSE
            cExpr$ = emit_expr$(arrSize$)
            IF varType$ = "string" THEN
              emit_stmt$ = "    " + c_var_name$(varName$, "string") + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= (" + cExpr$ + "); _i++) " + c_var_name$(varName$, "string") + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_ub_" + sanitize_ident$(varName$) + " = (" + cExpr$ + ");"
            ELSE
              emit_stmt$ = "    " + c_var_name$(varName$, varType$) + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(" + c_type$(varType$) + ")); xb_ub_" + sanitize_ident$(varName$) + " = (" + cExpr$ + ");"
            END IF
          END IF
        ELSE
          emit_stmt$ = ""
        END IF
        RETURN emit_stmt$
      END IF
    END IF
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
      IF INSTR(##strDual$, ":" + varName$ + ":") > 0 THEN
        IF INSTR(arrSize$, ",") > 0 THEN
          emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; " + c_var_name$(varName$, "string") + bd$(varName$) + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + "; _i++) " + c_var_name$(varName$, "string") + bd$(varName$) + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_d1_" + sanitize_ident$(varName$) + bd$(varName$) + " = (" + emit_d1$(arrSize$) + ");"
        ELSE
          emit_stmt$ = "    " + c_var_name$(varName$, "string") + bd$(varName$) + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= (" + cExpr$ + "); _i++) " + c_var_name$(varName$, "string") + bd$(varName$) + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = (" + cExpr$ + ");"
        END IF
      ELSEIF INSTR(##dynStr$, ":" + varName$ + ":") > 0 THEN
        IF INSTR(arrSize$, ",") > 0 THEN
          emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; " + c_var_name$(varName$, "string") + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + " + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= xb_ub_" + sanitize_ident$(varName$) + "; _i++) " + c_var_name$(varName$, "string") + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_d1_" + sanitize_ident$(varName$) + " = (" + emit_d1$(arrSize$) + ");"
        ELSE
          emit_stmt$ = "    " + c_var_name$(varName$, "string") + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= (" + cExpr$ + "); _i++) " + c_var_name$(varName$, "string") + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_ub_" + sanitize_ident$(varName$) + " = (" + cExpr$ + ");"
        END IF
      ELSEIF INSTR(##dynNames$, ":" + varName$ + ":") > 0 THEN
        IF INSTR(arrSize$, ",") > 0 THEN
          DIM _d1nc
          DIM _d1ci
          DIM _d1cc
          DIM _d1ch2
          DIM _d1cd
          _d1cc = 0
          _d1cd = 0
          FOR _d1ci = 1 TO LEN(arrSize$)
            _d1ch2 = ASC(MID$(arrSize$, _d1ci, 1))
            IF _d1ch2 = 40 THEN
              _d1cd = _d1cd + 1
            ELSEIF _d1ch2 = 41 THEN
              _d1cd = _d1cd - 1
            ELSEIF _d1ch2 = 44 AND _d1cd = 0 THEN
              _d1cc = _d1cc + 1
            END IF
          NEXT _d1ci
          DIM _dt3$
          _dt3$ = c_type$(dyn_type$(varName$))
          IF _d1cc = 1 THEN
            emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; xb_var_" + sanitize_ident$(varName$) + bd$(varName$) + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " + 1), sizeof(" + _dt3$ + ")); xb_d1_" + sanitize_ident$(varName$) + bd$(varName$) + " = (" + emit_d1$(arrSize$) + ");"
          ELSE
            emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; xb_var_" + sanitize_ident$(varName$) + bd$(varName$) + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " + 1), sizeof(" + _dt3$ + "));"
          END IF
        ELSE
          DIM _dt4$
          _dt4$ = c_type$(dyn_type$(varName$))
          emit_stmt$ = "    xb_var_" + sanitize_ident$(varName$) + bd$(varName$) + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(" + _dt4$ + ")); xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = (" + cExpr$ + ");"
        END IF
      ELSEIF INSTR(##allStrArr$, ":" + varName$ + ":") > 0 AND varType$ = "string" THEN
        IF INSTR(arrSize$, ",") > 0 THEN
          emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; " + c_var_name$(varName$, "string") + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + " + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= xb_ub_" + sanitize_ident$(varName$) + "; _i++) " + c_var_name$(varName$, "string") + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_d1_" + sanitize_ident$(varName$) + " = (" + emit_d1$(arrSize$) + ");"
        ELSE
          emit_stmt$ = "    " + c_var_name$(varName$, "string") + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(char*)); for (intptr_t _i = 0; _i <= (" + cExpr$ + "); _i++) " + c_var_name$(varName$, "string") + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + "); xb_ub_" + sanitize_ident$(varName$) + " = (" + cExpr$ + ");"
        END IF
      ELSEIF varType$ = "string" THEN
        IF INSTR(arrSize$, ",") > 0 THEN
          emit_stmt$ = "    char* " + c_var_name$(varName$, varType$) + emit_msub$(arrSize$, 1) + ";" + CHR$(10) + "    for (intptr_t _i = 0; _i < " + emit_mtotal$(arrSize$) + "; _i++) ((char**)" + c_var_name$(varName$, varType$) + ")[_i] = xb_str(" + CHR$(34) + CHR$(34) + ");"
        ELSE
          emit_stmt$ = "    char* " + c_var_name$(varName$, varType$) + "[(" + cExpr$ + ") + 1];" + CHR$(10) + "    for (int _i = 0; _i < (" + cExpr$ + ") + 1; _i++) " + c_var_name$(varName$, varType$) + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + ");"
        END IF
      ELSEIF INSTR(##xstArrays$, ":" + varName$ + ":") > 0 AND INSTR(##dynNames$, ":" + varName$ + ":") = 0 AND varType$ <> "string" THEN
        IF INSTR(arrSize$, ",") > 0 THEN
          emit_stmt$ = "    xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = " + emit_mtotal$(arrSize$) + " - 1; xb_var_" + sanitize_ident$(varName$) + bd$(varName$) + " = calloc((size_t)(xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " + 1), sizeof(intptr_t)); xb_d1_" + sanitize_ident$(varName$) + bd$(varName$) + " = (" + emit_d1$(arrSize$) + ");"
        ELSE
          emit_stmt$ = "    xb_var_" + sanitize_ident$(varName$) + bd$(varName$) + " = calloc((size_t)((" + cExpr$ + ") + 1), sizeof(intptr_t)); xb_ub_" + sanitize_ident$(varName$) + bd$(varName$) + " = (" + cExpr$ + ");"
        END IF
      ELSE
        emit_stmt$ = "    " + c_type$(varType$) + " " + c_var_name$(varName$, varType$) + emit_msub$(arrSize$, 1) + "; memset(" + c_var_name$(varName$, varType$) + ", 0, sizeof(" + c_var_name$(varName$, varType$) + "));"
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
      IF INSTR(##dynNames$, ":" + varName$ + ":") > 0 OR INSTR(##dynStr$, ":" + varName$ + ":") > 0 OR INSTR(##strDual$, ":" + varName$ + ":") > 0 OR INSTR(##byrefDual$, ":" + varName$ + ":") > 0 OR INSTR(CHR$(10) + ##arrParams$, CHR$(10) + varName$ + CHR$(10)) > 0 THEN
        emit_stmt$ = ""
      ELSEIF varType$ = "string" THEN
        emit_stmt$ = "    char* " + c_var_name$(varName$, varType$) + " = xb_str(" + CHR$(34) + CHR$(34) + ");"
      ELSEIF varType$ = "float" THEN
        emit_stmt$ = "    double " + c_var_name$(varName$, varType$) + " = 0.0;"
      ELSE
        emit_stmt$ = "    intptr_t " + c_var_name$(varName$, varType$) + " = 0;"
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
    spacePos = INSTR(tmp$, "= ", bracketPos + 1)
    right$ = MID$(tmp$, spacePos + 2, LEN(tmp$) - spacePos - 1)
    c2$ = emit_expr$(right$)
    IF (INSTR(##undimmed$, ":" + varName$ + ":") > 0 OR is_xfn_dyn$(varName$) = "1") AND INSTR(##sharedArrays$, ":" + varName$ + ":") = 0 THEN
      emit_stmt$ = "    (void)(" + c2$ + ");"
    ELSE
      _ndShape$ = shape_of$(varName$)
      _ndRank = top_part_count(_ndShape$)
      _ndIdxRank = top_part_count(cExpr$)
      IF _ndRank >= 3 AND INSTR(cExpr$, ",") > 0 AND (INSTR(##dynNames$, ":" + varName$ + ":") > 0 OR INSTR(##dynStr$, ":" + varName$ + ":") > 0 OR INSTR(##sharedArrays$, ":" + varName$ + ":") > 0 OR INSTR(##allStrArr$, ":" + varName$ + ":") > 0 OR INSTR(##xstArrays$, ":" + varName$ + ":") > 0) THEN
        IF _ndRank = _ndIdxRank THEN
          emit_stmt$ = "    " + c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_flat_nd$(cExpr$, _ndShape$) + "] = " + c2$ + ";"
        ELSE
          emit_stmt$ = "    " + c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_expr$(first_comma_part$(cExpr$)) + "] = " + c2$ + ";"
        END IF
      ELSEIF INSTR(cExpr$, ",") > 0 AND INSTR(##arr2d$, ":" + varName$ + ":") > 0 AND (INSTR(##dynNames$, ":" + varName$ + ":") > 0 OR INSTR(##dynStr$, ":" + varName$ + ":") > 0 OR INSTR(##sharedArrays$, ":" + varName$ + ":") > 0 OR INSTR(##allStrArr$, ":" + varName$ + ":") > 0 OR INSTR(##xstArrays$, ":" + varName$ + ":") > 0) THEN
        emit_stmt$ = "    " + c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_flat2d$(cExpr$, "xb_d1_" + sanitize_ident$(varName$) + bd$(varName$)) + "] = " + c2$ + ";"
      ELSEIF INSTR(cExpr$, ",") > 0 AND INSTR(##arr2d$, ":" + varName$ + ":") = 0 THEN
        emit_stmt$ = "    " + c_var_name$(varName$, varType$) + bd$(varName$) + "[" + emit_expr$(first_comma_part$(cExpr$)) + "] = " + c2$ + ";"
      ELSE
        emit_stmt$ = "    " + c_var_name$(varName$, varType$) + bd$(varName$) + emit_msub$(cExpr$, 0) + " = " + c2$ + ";"
      END IF
    END IF
    RETURN emit_stmt$
  END IF
  IF LEFT$(s$, 10) = "mid_assign" THEN
    DIM pipe1
    DIM pipe2
    DIM pipe3
    DIM part1$
    DIM part2$
    DIM part3$
    DIM part4$
    DIM rest2$
    DIM rest3$
    rest$ = MID$(s$, 12, LEN(s$) - 11)
    pipe1 = INSTR(rest$, " | ")
    part1$ = LEFT$(rest$, pipe1 - 1)
    rest2$ = MID$(rest$, pipe1 + 3, LEN(rest$) - pipe1 - 2)
    pipe2 = INSTR(rest2$, " | ")
    IF pipe2 > 0 THEN
      part2$ = LEFT$(rest2$, pipe2 - 1)
      rest3$ = MID$(rest2$, pipe2 + 3, LEN(rest2$) - pipe2 - 2)
      pipe3 = INSTR(rest3$, " | ")
      IF pipe3 > 0 THEN
        part3$ = LEFT$(rest3$, pipe3 - 1)
        part4$ = MID$(rest3$, pipe3 + 3, LEN(rest3$) - pipe3 - 2)
        emit_stmt$ = "    xb_mid_assign(" + emit_expr$(part1$) + ", " + emit_expr$(part2$) + ", " + emit_expr$(part3$) + ", " + emit_expr$(part4$) + ");"
      ELSE
        emit_stmt$ = "    xb_mid_assign(" + emit_expr$(part1$) + ", " + emit_expr$(part2$) + ", -1, " + emit_expr$(rest3$) + ");"
      END IF
    END IF
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 15) = "builtin_assign " THEN
    rest$ = MID$(s$, 16, LEN(s$) - 15)
    eqPos = INSTR(rest$, " = ")
    start$ = MID$(rest$, eqPos + 3, LEN(rest$) - eqPos - 2)
    ' *AT-write lvalue (parser restricts to is_at_builtin): the interpreter has
    ' no real memory, so it no-ops the write and only evaluates the value for
    ' side-effects/errors. Match the Rust CEmitter's (void)(value) — a real
    ' *(T*)(addr)=v would dereference a stub address and crash.
    emit_stmt$ = "    (void)(" + emit_expr$(start$) + ");"
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
    ' CG-BYTES: the Rust CEmitter accumulates each PRINT line into one
    ' byte-string and prints it once - mirror that exactly.
    DIM pi
    DIM pdepth
    DIM pstart
    DIM pitems$
    DIM pseps$
    DIM pch
    DIM pcount
    DIM pw
    DIM pn
    DIM it$
    DIM pt$
    DIM pe$
    DIM pf$
    DIM out$
    DIM k
    DIM ksep$
    DIM karg$
    DIM pstr$
    pi = 1
    pdepth = 0
    pstart = 1
    pitems$ = ""
    pseps$ = ""
    WHILE pi <= LEN(rest$)
      pch = ASC(MID$(rest$, pi, 1))
      IF pch = 34 THEN
        pi = pi + 1
        WHILE pi <= LEN(rest$)
          pch = ASC(MID$(rest$, pi, 1))
          IF pch = 92 THEN
            pi = pi + 2
          ELSEIF pch = 34 THEN
            EXIT WHILE
          ELSE
            pi = pi + 1
          END IF
        WEND
      ELSEIF pch = 40 THEN
        pdepth = pdepth + 1
      ELSEIF pch = 41 THEN
        pdepth = pdepth - 1
      ELSEIF pch = 44 AND pdepth = 0 THEN
        pitems$ = pitems$ + MID$(rest$, pstart, pi - pstart) + CHR$(10)
        pseps$ = pseps$ + "C" + CHR$(10)
        pstart = pi + 1
      ELSEIF pch = 59 AND pdepth = 0 THEN
        pitems$ = pitems$ + MID$(rest$, pstart, pi - pstart) + CHR$(10)
        pseps$ = pseps$ + "S" + CHR$(10)
        pstart = pi + 1
      END IF
      pi = pi + 1
    WEND
    pitems$ = pitems$ + MID$(rest$, pstart, LEN(rest$) - pstart + 1) + CHR$(10)
    pcount = 0
    pw = 1
    WHILE pw <= LEN(pitems$)
      pn = INSTR(pitems$, CHR$(10), pw)
      IF pn = 0 THEN
        pn = LEN(pitems$) + 1
      END IF
      it$ = trim_spaces$(MID$(pitems$, pw, pn - pw))
      IF LEN(it$) > 0 THEN
        pcount = pcount + 1
      END IF
      pw = pn + 1
    WEND
    IF pcount = 0 THEN
      emit_stmt$ = "    printf(" + CHR$(34) + CHR$(92) + "n" + CHR$(34) + ");"
      RETURN emit_stmt$
    END IF
    IF pcount = 1 THEN
      it$ = trim_spaces$(LEFT$(pitems$, INSTR(pitems$, CHR$(10)) - 1))
      IF LEFT$(it$, 9) = "call TAB(" THEN
        karg$ = MID$(it$, 10, LEN(it$) - 10)
        emit_stmt$ = "    { char* _p = xb_str(" + CHR$(34) + CHR$(34) + "); char* _t = xb_tab(xb_len(_p), " + emit_expr$(trim_spaces$(karg$)) + "); _p = xb_concat(_p, _t); xb_print_str(_p); }"
      ELSE
        pt$ = expr_type$(it$)
        pe$ = emit_expr$(it$)
        pf$ = "xb_print_int"
        IF pt$ = "string" THEN
          pf$ = "xb_print_str"
        ELSEIF pt$ = "float" THEN
          pf$ = "xb_print_float"
        ELSEIF pt$ = "giant" THEN
          pf$ = "xb_print_giant"
        END IF
        emit_stmt$ = "    " + pf$ + "(" + pe$ + ");"
      END IF
      RETURN emit_stmt$
    END IF
    it$ = trim_spaces$(LEFT$(pitems$, INSTR(pitems$, CHR$(10)) - 1))
    IF LEFT$(it$, 9) = "call TAB(" THEN
      karg$ = MID$(it$, 10, LEN(it$) - 10)
      out$ = "    { char* _p = xb_tab(0, " + emit_expr$(trim_spaces$(karg$)) + ");"
    ELSE
      pt$ = expr_type$(it$)
      pe$ = emit_expr$(it$)
      pstr$ = pe$
      IF pt$ = "integer" THEN
        pstr$ = "xb_str_num(" + pe$ + ")"
      ELSEIF pt$ = "giant" THEN
        pstr$ = "xb_str_giant(" + pe$ + ")"
      ELSEIF pt$ = "float" THEN
        pstr$ = "xb_str_float(" + pe$ + ")"
      END IF
      out$ = "    { char* _p = " + pstr$ + ";"
    END IF
    k = 2
    pw = INSTR(pitems$, CHR$(10)) + 1
    WHILE k <= pcount
      pn = INSTR(pitems$, CHR$(10), pw)
      IF pn = 0 THEN
        pn = LEN(pitems$) + 1
      END IF
      it$ = trim_spaces$(MID$(pitems$, pw, pn - pw))
      pw = pn + 1
      IF LEN(it$) = 0 THEN
        k = k + 1
      ELSE
        ksep$ = MID$(pseps$, (k - 2) * 2 + 1, 1)
        IF ksep$ = "C" THEN
          out$ = out$ + " _p = xb_concat(_p, xb_str(" + CHR$(34) + CHR$(92) + "t" + CHR$(34) + "));"
        END IF
        IF LEFT$(it$, 9) = "call TAB(" THEN
          karg$ = MID$(it$, 10, LEN(it$) - 10)
          out$ = out$ + " { char* _t = xb_tab(xb_len(_p), " + emit_expr$(trim_spaces$(karg$)) + "); _p = xb_concat(_p, _t); }"
        ELSE
          pt$ = expr_type$(it$)
          pe$ = emit_expr$(it$)
          pstr$ = pe$
          IF pt$ = "integer" THEN
            pstr$ = "xb_str_num(" + pe$ + ")"
          ELSEIF pt$ = "giant" THEN
            pstr$ = "xb_str_giant(" + pe$ + ")"
          ELSEIF pt$ = "float" THEN
            pstr$ = "xb_str_float(" + pe$ + ")"
          END IF
          out$ = out$ + " { char* _t = " + pstr$ + "; _p = xb_concat(_p, _t); }"
        END IF
        k = k + 1
      END IF
    WEND
    out$ = out$ + " xb_print_str(_p); }"
    emit_stmt$ = out$
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
    emit_stmt$ = "    do {" + CHR$(10) + "    if (!(" + cExpr$ + ")) break;"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 9) = "do until " THEN
    rest$ = MID$(s$, 10, LEN(s$) - 9)
    cExpr$ = emit_expr$(rest$)
    emit_stmt$ = "    do {" + CHR$(10) + "    if (" + cExpr$ + ") break;"
    RETURN emit_stmt$
  END IF

  IF s$ = "loop" THEN
    emit_stmt$ = "    } while (1);"
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
    emit_stmt$ = ##byrefWBCopy$ + "    return " + cExpr$ + ";"
    RETURN emit_stmt$
  END IF

  IF s$ = "return" THEN
    emit_stmt$ = ##byrefWBCopy$ + "    return 0;"
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
    IF fn$ = "XstQuickSort" OR fn$ = "XstCopyArray" THEN
      DIM xsParts$
      DIM xsI
      DIM xsCh
      DIM xsDepth
      DIM xsStart
      DIM xsCount
      DIM xsArgs$[16]
      DIM xsSym$
      DIM xsSp
      DIM xsN0$
      DIM xsT0$
      DIM xsN1$
      DIM xsT1$
      DIM xsEt0$
      DIM xsEt1$
      xsN0$ = ""
      xsT0$ = ""
      xsN1$ = ""
      xsT1$ = ""
      xsDepth = 0
      xsStart = 1
      xsCount = 0
      FOR xsI = 1 TO LEN(args$)
        xsCh = ASC(MID$(args$, xsI, 1))
        IF xsCh = 40 THEN
          xsDepth = xsDepth + 1
        ELSEIF xsCh = 41 THEN
          xsDepth = xsDepth - 1
        ELSEIF xsCh = 44 AND xsDepth = 0 THEN
          xsArgs$[xsCount] = trim_spaces$(MID$(args$, xsStart, xsI - xsStart))
          xsCount = xsCount + 1
          xsStart = xsI + 1
        END IF
      NEXT xsI
      xsArgs$[xsCount] = trim_spaces$(MID$(args$, xsStart, LEN(args$) - xsStart + 1))
      xsCount = xsCount + 1
      IF xsCount >= 1 THEN
        xsSym$ = extract_byref_sym$(xsArgs$[0])
        xsSp = INSTR(xsSym$, ":")
        IF xsSp > 0 THEN
          xsN0$ = LEFT$(xsSym$, xsSp - 1)
          xsT0$ = MID$(xsSym$, xsSp + 1, LEN(xsSym$) - xsSp)
        END IF
      END IF
      IF xsCount >= 2 THEN
        xsSym$ = extract_byref_sym$(xsArgs$[1])
        xsSp = INSTR(xsSym$, ":")
        IF xsSp > 0 THEN
          xsN1$ = LEFT$(xsSym$, xsSp - 1)
          xsT1$ = MID$(xsSym$, xsSp + 1, LEN(xsSym$) - xsSp)
        END IF
      END IF
      xsEt0$ = "0"
      IF xsT0$ = "string" THEN xsEt0$ = "2"
      IF xsT0$ = "float" THEN xsEt0$ = "1"
      xsEt1$ = "0"
      IF xsT1$ = "string" THEN xsEt1$ = "2"
      IF xsT1$ = "float" THEN xsEt1$ = "1"
      IF fn$ = "XstQuickSort" AND xsCount = 5 THEN
        DIM xsLen0$
        DIM xsIdxData$
        DIM xsIdxUb$
        xsLen0$ = "(xb_ub_" + sanitize_ident$(xsN0$) + " + 1)"
        xsIdxData$ = "xb_var_" + sanitize_ident$(xsN1$)
        xsIdxUb$ = "xb_ub_" + sanitize_ident$(xsN1$)
        emit_stmt$ = "    xb_quicksort((void*)" + c_var_name$(xsN0$, xsT0$) + ", " + xsEt0$ + ", " + xsLen0$ + ", (intptr_t**)&" + xsIdxData$ + ", (intptr_t*)&" + xsIdxUb$ + ", (intptr_t)(" + emit_expr$(xsArgs$[2]) + "), (intptr_t)(" + emit_expr$(xsArgs$[3]) + "), (intptr_t)(" + emit_expr$(xsArgs$[4]) + "));"
        RETURN emit_stmt$
      END IF
      IF fn$ = "XstCopyArray" AND xsCount = 2 THEN
        DIM xsSrcLen$
        DIM xsDstData$
        DIM xsDstUb$
        xsSrcLen$ = "(xb_ub_" + sanitize_ident$(xsN0$) + " + 1)"
        xsDstData$ = c_var_name$(xsN1$, xsT1$)
        xsDstUb$ = "xb_ub_" + sanitize_ident$(xsN1$)
        emit_stmt$ = "    xb_copyarray((void*)" + c_var_name$(xsN0$, xsT0$) + ", " + xsSrcLen$ + ", " + xsEt0$ + ", (void**)&" + xsDstData$ + ", &" + xsDstUb$ + ");"
        RETURN emit_stmt$
      END IF
      emit_stmt$ = ""
      RETURN emit_stmt$
    END IF
    IF fn$ = "WriteFile" OR fn$ = "ReadFile" THEN
      ' RT-KERNEL32 statement-position call: reuse the expression arm.
      DIM k32Expr$
      DIM k32Save$
      k32Save$ = MID$(s$, 6, LEN(s$) - 5)
      k32Expr$ = emit_expr$("call " + k32Save$)
      IF LEN(k32Expr$) > 0 THEN
        emit_stmt$ = "    " + k32Expr$ + ";"
      ELSE
        emit_stmt$ = ""
      END IF
      RETURN emit_stmt$
    END IF
    IF fn$ = "XgrProcessMessages" THEN
      emit_stmt$ = "    xb_xgr_process_messages(" + emit_expr$(args$) + ");"
      RETURN emit_stmt$
    END IF
    IF INSTR(##funcTypes$, "," + fn$ + ":") = 0 THEN
      IF c_func_name$(fn$) = "xb_user_" + fn$ THEN
        emit_stmt$ = ""
        RETURN emit_stmt$
      END IF
    END IF
    IF INSTR(##funcTypes$, "," + fn$ + ":") > 0 THEN
      ##curCallFn$ = fn$
      emit_stmt$ = "    " + c_func_name$(fn$) + "(" + emit_args_n$(args$, VAL(arity_of$(fn$))) + ");"
      ##curCallFn$ = ""
    ELSE
      ##curCallFn$ = fn$
      emit_stmt$ = "    " + c_func_name$(fn$) + "(" + emit_args$(args$) + ");"
      ##curCallFn$ = ""
    END IF
    RETURN emit_stmt$
  END IF

  IF s$ = "exit_loop" THEN
    emit_stmt$ = "    break;"
    RETURN emit_stmt$
  END IF

  IF s$ = "exit_select" THEN
    DIM esId
    esId = 0
    DIM esStackLen
    esStackLen = LEN(##selectExitStack$)
    IF esStackLen >= 2 THEN
      DIM esLastComma
      esLastComma = esStackLen
      WHILE esLastComma > 0 AND ASC(MID$(##selectExitStack$, esLastComma, 1)) <> 44
        esLastComma = esLastComma - 1
      WEND
      IF esLastComma > 1 THEN
        esId = ASC(MID$(##selectExitStack$, esLastComma - 1, 1))
      END IF
    END IF
    emit_stmt$ = "    goto _exit_sel_" + STR$(esId - 1) + ";"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 12) = "select_case " THEN
    rest$ = MID$(s$, 13, LEN(s$) - 12)
    cExpr$ = emit_expr$(rest$)
    ##selectState = 1
    ##selectExpr$ = cExpr$
    IF INSTR(rest$, ":string") > 0 OR INSTR(rest$, "$:") > 0 OR INSTR(rest$, "$,") > 0 OR INSTR(rest$, "$)") > 0 THEN
      ##selectIsString = 1
    ELSE
      ##selectIsString = 0
    END IF
    ##selectBraces = 0
    ##selectExitCount = ##selectExitCount + 1
    ##selectExitStack$ = ##selectExitStack$ + CHR$(##selectExitCount) + ","
    ' CG-BYTES: Rust CEmitter shape - saved _sel, if/else-if chain, 0-based
    ' exit ids. Case bodies stream via add_lead (their IR lead supplies +4).
    selTy$ = "intptr_t"
    IF ##selectIsString = 1 THEN
      selTy$ = "char*"
    END IF
    ##selLead$ = ##curLead$
    _sl$ = ""
    FOR _si = 1 TO VAL(##curLead$)
      _sl$ = _sl$ + " "
    NEXT _si
    ##noLead$ = "1"
    emit_stmt$ = _sl$ + "{" + CHR$(10) + _sl$ + "    " + selTy$ + " _sel = " + cExpr$ + ";"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "case " AND ##selectState > 0 THEN
    rest$ = MID$(s$, 6, LEN(s$) - 5)
    DIM caseConds$
    DIM casePos
    DIM caseStart
    DIM caseDepth
    DIM caseCh
    DIM caseArg$
    DIM caseLast$
    caseConds$ = ""
    casePos = 1
    caseStart = 1
    caseDepth = 0
    WHILE casePos <= LEN(rest$)
      caseCh = ASC(MID$(rest$, casePos, 1))
      IF caseCh = 40 THEN
        caseDepth = caseDepth + 1
      ELSEIF caseCh = 41 THEN
        caseDepth = caseDepth - 1
      ELSEIF caseCh = 44 AND caseDepth = 0 THEN
        caseArg$ = MID$(rest$, caseStart, casePos - caseStart)
        IF LEN(caseConds$) > 0 THEN
          caseConds$ = caseConds$ + " || "
        END IF
        IF ##selectIsString = 1 THEN
          caseConds$ = caseConds$ + "(xb_scmp(_sel, " + emit_expr$(trim_spaces$(caseArg$)) + ") == 0)"
        ELSE
          caseConds$ = caseConds$ + "_sel == " + emit_expr$(trim_spaces$(caseArg$))
        END IF
        caseStart = casePos + 1
      END IF
      casePos = casePos + 1
    WEND
    IF caseStart <= LEN(rest$) THEN
      caseLast$ = MID$(rest$, caseStart, LEN(rest$) - caseStart + 1)
      IF LEN(caseConds$) > 0 THEN
        caseConds$ = caseConds$ + " || "
      END IF
      IF ##selectIsString = 1 THEN
        caseConds$ = caseConds$ + "(xb_scmp(_sel, " + emit_expr$(trim_spaces$(caseLast$)) + ") == 0)"
      ELSE
        caseConds$ = caseConds$ + "_sel == " + emit_expr$(trim_spaces$(caseLast$))
      END IF
    END IF
    _sl$ = ""
    FOR _si = 1 TO VAL(##selLead$) + 4
      _sl$ = _sl$ + " "
    NEXT _si
    ##noLead$ = "1"
    IF ##selectState = 1 THEN
      emit_stmt$ = _sl$ + "if (" + caseConds$ + ") {"
    ELSE
      emit_stmt$ = _sl$ + "}" + CHR$(10) + _sl$ + "else if (" + caseConds$ + ") {"
    END IF
    ##selectState = 2
    ##selectBraces = ##selectBraces + 1
    RETURN emit_stmt$
  END IF

  IF s$ = "case_else" AND ##selectState > 0 THEN
    _sl$ = ""
    FOR _si = 1 TO VAL(##selLead$) + 4
      _sl$ = _sl$ + " "
    NEXT _si
    ##noLead$ = "1"
    emit_stmt$ = _sl$ + "}" + CHR$(10) + _sl$ + "else {"
    ##selectBraces = ##selectBraces + 1
    RETURN emit_stmt$
  END IF

  IF s$ = "end_select" THEN
    ##selectState = 0
    ##selectExpr$ = ""
    ##selectIsString = 0
    ##selectBraces = 0
    DIM selId
    selId = 0
    DIM stackLen
    stackLen = LEN(##selectExitStack$)
    IF stackLen >= 2 THEN
      DIM lastComma
      lastComma = stackLen
      WHILE lastComma > 0 AND ASC(MID$(##selectExitStack$, lastComma, 1)) <> 44
        lastComma = lastComma - 1
      WEND
      IF lastComma > 1 THEN
        selId = ASC(MID$(##selectExitStack$, lastComma - 1, 1))
        ##selectExitStack$ = LEFT$(##selectExitStack$, lastComma - 2)
      END IF
    END IF
    _sl$ = ""
    FOR _si = 1 TO VAL(##selLead$) + 4
      _sl$ = _sl$ + " "
    NEXT _si
    _sl2$ = ""
    FOR _si = 1 TO VAL(##curLead$)
      _sl2$ = _sl2$ + " "
    NEXT _si
    emit_stmt$ = _sl$ + "}" + CHR$(10) + _sl$ + "_exit_sel_" + STR$(selId - 1) + ":;" + CHR$(10) + _sl2$ + "}"
    ##selLead$ = ""
    ##selLead$ = ""
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "swap " THEN
    rest$ = MID$(s$, 6, LEN(s$) - 5)
    sp = INSTR(rest$, " ")
    IF sp > 0 THEN
      DIM swapLeft$
      swapLeft$ = LEFT$(rest$, sp - 1)
      DIM swapRight$
      swapRight$ = MID$(rest$, sp + 1, LEN(rest$) - sp)
      DIM swapLName$
      DIM swapLType$
      colonPos = INSTR(swapLeft$, ":")
      IF colonPos > 0 THEN
        swapLName$ = LEFT$(swapLeft$, colonPos - 1)
        swapLType$ = MID$(swapLeft$, colonPos + 1, LEN(swapLeft$) - colonPos)
      ELSE
        swapLName$ = swapLeft$
        swapLType$ = "integer"
      END IF
      DIM swapRName$
      DIM swapRType$
      colonPos = INSTR(swapRight$, ":")
      IF colonPos > 0 THEN
        swapRName$ = LEFT$(swapRight$, colonPos - 1)
        swapRType$ = MID$(swapRight$, colonPos + 1, LEN(swapRight$) - colonPos)
      ELSE
        swapRName$ = swapRight$
        swapRType$ = "integer"
      END IF
      DIM swapCType$
      swapCType$ = c_type$(swapLType$)
      _swT$ = "_swap_tmp_" + c_var_name$(swapLName$, swapLType$)
      emit_stmt$ = "    { " + swapCType$ + " " + _swT$ + " = " + c_var_name$(swapLName$, swapLType$) + "; " + c_var_name$(swapLName$, swapLType$) + " = " + c_var_name$(swapRName$, swapRType$) + "; " + c_var_name$(swapRName$, swapRType$) + " = " + _swT$ + "; }"
    ELSE
      emit_stmt$ = ""
    END IF
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "read " THEN
    rest$ = MID$(s$, 6, LEN(s$) - 5)
    DIM readParts$
    DIM readIdx
    readIdx = 1
    DO
      DIM commaPos
      commaPos = INSTR(rest$, ",", readIdx)
      IF commaPos = 0 THEN
        readParts$ = MID$(rest$, readIdx, LEN(rest$) - readIdx + 1)
      ELSE
        readParts$ = MID$(rest$, readIdx, commaPos - readIdx)
      END IF
      DIM rpName$
      DIM rpType$
      colonPos = INSTR(readParts$, ":")
      IF colonPos > 0 THEN
        rpName$ = LEFT$(readParts$, colonPos - 1)
        rpType$ = MID$(readParts$, colonPos + 1, LEN(readParts$) - colonPos)
      ELSE
        rpName$ = readParts$
        rpType$ = "integer"
      END IF
      IF rpType$ = "integer" THEN
        emit_stmt$ = emit_stmt$ + "  xb_read_int(&" + c_var_name$(rpName$, rpType$) + ");" + CHR$(10)
      ELSEIF rpType$ = "float" THEN
        emit_stmt$ = emit_stmt$ + "  xb_read_float(&" + c_var_name$(rpName$, rpType$) + ");" + CHR$(10)
      ELSEIF rpType$ = "string" THEN
        emit_stmt$ = emit_stmt$ + "  " + c_var_name$(rpName$, rpType$) + " = xb_read_str();" + CHR$(10)
      END IF
      IF commaPos = 0 THEN
        EXIT DO
      END IF
      readIdx = commaPos + 2
    LOOP
    RETURN emit_stmt$
  END IF

  IF s$ = "restore" OR LEFT$(s$, 8) = "restore " THEN
    emit_stmt$ = "  xb_restore(0);"
    RETURN emit_stmt$
  END IF

  IF s$ = "stop" THEN
    emit_stmt$ = "    exit(0);"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 6) = "gosub " THEN
    DIM gosubName$
    gosubName$ = MID$(s$, 7, LEN(s$) - 6)
    DIM grSuf$
    grSuf$ = gosub_ret_suffix$(gosubName$)
    emit_stmt$ = "    xb_gosub_stack[xb_gosub_sp++] = &&xb_gosub_ret_" + gosubName$ + grSuf$ + "; goto xb_label_" + gosubName$ + ";" + CHR$(10) + "xb_gosub_ret_" + gosubName$ + grSuf$ + ":"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 6) = "label " THEN
    DIM labelName$
    labelName$ = MID$(s$, 7, LEN(s$) - 6)
    emit_stmt$ = "xb_label_" + labelName$ + ":"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 5) = "goto " THEN
    DIM gotoName$
    gotoName$ = MID$(s$, 6, LEN(s$) - 5)
    emit_stmt$ = "    goto xb_label_" + gotoName$ + ";"
    RETURN emit_stmt$
  END IF

  IF s$ = "gosub_return" THEN
    emit_stmt$ = "    if (xb_gosub_sp > xb_gosub_base) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;"
    RETURN emit_stmt$
  END IF
  IF LEFT$(s$, 11) = "gosub_expr " THEN
    DIM gosubExpr$
    gosubExpr$ = MID$(s$, 12, LEN(s$) - 11)
    DIM geSuf$
    geSuf$ = gosub_ret_suffix$("expr")
    emit_stmt$ = "    { intptr_t _xb_ge = " + emit_expr$(gosubExpr$) + "; if (_xb_ge) { xb_gosub_stack[xb_gosub_sp++] = &&xb_gosub_ret_expr" + geSuf$ + "; goto *(void*)_xb_ge; } xb_gosub_ret_expr" + geSuf$ + ": (void)0; }"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 10) = "goto_expr " THEN
    DIM gotoExpr$
    gotoExpr$ = MID$(s$, 11, LEN(s$) - 10)
    emit_stmt$ = "    goto *(void*)" + emit_expr$(gotoExpr$) + ";"
    RETURN emit_stmt$
  END IF

  emit_stmt$ = ""
END FUNCTION
