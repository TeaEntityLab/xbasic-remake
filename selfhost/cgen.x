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
DIM funcBody$
DIM usedSyms$
DIM dimmedSyms$
DIM fullBody$
DIM hoists$
DIM firstFunc$
DIM firstParams$
DIM emittedFuncs$
DIM skipFunc

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
PRINT "#include <ctype.h>"
PRINT "#include <math.h>"
PRINT "#include <time.h>"
PRINT "#include <stdint.h>"
PRINT ""
PRINT "static char* xb_alloc(size_t n) { char* p = (char*)malloc(sizeof(size_t) + n + 1); *(size_t*)p = n; char* d = p + sizeof(size_t); d[n] = 0; return d; }"
PRINT "static int xb_len(const char* s) { return (int)*((size_t*)s - 1); }"
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
PRINT "    if (off >= slen) return xb_str(" + CHR$(34) + CHR$(34) + ");"
PRINT "    if (len < 0) len = slen - off;"
PRINT "    if (off + len > slen) len = slen - off;"
PRINT "    char* r = xb_alloc((size_t)len);"
PRINT "    memcpy(r, s + off, (size_t)len);"
PRINT "    return r;"
PRINT "}"
PRINT "static char* xb_mid2(const char* s, int start) { int slen = xb_len(s); if (start < 1) start = 1; int off = start - 1; if (off >= slen) return xb_str(" + CHR$(34) + CHR$(34) + "); int len = slen - off; char* r = xb_alloc((size_t)len); memcpy(r, s + off, (size_t)len); return r; }"
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
PRINT "static char* xb_hex(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%X" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_hex2(int v, int w) { char buf[32]; if (w > 0) snprintf(buf, 32, " + CHR$(34) + "%0*X" + CHR$(34) + ", w, v); else snprintf(buf, 32, " + CHR$(34) + "%X" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_bin(int v) { char buf[33]; int n = 0; if (v == 0) { buf[0] = '0'; buf[1] = 0; return xb_from_cstr(buf); } int t = v; while (t) { n++; t >>= 1; } buf[n] = 0; t = v; while (t) { buf[--n] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_oct(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_hexx(int v, int w) { char buf[34]; buf[0]='0'; buf[1]='x'; if (w > 0) snprintf(buf+2, 32, " + CHR$(34) + "%0*X" + CHR$(34) + ", w, v); else snprintf(buf+2, 32, " + CHR$(34) + "%X" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_rjust(const char* s, int w) { int len = xb_len(s); if (len >= w) return xb_strdup(s); char* r = xb_alloc((size_t)w); int pad = w - len; int i; for (i = 0; i < pad; i++) r[i] = ' '; memcpy(r + pad, s, (size_t)len); return r; }"
PRINT "static char* xb_ljust(const char* s, int w) { int len = xb_len(s); if (len >= w) return xb_strdup(s); char* r = xb_alloc((size_t)w); memcpy(r, s, (size_t)len); int i; for (i = len; i < w; i++) r[i] = ' '; return r; }"
PRINT "static char* xb_rclip1(const char* s) { int len = xb_len(s); while (len > 0 && isspace((unsigned char)s[len-1])) len--; char* r = xb_alloc((size_t)len); memcpy(r, s, (size_t)len); return r; }"
PRINT "static char* xb_rclip2(const char* s, int n) { int len = xb_len(s); if (n >= len) return xb_str(" + CHR$(34) + CHR$(34) + "); int newlen = len - n; char* r = xb_alloc((size_t)newlen); memcpy(r, s, (size_t)newlen); return r; }"
PRINT "static char* xb_lclip1(const char* s) { int m = xb_len(s); int i = 0; while (i < m && isspace((unsigned char)s[i])) i++; int len = m - i; char* r = xb_alloc((size_t)len); memcpy(r, s + i, (size_t)len); return r; }"
PRINT "static char* xb_lclip2(const char* s, int n) { int len = xb_len(s); if (n >= len) return xb_str(" + CHR$(34) + CHR$(34) + "); int nl = len - n; char* r = xb_alloc((size_t)nl); memcpy(r, s + n, (size_t)nl); return r; }"
PRINT "static int xb_inchr(const char* s, const char* set, int start) { int len = xb_len(s); int i; for (i = start - 1; i < len; i++) { if (strchr(set, s[i])) return i + 1; } return 0; }"
PRINT "static int xb_rinchr(const char* s, const char* set, int end) { int len = xb_len(s); int begin = end - 1; if (begin >= len) begin = len - 1; int i; for (i = begin; i >= 0; i--) { if (strchr(set, s[i])) return i + 1; } return 0; }"
PRINT "static int xb_inchr2(const char* s, const char* set) { return xb_inchr(s, set, 1); }"
PRINT "static int xb_rinchr2(const char* s, const char* set) { return xb_rinchr(s, set, xb_len(s)); }"
PRINT "static int xb_inchri(const char* s, const char* set, int start) { int len = xb_len(s); char* lset = xb_strdup(set); char* p; for (p = lset; *p; p++) *p = (char)tolower((unsigned char)*p); int i; for (i = start - 1; i < len; i++) { if (strchr(lset, tolower((unsigned char)s[i]))) return i + 1; } return 0; }"
PRINT "static int xb_rinchri(const char* s, const char* set, int end) { int len = xb_len(s); int begin = end - 1; if (begin >= len) begin = len - 1; char* lset = xb_strdup(set); char* p; for (p = lset; *p; p++) *p = (char)tolower((unsigned char)*p); int i; for (i = begin; i >= 0; i--) { if (strchr(lset, tolower((unsigned char)s[i]))) return i + 1; } return 0; }"
PRINT "static int xb_inchri2(const char* s, const char* set) { return xb_inchri(s, set, 1); }"
PRINT "static int xb_rinchri2(const char* s, const char* set) { return xb_rinchri(s, set, xb_len(s)); }"
PRINT "static char* xb_stuff(const char* into, const char* from, int start, int len) { int ilen = xb_len(into); int flen = xb_len(from); int si = start - 1; if (si < 0) si = 0; if (si > ilen) si = ilen; int avail = ilen - si; int max_from = (len < 0) ? flen : (len < flen ? len : flen); int p2 = max_from < avail ? max_from : avail; char* r = xb_alloc((size_t)ilen); memcpy(r, into, (size_t)si); memcpy(r + si, from, (size_t)p2); memcpy(r + si + p2, into + si + p2, (size_t)(ilen - si - p2)); return r; }"
PRINT "static char* xb_string(int v) { char buf[16]; snprintf(buf, 16, " + CHR$(34) + "%d" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_signed(int v) { char buf[16]; if (v >= 0) snprintf(buf, 16, " + CHR$(34) + "+%d" + CHR$(34) + ", v); else snprintf(buf, 16, " + CHR$(34) + "%d" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_null(int n) { if (n < 0) n = 0; char* r = xb_alloc((size_t)n); memset(r, 0, (size_t)n); return r; }"
PRINT "static int xb_rotatel(unsigned int v, unsigned int n) { n %= 32; return (v << n) | (v >> ((32 - n) % 32)); }"
PRINT "static int xb_rotater(unsigned int v, unsigned int n) { n %= 32; return (v >> n) | (v << ((32 - n) % 32)); }"
PRINT "static int xb_dhigh(double v) { uint64_t b; memcpy(&b, &v, 8); return (int)(b >> 32); }"
PRINT "static int xb_dlow(double v) { uint64_t b; memcpy(&b, &v, 8); return (int)(b & 0xFFFFFFFF); }"
PRINT "static double xb_dmake(int hi, int lo) { uint64_t b = ((uint64_t)(unsigned)hi << 32) | (unsigned)lo; double v; memcpy(&v, &b, 8); return v; }"
PRINT "static int64_t xb_gmake(int hi, int lo) { return (int64_t)(((uint64_t)(unsigned)hi << 32) | (unsigned)lo); }"
PRINT "static double xb_smake(int v) { float f; uint32_t b = (unsigned)v; memcpy(&f, &b, 4); return (double)f; }"
PRINT "static int xb_xmake(double v) { float f = (float)v; uint32_t b; memcpy(&b, &f, 4); return (int)b; }"
PRINT "static int xb_error_code = 0;"
PRINT "static int xb_error(int n) { int old = xb_error_code; if (n != -1) xb_error_code = n; return old; }"
PRINT "static char* xb_error_str(int n) { char buf[32]; snprintf(buf, 32, " + CHR$(34) + "error %d" + CHR$(34) + ", n); return xb_from_cstr(buf); }"
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
PRINT "static char* xb_octo(int v) { char buf[18]; snprintf(buf, 18, " + CHR$(34) + "0o%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_cjust(const char* s, int w) { int len = xb_len(s); if (len >= w) { char* r = xb_alloc((size_t)w); memcpy(r, s, (size_t)w); return r; } int total = w - len, left = total / 2, right = total - left; char* r = xb_alloc((size_t)w); memset(r, ' ', (size_t)left); memcpy(r + left, s, (size_t)len); memset(r + left + len, ' ', (size_t)right); return r; }"
PRINT "static int xb_quit(int code) { exit(code); return 0; }"
PRINT "static char* xb_bin2(int v, int d) { char buf[33]; int n = 0; unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } if (n < d) n = d; if (v == 0) { if (d > 0) n = d; else { buf[0] = '0'; buf[1] = 0; return xb_from_cstr(buf); } } buf[n] = 0; t = (unsigned int)v; int pos = n - 1; while (pos >= 0) { buf[pos--] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_oct2(int v, int d) { char buf[18]; if (d > 0) snprintf(buf, 18, " + CHR$(34) + "%0*o" + CHR$(34) + ", d, v); else snprintf(buf, 18, " + CHR$(34) + "%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
PRINT "static char* xb_binb2(int v, int d) { char buf[35]; int n = 0; unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } if (n < d) n = d; if (v == 0 && d == 0) { buf[0] = '0'; buf[1] = 'b'; buf[2] = '0'; buf[3] = 0; return xb_from_cstr(buf); } if (v == 0) n = d; buf[0] = '0'; buf[1] = 'b'; buf[n + 2] = 0; t = (unsigned int)v; int pos = n + 1; while (pos > 1) { buf[pos--] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }"
PRINT "static char* xb_octo2(int v, int d) { char buf[20]; if (d > 0) snprintf(buf, 20, " + CHR$(34) + "0o%0*o" + CHR$(34) + ", d, v); else snprintf(buf, 20, " + CHR$(34) + "0o%o" + CHR$(34) + ", v); return xb_from_cstr(buf); }"
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
PRINT "  if (int_digits == 0 && frac_digits == 0 && !star_fill && !zero_fill) { char buf[64]; snprintf(buf, 64, " + CHR$(34) + CHR$(37) + "g" + CHR$(34) + ", val); return xb_from_cstr(buf); }"
PRINT "  int neg = val < 0.0; double abs_val = neg ? -val : val;"
PRINT "  char r[128]; r[0] = 0; int pos = 0;"
PRINT "  if (paren_neg && neg) r[pos++] = '(';"
PRINT "  else if (leading_plus) r[pos++] = neg ? '-' : '+';"
PRINT "  else if (neg && !trailing_plus && !trailing_minus) r[pos++] = '-';"
PRINT "  if (dollar) r[pos++] = '$';"
PRINT "  char numbuf[64];"
PRINT "  if (has_decimal && frac_digits > 0) snprintf(numbuf, 64, " + CHR$(34) + CHR$(37) + ".*f" + CHR$(34) + ", frac_digits, abs_val);"
PRINT "  else snprintf(numbuf, 64, " + CHR$(34) + CHR$(37) + "g" + CHR$(34) + ", abs_val);"
PRINT "  char* dot = strchr(numbuf, '.');"
PRINT "  int orig_int_len = dot ? (int)(dot - numbuf) : (int)strlen(numbuf);"
PRINT "  char fill = star_fill ? '*' : (zero_fill ? '0' : ' ');"
PRINT "  int commas = has_commas ? (orig_int_len - 1) / 3 : 0;"
PRINT "  int pad = int_digits > (orig_int_len + commas) ? int_digits - (orig_int_len + commas) : 0;"
PRINT "  for (int p = 0; p < pad; p++) r[pos++] = fill;"
PRINT "  if (has_commas) { for (int i = 0; i < orig_int_len; i++) { if (i > 0 && (orig_int_len - i) " + CHR$(37) + " 3 == 0) r[pos++] = ','; r[pos++] = numbuf[i]; } }"
PRINT "  else { memcpy(r + pos, numbuf, orig_int_len); pos += orig_int_len; }"
PRINT "  if (dot) { r[pos++] = '.'; int flen = (int)strlen(dot + 1); memcpy(r + pos, dot + 1, flen); pos += flen; }"
PRINT "  if (paren_neg && neg) r[pos++] = ')';"
PRINT "  else if (trailing_plus) r[pos++] = neg ? '-' : '+';"
PRINT "  else if (trailing_minus && neg) r[pos++] = '-';"
PRINT "  r[pos] = 0; return xb_from_cstr(r);"
PRINT "}"
PRINT "static int xb_shell(const char* cmd) { return system(cmd); }"
PRINT "static int xb_library(int n) { return 0; }"
PRINT "static double xb_sqrt(double v) { return sqrt(v); }"
PRINT "static double xb_sin(double v) { return sin(v); }"
PRINT "static double xb_cos(double v) { return cos(v); }"
PRINT "static double xb_tan(double v) { return tan(v); }"
PRINT "static double xb_exp(double v) { return exp(v); }"
PRINT "static double xb_log(double v) { return log(v); }"
PRINT "static double xb_acos(double v) { return acos(v); }"
PRINT "static double xb_asin(double v) { return asin(v); }"
PRINT "static double xb_atan2(double a, double b) { return atan2(a, b); }"
PRINT "static double xb_atan(double v) { return atan(v); }"
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
PRINT "static double xb_atn(double v) { return atan(v); }"
PRINT "static double xb_ceil(double v) { return ceil(v); }"
PRINT "static double xb_floor(double v) { return floor(v); }"
PRINT "static double xb_round(double v) { return round(v); }"
PRINT "static double xb_rnd(void) { return (double)rand() / RAND_MAX; }"
PRINT "static double xb_timer(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); return tm->tm_hour*3600.0 + tm->tm_min*60.0 + tm->tm_sec; }"
PRINT "static char* xb_time(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char buf[9]; snprintf(buf, 9, " + CHR$(34) + "%02d:%02d:%02d" + CHR$(34) + ", tm->tm_hour, tm->tm_min, tm->tm_sec); return xb_from_cstr(buf); }"
PRINT "static char* xb_date(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char buf[11]; snprintf(buf, 11, " + CHR$(34) + "%04d-%02d-%02d" + CHR$(34) + ", tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday); return xb_from_cstr(buf); }"
PRINT "static char* xb_version(int _) { (void)_; return xb_from_cstr(xb_version_str); }"
PRINT "static int xb_csize(const char* s) { const char* p = s; while (*p) p++; return (int)(p - s); }"
PRINT "static char* xb_csize_str(const char* s) { return xb_from_cstr(s); }"
PRINT "static char* xb_program_name(int _) { (void)_; return xb_from_cstr(xb_program_name_str); }"
PRINT "static int xb_eof(void) {"
PRINT "    int c = fgetc(stdin);"
PRINT "    if (c == EOF) return 1;"
PRINT "    ungetc(c, stdin);"
PRINT "    return 0;"
PRINT "}"
PRINT "static FILE* xb_files[256];"
PRINT "static int xb_file_count = 3;"
PRINT "static int xb_open(const char* name, int mode) {"
PRINT "    const char* opts = (mode == 0) ? " + CHR$(34) + "rb" + CHR$(34) + " : (mode == 1 || mode == 2) ? " + CHR$(34) + "r+b" + CHR$(34) + " : (mode == 3) ? " + CHR$(34) + "wb" + CHR$(34) + " : (mode == 4) ? " + CHR$(34) + "w+b" + CHR$(34) + " : " + CHR$(34) + "rb" + CHR$(34) + ";"
PRINT "    FILE* f = fopen(name, opts);"
PRINT "    if (!f) return -1;"
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
PRINT "static char* xb_infile(int fn) {"
PRINT "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return xb_str(" + CHR$(34) + CHR$(34) + ");"
PRINT "    char buf[65536];"
PRINT "    if (!fgets(buf, sizeof(buf), xb_files[fn])) return xb_str(" + CHR$(34) + CHR$(34) + ");"
PRINT "    int len = (int)strlen(buf);"
PRINT "    if (len > 0 && buf[len-1] == " + CHR$(39) + CHR$(92) + "n" + CHR$(39) + ") buf[len-1] = 0;"
PRINT "    return xb_from_cstr(buf);"
PRINT "}"
PRINT "static char* xb_tab(int cur, int col) { if (col <= cur) return xb_str(" + CHR$(34) + CHR$(34) + "); int n = col - cur; char* r = xb_alloc((size_t)n); memset(r, ' ', (size_t)n); return r; }"
PRINT "static char* xb_tab_0(int col) { return xb_tab(0, col); }"
PRINT "static int xb_isdata(const char* s) { return (s && s[0]) ? -1 : 0; }"
PRINT "static char* xb_inkey(void) { int c = getchar(); if (c == EOF) return xb_str(" + CHR$(34) + CHR$(34) + "); char buf[2]; buf[0] = (char)c; buf[1] = 0; return xb_from_cstr(buf); }"
PRINT "static int xb_waitkey(void) { int c = getchar(); return (c == EOF) ? 0 : c; }"
PRINT "static int xb_isnode(const char* s) { return 0; }"
PRINT "static void xb_mid_assign(char* dst, int start, int len, const char* src) {"
PRINT "    int dlen = xb_len(dst); int slen = xb_len(src);"
PRINT "    if (start < 1 || start > dlen) return;"
PRINT "    int si = start - 1; int copy = (len < 0) ? slen : len;"
PRINT "    if (copy > slen) copy = slen; if (si + copy > dlen) copy = dlen - si;"
PRINT "    memcpy(dst + si, src, copy);"
PRINT "}"
PRINT "static intptr_t xb_goaddr(intptr_t x) { return x; }"
PRINT "static intptr_t xb_subaddr(intptr_t x) { return x; }"
PRINT "static intptr_t xb_funcaddress(intptr_t x) { return x; }"
PRINT "static char* xb_cstring(intptr_t addr) { return addr ? xb_from_cstr((char*)addr) : xb_str(" + CHR$(34) + CHR$(34) + "); }"
PRINT "static int xb_sbyteat(intptr_t a, intptr_t o) { return (int)(*(signed char*)(a+o)); }"
PRINT "static int xb_ubyteat(intptr_t a, intptr_t o) { return (int)(*(unsigned char*)(a+o)); }"
PRINT "static int xb_sshortat(intptr_t a, intptr_t o) { return (int)(*(signed short*)(a+o)); }"
PRINT "static int xb_ushortat(intptr_t a, intptr_t o) { return (int)(*(unsigned short*)(a+o)); }"
PRINT "static int xb_slongat(intptr_t a, intptr_t o) { return (int)(*(signed int*)(a+o)); }"
PRINT "static int xb_ulongat(intptr_t a, intptr_t o) { return (int)(*(unsigned int*)(a+o)); }"
PRINT "static intptr_t xb_xlongat(intptr_t a, intptr_t o) { return *(intptr_t*)(a+o); }"
PRINT "static intptr_t xb_giantat(intptr_t a, intptr_t o) { return *(intptr_t*)(a+o); }"
PRINT "static double xb_singleat(intptr_t a, intptr_t o) { return (double)(*(float*)(a+o)); }"
PRINT "static double xb_doubleat(intptr_t a, intptr_t o) { return *(double*)(a+o); }"
PRINT "static intptr_t xb_subaddrat(intptr_t a, intptr_t o) { return *(intptr_t*)(a+o); }"
PRINT "static intptr_t xb_goaddrat(intptr_t a, intptr_t o) { return *(intptr_t*)(a+o); }"
PRINT "static void* xb_gosub_stack[256]; static int xb_gosub_sp = 0;"
PRINT "static char* xb_readline(void) {"
PRINT "    char buf[65536];"
PRINT "    if (!fgets(buf, sizeof(buf), stdin)) return xb_str(" + CHR$(34) + CHR$(34) + ");"
PRINT "    int len = (int)strlen(buf);"
PRINT "    if (len > 0 && buf[len-1] == '" + CHR$(92) + "n" + CHR$(39) + ") buf[len-1] = 0;"
PRINT "    return xb_from_cstr(buf);"
PRINT "}"
PRINT "static char* xb_ucase(const char* s) { char* r = xb_strdup(s); int n = xb_len(r); for (int i = 0; i < n; i++) r[i] = (char)toupper((unsigned char)r[i]); return r; }"
PRINT "static char* xb_lcase(const char* s) { char* r = xb_strdup(s); int n = xb_len(r); for (int i = 0; i < n; i++) r[i] = (char)tolower((unsigned char)r[i]); return r; }"
PRINT "static char* xb_trim(const char* s) { int n = xb_len(s); int a = 0; while (a < n && (s[a] == ' ' || s[a] == '" + CHR$(92) + "t')) a++; int b = n; while (b > a && (s[b-1] == ' ' || s[b-1] == '" + CHR$(92) + "t')) b--; int len = b - a; char* r = xb_alloc((size_t)len); memcpy(r, s + a, (size_t)len); return r; }"
PRINT "static char* xb_ltrim(const char* s) { int n = xb_len(s); int a = 0; while (a < n && (s[a] == ' ' || s[a] == '" + CHR$(92) + "t')) a++; int len = n - a; char* r = xb_alloc((size_t)len); memcpy(r, s + a, (size_t)len); return r; }"
PRINT "static char* xb_rtrim(const char* s) { int n = xb_len(s); while (n > 0 && (s[n-1] == ' ' || s[n-1] == '" + CHR$(92) + "t')) n--; char* r = xb_alloc((size_t)n); memcpy(r, s, (size_t)n); return r; }"
PRINT "static char* xb_space(int n) { if (n < 0) n = 0; char* r = xb_alloc((size_t)n); memset(r, ' ', (size_t)n); return r; }"
PRINT "static int xb_abs(int v) { return v < 0 ? -v : v; }"
PRINT "static int xb_sgn(int v) { return (v > 0) - (v < 0); }"
PRINT "static int xb_int(double v) { return (int)floor(v); }"
PRINT "static int xb_fix(double v) { return (int)trunc(v); }"
PRINT "static double xb_fabs(double v) { return fabs(v); }"
PRINT "static int xb_max(int a, int b) { return a > b ? a : b; }"
PRINT "static int xb_min(int a, int b) { return a < b ? a : b; }"
PRINT "static void xb_print_int(int v) { printf(" + CHR$(34) + "%d" + CHR$(92) + "n" + CHR$(34) + ", v); }"
PRINT "static void xb_print_giant(int64_t v) { printf(" + CHR$(34) + "%lld" + CHR$(92) + "n" + CHR$(34) + ", (long long)v); }"
PRINT "static void xb_print_str(const char* s) { fwrite(s, 1, (size_t)xb_len(s), stdout); putchar('" + CHR$(92) + "n'); }"
PRINT "static void xb_print_float(double v) { char buf[400]; xb_fmt_float(v, buf, 400); printf(" + CHR$(34) + "%s" + CHR$(92) + "n" + CHR$(34) + ", buf); }"
IF INSTR(src$, "INLINE$(") > 0 THEN
  PRINT "static char* xb_inline(const char* prompt) { if (prompt) xb_print_str(prompt); return xb_readline(); }"
END IF
PRINT "static int xb_data_int[256]; static double xb_data_float[256]; static char* xb_data_str[256]; static int xb_data_tag[256]; static int xb_data_count = 0; static int xb_data_pos = 0;"
PRINT "static void xb_data_add_int(int v) { xb_data_tag[xb_data_count] = 0; xb_data_int[xb_data_count] = v; xb_data_count++; }"
PRINT "static void xb_data_add_float(double v) { xb_data_tag[xb_data_count] = 1; xb_data_float[xb_data_count] = v; xb_data_count++; }"
PRINT "static void xb_data_add_str(const char* v) { xb_data_tag[xb_data_count] = 2; xb_data_str[xb_data_count] = xb_from_cstr(v); xb_data_count++; }"
PRINT "static void xb_read_int(int* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int)xb_data_float[xb_data_pos]; else *v = atoi(xb_data_str[xb_data_pos]); xb_data_pos++; }"
PRINT "static void xb_read_giant(int64_t* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int64_t)xb_data_float[xb_data_pos]; else *v = (int64_t)atoll(xb_data_str[xb_data_pos]); xb_data_pos++; }"
PRINT "static void xb_read_float(double* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 1) *v = xb_data_float[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 0) *v = (double)xb_data_int[xb_data_pos]; else *v = atof(xb_data_str[xb_data_pos]); xb_data_pos++; }"
PRINT "static char* xb_read_str(void) {"
PRINT "  if (xb_data_pos >= xb_data_count) return xb_str(" + CHR$(34) + CHR$(34) + ");"
PRINT "  char* r;"
PRINT "  if (xb_data_tag[xb_data_pos] == 2) r = xb_strdup(xb_data_str[xb_data_pos]);"
PRINT "  else { char buf[400];"
PRINT "    if (xb_data_tag[xb_data_pos] == 0) snprintf(buf, 400, " + CHR$(34) + "%d" + CHR$(34) + ", xb_data_int[xb_data_pos]);"
PRINT "    else xb_fmt_float(xb_data_float[xb_data_pos], buf, 400);"
PRINT "    r = xb_from_cstr(buf); }"
PRINT "  xb_data_pos++; return r;"
PRINT "}"
PRINT "static void xb_restore(int idx) { xb_data_pos = idx; }"
PRINT ""
##funcTypes$ = ""
##funcArity$ = ""
##gosubRetCount$ = ""
##sharedDecls$ = ""
##selectState = 0
##selectExpr$ = ""
##selectBraces = 0
##selectExitCount = 0
##selectExitStack$ = ""
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
      inFunc = 1
      rest$ = MID$(stmt$, 10, LEN(stmt$) - 9)
      parenPos = INSTR(rest$, "(")
      funcName$ = LEFT$(rest$, parenPos - 1)
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
        PRINT c_type$(retType$) + " xb_user_" + funcName$ + "(" + emit_params$(params$) + ") {"
        PRINT "    " + c_type$(retType$) + " " + c_var_name$(funcName$, retType$) + " = " + c_default$(retType$) + ";"
        funcBody$ = ""
        usedSyms$ = CHR$(10)
        dimmedSyms$ = CHR$(10) + funcName$ + CHR$(10) + param_names$(params$)
        ##gosubRetCount$ = ""
      END IF
    ELSEIF stmt$ = "end function" THEN
      inFunc = 0
      IF skipFunc = 0 THEN
        hoists$ = emit_hoists$(usedSyms$, dimmedSyms$)
        fullBody$ = hoists$ + computed_goto_prologue$(funcBody$) + funcBody$
        IF LEN(fullBody$) > 0 THEN
          PRINT LEFT$(fullBody$, LEN(fullBody$) - 1)
        END IF
        PRINT "    return " + c_var_name$(funcName$, retType$) + ";"
        PRINT "}"
      END IF
      skipFunc = 0
    ELSE
      IF skipFunc = 0 THEN
        cCode$ = emit_stmt$(stmt$)
        IF inFunc = 1 THEN
          usedSyms$ = scan_used$(stmt$, usedSyms$)
          IF LEFT$(stmt$, 4) = "dim " THEN
            dimmedSyms$ = dimmedSyms$ + dim_name$(stmt$) + CHR$(10)
          ELSEIF LEFT$(stmt$, 6) = "redim " THEN
            dimmedSyms$ = dimmedSyms$ + dim_name$(stmt$) + CHR$(10)
          END IF
          funcBody$ = funcBody$ + cCode$ + CHR$(10)
        ELSE
          mainBody$ = mainBody$ + cCode$ + CHR$(10)
        END IF
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
  IF t$ = "string" THEN
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
    emit_expr$ = strip_zeros$(t$)
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
      emit_expr$ = "(-(xb_scmp(" + emit_expr$(left$) + ", " + emit_expr$(right$) + ") " + c_cmp_op$(op$) + " 0))"
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

  IF LEFT$(e$, 4) = "neg(" THEN
    t$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(t$, 1) = ")" THEN
      t$ = LEFT$(t$, LEN(t$) - 1)
    END IF
    emit_expr$ = "(-" + emit_expr$(t$) + ")"
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

  IF LEFT$(e$, 4) = "xor(" THEN
    rest$ = MID$(e$, 5, LEN(e$) - 4)
    IF RIGHT$(rest$, 1) = ")" THEN
      rest$ = LEFT$(rest$, LEN(rest$) - 1)
    END IF
    left$ = first_expr$(rest$)
    right$ = after_first$(rest$)
    emit_expr$ = "((" + emit_expr$(left$) + ") ^ (" + emit_expr$(right$) + "))"
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
    emittedArgs$ = emit_args$(args$)
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
    IF INSTR(##funcTypes$, fn$ + ":") = 0 THEN
      IF funcName$ = "xb_user_" + fn$ THEN
        IF RIGHT$(fn$, 1) = "$" THEN
          emit_expr$ = "xb_str(" + CHR$(34) + CHR$(34) + ")"
        ELSE
          emit_expr$ = "0"
        END IF
        RETURN emit_expr$
      END IF
    END IF
    IF INSTR(##funcTypes$, fn$ + ":") > 0 THEN
      emit_expr$ = funcName$ + "(" + emit_args_n$(args$, VAL(arity_of$(fn$))) + ")"
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
      t$ = MID$(t$, br + 1, LEN(t$) - br)
      IF RIGHT$(t$, 1) = "]" THEN
        t$ = LEFT$(t$, LEN(t$) - 1)
      END IF
      emit_expr$ = c_var_name$(varName$, varType$) + emit_msub$(t$, 0)
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
    emit_expr$ = "(int)(sizeof(" + c_var_name$(varName$, varType$) + ")/sizeof(" + c_var_name$(varName$, varType$) + "[0])-1)"
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
    emit_expr$ = "((intptr_t)&&xb_label_" + labelName$ + ")"
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
    emit_expr$ = "xb_shared_" + sanitize_ident$(varName$)
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
    IF ch = 40 THEN
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
  IF INSTR(nm$, ".") > 0 THEN
    RETURN add_sym$
  END IF
  IF INSTR(nm$, "[") > 0 THEN
    RETURN add_sym$
  END IF
  IF INSTR(acc$, CHR$(10) + nm$ + "|") > 0 THEN
    RETURN add_sym$
  END IF
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
      IF ch = 40 THEN
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
        IF INSTR(dimmed$, CHR$(10) + nm$ + CHR$(10)) = 0 THEN
          out$ = out$ + "    " + c_type$(ty$) + " " + c_var_name$(nm$, ty$) + " = " + c_default$(ty$) + ";" + CHR$(10)
        END IF
      END IF
    ELSE
      rest$ = ""
    END IF
  WEND
  emit_hoists$ = out$
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

' Strip leading zeros from a decimal integer literal (keeping one digit + any
' sign), so `08`/`09` are not emitted as invalid C octal constants.
FUNCTION strip_zeros$(n$)
  DIM neg$
  DIM d$
  DIM i
  ' Only DECIMAL leading zeros are the C-octal hazard. Leave hex (`0x..`/`0X..`)
  ' and anything else (empty) exactly as-is.
  IF INSTR(n$, "x") > 0 THEN
    strip_zeros$ = n$
    RETURN strip_zeros$
  END IF
  IF INSTR(n$, "X") > 0 THEN
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
  IF INSTR(body$, "goto *") > 0 THEN
    IF INSTR(body$, "&&xb_gosub_ret_") = 0 THEN
      p$ = "    if (0) { void* _xb_la = &&_xb_cg_dummy; (void)_xb_la; _xb_cg_dummy: (void)0; }" + CHR$(10)
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
        emit_stmt$ = "    char* " + c_var_name$(varName$, varType$) + "[(" + cExpr$ + ") + 1];" + CHR$(10) + "    for (int _i = 0; _i < (" + cExpr$ + ") + 1; _i++) " + c_var_name$(varName$, varType$) + "[_i] = xb_str(" + CHR$(34) + CHR$(34) + ");"
      ELSE
        emit_stmt$ = "    intptr_t " + c_var_name$(varName$, varType$) + emit_msub$(arrSize$, 1) + ";"
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
    spacePos = INSTR(tmp$, "= ")
    right$ = MID$(tmp$, spacePos + 2, LEN(tmp$) - spacePos - 1)
    c2$ = emit_expr$(right$)
    emit_stmt$ = "    " + c_var_name$(varName$, varType$) + emit_msub$(cExpr$, 0) + " = " + c2$ + ";"
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
    DIM printParts$
    DIM printPos
    DIM printStart
    DIM printDepth
    DIM printCh
    DIM printArg$
    DIM printE$
    DIM printT$
    DIM printLast$
    DIM printLE$
    DIM printLT$
    printParts$ = ""
    IF LEN(rest$) = 0 THEN
      emit_stmt$ = "    printf(" + CHR$(34) + CHR$(92) + "n" + CHR$(34) + ");"
      RETURN emit_stmt$
    END IF
    printPos = 1
    printStart = 1
    printDepth = 0
    WHILE printPos <= LEN(rest$)
      printCh = ASC(MID$(rest$, printPos, 1))
      IF printCh = 40 THEN
        printDepth = printDepth + 1
      ELSEIF printCh = 41 THEN
        printDepth = printDepth - 1
      ELSEIF printDepth = 0 AND printPos + 2 <= LEN(rest$) THEN
        IF MID$(rest$, printPos, 3) = " ; " OR MID$(rest$, printPos, 3) = " , " THEN
          printArg$ = MID$(rest$, printStart, printPos - printStart)
          printE$ = emit_expr$(printArg$)
          printT$ = expr_type$(printArg$)
          IF printT$ = "string" THEN
            printParts$ = printParts$ + "    printf(" + CHR$(34) + "%s" + CHR$(34) + ", " + printE$ + ");" + CHR$(10)
          ELSEIF printT$ = "float" THEN
            printParts$ = printParts$ + "    printf(" + CHR$(34) + "%g" + CHR$(34) + ", " + printE$ + ");" + CHR$(10)
          ELSE
            printParts$ = printParts$ + "    printf(" + CHR$(34) + "%d" + CHR$(34) + ", " + printE$ + ");" + CHR$(10)
          END IF
          IF MID$(rest$, printPos, 3) = " , " THEN
            printParts$ = printParts$ + "    printf(" + CHR$(34) + "\t" + CHR$(34) + ");" + CHR$(10)
          END IF
          printStart = printPos + 3
          printPos = printPos + 2
        END IF
      END IF
      printPos = printPos + 1
    WEND
    IF printStart <= LEN(rest$) THEN
      printLast$ = MID$(rest$, printStart, LEN(rest$) - printStart + 1)
      printLE$ = emit_expr$(printLast$)
      printLT$ = expr_type$(printLast$)
      IF printLT$ = "string" THEN
        printParts$ = printParts$ + "    xb_print_str(" + printLE$ + ");"
      ELSEIF printLT$ = "float" THEN
        printParts$ = printParts$ + "    xb_print_float(" + printLE$ + ");"
      ELSE
        printParts$ = printParts$ + "    xb_print_int(" + printLE$ + ");"
      END IF
    END IF
    emit_stmt$ = printParts$
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
    emit_stmt$ = "    while (1) {"
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
    IF INSTR(##funcTypes$, fn$ + ":") = 0 THEN
      IF c_func_name$(fn$) = "xb_user_" + fn$ THEN
        emit_stmt$ = ""
        RETURN emit_stmt$
      END IF
    END IF
    IF INSTR(##funcTypes$, fn$ + ":") > 0 THEN
      emit_stmt$ = "    " + c_func_name$(fn$) + "(" + emit_args_n$(args$, VAL(arity_of$(fn$))) + ");"
    ELSE
      emit_stmt$ = "    " + c_func_name$(fn$) + "(" + emit_args$(args$) + ");"
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
    emit_stmt$ = "    goto _exit_sel_" + STR$(esId) + ";"
    RETURN emit_stmt$
  END IF

  IF LEFT$(s$, 12) = "select_case " THEN
    rest$ = MID$(s$, 13, LEN(s$) - 12)
    cExpr$ = emit_expr$(rest$)
    ##selectState = 1
    ##selectExpr$ = cExpr$
    ##selectBraces = 0
    ##selectExitCount = ##selectExitCount + 1
    ##selectExitStack$ = ##selectExitStack$ + CHR$(##selectExitCount) + ","
    emit_stmt$ = "    { intptr_t _matched = 0;"
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
        caseConds$ = caseConds$ + "(" + ##selectExpr$ + " == " + emit_expr$(caseArg$) + ")"
        caseStart = casePos + 1
      END IF
      casePos = casePos + 1
    WEND
    IF caseStart <= LEN(rest$) THEN
      caseLast$ = MID$(rest$, caseStart, LEN(rest$) - caseStart + 1)
      IF LEN(caseConds$) > 0 THEN
        caseConds$ = caseConds$ + " || "
      END IF
      caseConds$ = caseConds$ + "(" + ##selectExpr$ + " == " + emit_expr$(caseLast$) + ")"
    END IF
    IF ##selectState = 1 THEN
      emit_stmt$ = "    if (" + caseConds$ + ") { _matched = 1;"
    ELSE
      emit_stmt$ = "    } else if (!_matched && (" + caseConds$ + ")) { _matched = 1;"
    END IF
    ##selectState = 2
    ##selectBraces = ##selectBraces + 1
    RETURN emit_stmt$
  END IF

  IF s$ = "case_else" AND ##selectState > 0 THEN
    emit_stmt$ = "    } else {"
    ##selectBraces = ##selectBraces + 1
    RETURN emit_stmt$
  END IF

  IF s$ = "end_select" THEN
    ##selectState = 0
    ##selectExpr$ = ""
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
    emit_stmt$ = "    _exit_sel_" + STR$(selId) + ":; } }"
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
      emit_stmt$ = "    { " + swapCType$ + " _swap_tmp = " + c_var_name$(swapLName$, swapLType$) + "; " + c_var_name$(swapLName$, swapLType$) + " = " + c_var_name$(swapRName$, swapRType$) + "; " + c_var_name$(swapRName$, swapRType$) + " = _swap_tmp; }"
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
    emit_stmt$ = "    if (xb_gosub_sp > 0) { goto *xb_gosub_stack[--xb_gosub_sp]; } return 0;"
    RETURN emit_stmt$
  END IF
  IF LEFT$(s$, 11) = "gosub_expr " THEN
    DIM gosubExpr$
    gosubExpr$ = MID$(s$, 12, LEN(s$) - 11)
    DIM geSuf$
    geSuf$ = gosub_ret_suffix$("expr")
    emit_stmt$ = "    xb_gosub_stack[xb_gosub_sp++] = &&xb_gosub_ret_expr" + geSuf$ + "; goto *(void*)" + emit_expr$(gosubExpr$) + "; xb_gosub_ret_expr" + geSuf$ + ": (void)0;"
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
