pub(crate) fn emit_header(out: &mut String) {
    out.push_str("#include <stdio.h>\n");
    out.push_str("#include <stdlib.h>\n");
    out.push_str("#include <string.h>\n");
    out.push_str("#include <math.h>\n");
    out.push_str("#include <ctype.h>\n");
    out.push_str("#include <time.h>\n");
    out.push_str("#include <stdint.h>\n");
    out.push_str("#ifndef _WIN32\n#include <fcntl.h>\n#include <unistd.h>\n#endif\n");

    // Byte-strings: a string is a char* to its data with a size_t length in an 8-byte
    // header before the data (xb_len reads it) + a trailing NUL for legacy C-lib interop.
    // This makes CHR$(0)/embedded/high bytes byte-accurate through len/concat/print/compare.
    // Byte-strings: a string is a char* to its data with TWO size_t header words
    // before the data: [0]=length (xb_len), [1]=capacity (for xb_append doubling).
    // This makes CHR$(0)/embedded/high bytes byte-accurate and gives O(1) amortized append.
    out.push_str("static char* xb_alloc(size_t n) { size_t* p = (size_t*)malloc(2*sizeof(size_t) + n + 1); p[0] = n; p[1] = n; char* d = (char*)(p + 2); d[n] = 0; return d; }\n");
    out.push_str(
        "static int xb_len(const char* s) { if (!s) return 0; return (int)((size_t*)s)[-2]; }\n",
    );
    out.push_str(
        "static size_t xb_cap(const char* s) { if (!s) return 0; return ((size_t*)s)[-1]; }\n",
    );
    out.push_str("static char* xb_from_cstr(const char* s) { if (!s) s = \"\"; size_t n = strlen(s); char* d = xb_alloc(n); memcpy(d, s, n); return d; }\n");
    out.push_str("static char* xb_strdup(const char* s) { int n = xb_len(s); char* d = xb_alloc((size_t)n); if (n) memcpy(d, s, (size_t)n); return d; }\n");
    out.push_str("static char* xb_str(const char* s) { return xb_from_cstr(s); }\n");
    out.push_str("static char* xb_concat(const char* a, const char* b) {\n");
    out.push_str("    int la = xb_len(a), lb = xb_len(b);\n");
    out.push_str("    char* r = xb_alloc((size_t)(la + lb));\n");
    out.push_str("    if (la) memcpy(r, a, (size_t)la);\n");
    out.push_str("    if (lb) memcpy(r + la, b, (size_t)lb);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_append(char* a, const char* b) {\n");
    out.push_str("    if (!a) return xb_strdup(b);\n");
    out.push_str("    int la = xb_len(a), lb = xb_len(b);\n");
    out.push_str("    size_t new_len = (size_t)la + (size_t)lb;\n");
    out.push_str("    size_t cap = xb_cap(a);\n");
    out.push_str("    if (new_len <= cap) {\n");
    out.push_str("        ((size_t*)a)[-2] = new_len;\n");
    out.push_str("        if (lb) memcpy(a + la, b, (size_t)lb);\n");
    out.push_str("        a[new_len] = 0;\n");
    out.push_str("        return a;\n");
    out.push_str("    }\n");
    out.push_str("    size_t new_cap = new_len;\n");
    out.push_str("    if (la > 4096) { size_t want = (size_t)la * 2; if (want > new_cap) new_cap = want; }\n");
    out.push_str("    size_t* pa = (size_t*)a - 2;\n");
    out.push_str("    size_t* new_p = (size_t*)realloc(pa, 2*sizeof(size_t) + new_cap + 1);\n");
    out.push_str("    if (!new_p) { char* r = xb_alloc(new_len); if (la) memcpy(r, a, (size_t)la); if (lb) memcpy(r + la, b, (size_t)lb); return r; }\n");
    out.push_str("    new_p[0] = new_len;\n");
    out.push_str("    new_p[1] = new_cap;\n");
    out.push_str("    char* r = (char*)(new_p + 2);\n");
    out.push_str("    if (lb) memcpy(r + la, b, (size_t)lb);\n");
    out.push_str("    r[new_len] = 0;\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static int xb_asc(const char* s) { return s ? (unsigned char)s[0] : 0; }\n");
    out.push_str(
        "static char* xb_chr(int c, int count) { if (count < 1) count = 1; char* r = xb_alloc((size_t)count); for (int i = 0; i < count; i++) r[i] = (char)c; return r; }\n",
    );
    out.push_str("static int xb_scmp(const char* a, const char* b) { int la = xb_len(a), lb = xb_len(b); int m = la < lb ? la : lb; int r = 0; if (m) r = memcmp(a, b, (size_t)m); if (r) return r; return (la > lb) - (la < lb); }\n");
    out.push_str("static char* xb_left(const char* s, int n) {\n");
    out.push_str("    int len = xb_len(s);\n");
    out.push_str("    if (n < 0) n = 0;\n");
    out.push_str("    if (n > len) n = len;\n");
    out.push_str("    char* r = xb_alloc((size_t)n);\n");
    out.push_str("    if (n) memcpy(r, s, (size_t)n);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_right(const char* s, int n) {\n");
    out.push_str("    int len = xb_len(s);\n");
    out.push_str("    if (n < 0) n = 0;\n");
    out.push_str("    if (n > len) n = len;\n");
    out.push_str("    char* r = xb_alloc((size_t)n);\n");
    out.push_str("    if (n) memcpy(r, s + len - n, (size_t)n);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_mid(const char* s, int start, int len) {\n");
    out.push_str("    int slen = xb_len(s);\n");
    out.push_str("    if (start < 1) start = 1;\n");
    out.push_str("    int off = start - 1;\n");
    out.push_str("    if (off >= slen) return xb_str(\"\");\n");
    out.push_str("    if (len < 0) len = slen - off;\n");
    out.push_str("    if (off + len > slen) len = slen - off;\n");
    out.push_str("    char* r = xb_alloc((size_t)len);\n");
    out.push_str("    if (len) memcpy(r, s + off, (size_t)len);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instr2(const char* s, const char* sub) {\n");
    out.push_str("    if (!s || !sub) return 0;\n");
    out.push_str("    const char* p = strstr(s, sub);\n");
    out.push_str("    return p ? (int)(p - s) + 1 : 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instr3(const char* s, const char* sub, int start) {\n");
    out.push_str("    if (!s || !sub) return 0;\n");
    out.push_str("    if (start < 1) start = 1;\n");
    out.push_str("    const char* base = s + start - 1;\n");
    out.push_str("    const char* p = strstr(base, sub);\n");
    out.push_str("    return p ? (int)(p - s) + 1 : 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstr2(const char* s, const char* sub) {\n");
    out.push_str("    int slen = xb_len(s), sublen = xb_len(sub);\n");
    out.push_str("    if (sublen == 0 || sublen > slen) return 0;\n");
    out.push_str("    for (int i = slen - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstr3(const char* s, const char* sub, int end) {\n");
    out.push_str("    int slen = xb_len(s), sublen = xb_len(sub);\n");
    out.push_str("    if (sublen == 0) return 0;\n");
    out.push_str("    if (end > slen) end = slen;\n");
    out.push_str("    for (int i = end - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instri2(const char* s, const char* sub) {\n");
    out.push_str("    int slen = xb_len(s), sublen = xb_len(sub);\n");
    out.push_str("    if (sublen == 0 || sublen > slen) return 0;\n");
    out.push_str("    for (int i = 0; i <= slen - sublen; i++)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instri3(const char* s, const char* sub, int start) {\n");
    out.push_str("    int slen = xb_len(s), sublen = xb_len(sub);\n");
    out.push_str("    if (start < 1) start = 1;\n");
    out.push_str("    if (sublen == 0) return 0;\n");
    out.push_str("    for (int i = start - 1; i <= slen - sublen; i++)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstri2(const char* s, const char* sub) {\n");
    out.push_str("    int slen = xb_len(s), sublen = xb_len(sub);\n");
    out.push_str("    if (sublen == 0 || sublen > slen) return 0;\n");
    out.push_str("    for (int i = slen - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstri3(const char* s, const char* sub, int end) {\n");
    out.push_str("    int slen = xb_len(s), sublen = xb_len(sub);\n");
    out.push_str("    if (sublen == 0) return 0;\n");
    out.push_str("    if (end > slen) end = slen;\n");
    out.push_str("    for (int i = end - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_val(const char* s) { return s ? (int)strtol(s, 0, 0) : 0; }\n");
    out.push_str(
        "static char* xb_str_num(int v) { char buf[16]; snprintf(buf, 16, \"%d\", v); return xb_from_cstr(buf); }\n",
    );
    out.push_str(
        "static char* xb_str_giant(int64_t v) { char buf[24]; snprintf(buf, 24, \"%lld\", (long long)v); return xb_from_cstr(buf); }\n",
    );
    // Shortest-round-trip float print matching Rust's f64 `Display` (the
    // interpreter's `render`, slot.rs), so cgen float output is byte-identical.
    // Round MYSELF from a 41-sig-fig expansion (correctly-rounded on any libc at
    // that width) using round-half-away-from-zero, then place the decimal point
    // (fixed notation, never scientific — like Rust). Verified against Rust
    // `Display` on 1e6 random doubles + denormal/MAX/MIN edges (0 mismatches).
    out.push_str(
        r#"static void xb_fmt_float(double v, char* out, int outn) {
    if (v != v) { snprintf(out, (size_t)outn, "NaN"); return; }
    if (v == (1.0/0.0)) { snprintf(out, (size_t)outn, "inf"); return; }
    if (v == -(1.0/0.0)) { snprintf(out, (size_t)outn, "-inf"); return; }
    if (v == 0.0) { snprintf(out, (size_t)outn, signbit(v) ? "-0" : "0"); return; }
    char hi[80]; snprintf(hi, sizeof hi, "%.40e", v);
    const char* s = hi; int neg = 0;
    if (*s == '-') { neg = 1; s++; }
    char md[48]; int nmd = 0;
    md[nmd++] = *s++;
    if (*s == '.') { s++; while (*s && *s != 'e' && *s != 'E') md[nmd++] = *s++; }
    int hexp = (*s == 'e' || *s == 'E') ? atoi(s + 1) : 0;
    char best[48]; int bestn = 0, bestexp = 0;
    for (int p = 1; p <= 17; p++) {
        char r[48]; int rn = p, rexp = hexp;
        for (int i = 0; i < p; i++) r[i] = md[i];
        if (p < nmd && md[p] >= '5') {
            int i = p - 1;
            for (; i >= 0; i--) { if (r[i] < '9') { r[i]++; break; } r[i] = '0'; }
            if (i < 0) { memmove(r + 1, r, (size_t)p); r[0] = '1'; rexp++; }
        }
        while (rn > 1 && r[rn - 1] == '0') rn--;
        char cand[72]; int ci = 0; cand[ci++] = r[0];
        if (rn > 1) { cand[ci++] = '.'; for (int i = 1; i < rn; i++) cand[ci++] = r[i]; }
        snprintf(cand + ci, (size_t)((int)sizeof cand - ci), "e%d", rexp);
        double rt = strtod(cand, 0); if (neg) rt = -rt;
        memcpy(best, r, (size_t)rn); bestn = rn; bestexp = rexp;
        if (rt == v) break;
    }
    int point = bestexp + 1; char* o = out; if (neg) *o++ = '-';
    if (point <= 0) { *o++ = '0'; *o++ = '.'; for (int i = 0; i < -point; i++) *o++ = '0'; for (int i = 0; i < bestn; i++) *o++ = best[i]; }
    else if (point >= bestn) { for (int i = 0; i < bestn; i++) *o++ = best[i]; for (int i = 0; i < point - bestn; i++) *o++ = '0'; }
    else { for (int i = 0; i < point; i++) *o++ = best[i]; *o++ = '.'; for (int i = point; i < bestn; i++) *o++ = best[i]; }
    *o = 0;
}
"#,
    );
    out.push_str(
        "static char* xb_str_float(double v) { char buf[400]; xb_fmt_float(v, buf, 400); return xb_from_cstr(buf); }\n",
    );
    out.push_str("static int xb_eof(void) {\n");
    out.push_str("    int c = fgetc(stdin);\n");
    out.push_str("    if (c == EOF) return 1;\n");
    out.push_str("    ungetc(c, stdin);\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_readline(void) {\n");
    out.push_str("    char buf[65536];\n");
    out.push_str("    if (!fgets(buf, sizeof(buf), stdin)) return xb_str(\"\");\n");
    out.push_str("    int len = (int)strlen(buf);\n");
    out.push_str("    if (len > 0 && buf[len-1] == '\\n') buf[len-1] = 0;\n");
    out.push_str("    return xb_from_cstr(buf);\n");
    out.push_str("}\n");
    out.push_str("static void xb_print_int(int v) { printf(\"%d\\n\", v); }\n");
    out.push_str("static void xb_print_giant(int64_t v) { printf(\"%lld\\n\", (long long)v); }\n");
    out.push_str("static void xb_print_str(const char* s) { fwrite(s, 1, (size_t)xb_len(s), stdout); putchar('\\n'); }\n");
    out.push_str("static void xb_print_float(double v) { char buf[400]; xb_fmt_float(v, buf, 400); printf(\"%s\\n\", buf); }\n");
    out.push_str("static char* xb_ucase(const char* s) { char* r = xb_strdup(s); int n = xb_len(r); for (int i = 0; i < n; i++) r[i] = (char)toupper((unsigned char)r[i]); return r; }\n");
    out.push_str("static char* xb_lcase(const char* s) { char* r = xb_strdup(s); int n = xb_len(r); for (int i = 0; i < n; i++) r[i] = (char)tolower((unsigned char)r[i]); return r; }\n");
    out.push_str("static char* xb_trim(const char* s) { int n = xb_len(s); int a = 0; while (a < n && (s[a] == ' ' || s[a] == '\\t')) a++; int b = n; while (b > a && (s[b-1] == ' ' || s[b-1] == '\\t')) b--; int len = b - a; char* r = xb_alloc((size_t)len); memcpy(r, s + a, (size_t)len); return r; }\n");
    out.push_str("static char* xb_ltrim(const char* s) { int n = xb_len(s); int a = 0; while (a < n && (s[a] == ' ' || s[a] == '\\t')) a++; int len = n - a; char* r = xb_alloc((size_t)len); memcpy(r, s + a, (size_t)len); return r; }\n");
    out.push_str("static char* xb_rtrim(const char* s) { int n = xb_len(s); while (n > 0 && (s[n-1] == ' ' || s[n-1] == '\\t')) n--; char* r = xb_alloc((size_t)n); memcpy(r, s, (size_t)n); return r; }\n");
    out.push_str("static char* xb_space(int n) { if (n < 0) n = 0; char* r = xb_alloc((size_t)n); memset(r, ' ', (size_t)n); return r; }\n");
    out.push_str("static int xb_abs(int v) { return v < 0 ? -v : v; }\n");
    out.push_str("static double xb_fabs(double v) { return fabs(v); }\n");
    out.push_str("static int xb_sgn(int v) { return (v > 0) - (v < 0); }\n");
    out.push_str("static int xb_int(double v) { return (int)floor(v); }\n");
    out.push_str("static int xb_fix(double v) { return (int)trunc(v); }\n");
    out.push_str("static int xb_max(int a, int b) { return a > b ? a : b; }\n");
    out.push_str("static int xb_min(int a, int b) { return a < b ? a : b; }\n");
    out.push_str("static int xb_rotatel(unsigned int v, unsigned int n) { n %= 32; return (v << n) | (v >> ((32 - n) % 32)); }\n");
    out.push_str("static int xb_rotater(unsigned int v, unsigned int n) { n %= 32; return (v >> n) | (v << ((32 - n) % 32)); }\n");
    crate::c_runtime_bit::emit_bit_reinterp_runtime(out);
    crate::c_runtime_bit::emit_bit_ops_runtime(out);
    crate::c_runtime_bit::emit_str_misc_runtime(out);
    out.push_str("static char* xb_hex(int v) { char buf[16]; snprintf(buf, 16, \"%X\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_hex2(int v, int w) { char buf[32]; if (w > 0) snprintf(buf, 32, \"%0*X\", w, v); else snprintf(buf, 32, \"%X\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_bin(int v) { char buf[33]; int n = 0; if (v == 0) { buf[0] = '0'; buf[1] = 0; return xb_from_cstr(buf); } int t = v; while (t) { n++; t >>= 1; } buf[n] = 0; t = v; while (t) { buf[--n] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_oct(int v) { char buf[16]; snprintf(buf, 16, \"%o\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_string(int v) { char buf[16]; snprintf(buf, 16, \"%d\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_signed(int v) { char buf[16]; if (v >= 0) snprintf(buf, 16, \"+%d\", v); else snprintf(buf, 16, \"%d\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_null(int n) { if (n < 0) n = 0; char* r = xb_alloc((size_t)n); memset(r, 0, (size_t)n); return r; }\n");
    crate::c_runtime_math::emit_math_functions(out);
    out.push_str("static int xb_data_int[256]; static double xb_data_float[256]; static char* xb_data_str[256]; static int xb_data_tag[256]; static int xb_data_count = 0; static int xb_data_pos = 0;\n");
    out.push_str("static void xb_data_add_int(int v) { xb_data_tag[xb_data_count] = 0; xb_data_int[xb_data_count] = v; xb_data_count++; }\n");
    out.push_str("static void xb_data_add_float(double v) { xb_data_tag[xb_data_count] = 1; xb_data_float[xb_data_count] = v; xb_data_count++; }\n");
    out.push_str("static void xb_data_add_str(const char* v) { xb_data_tag[xb_data_count] = 2; xb_data_str[xb_data_count] = xb_from_cstr(v); xb_data_count++; }\n");
    out.push_str("static void xb_read_int(int* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int)xb_data_float[xb_data_pos]; else *v = (int)strtol(xb_data_str[xb_data_pos], 0, 0); xb_data_pos++; }\n");
    out.push_str("static void xb_read_giant(int64_t* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int64_t)xb_data_float[xb_data_pos]; else *v = (int64_t)strtoll(xb_data_str[xb_data_pos], 0, 0); xb_data_pos++; }\n");
    out.push_str("static void xb_read_float(double* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 1) *v = xb_data_float[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 0) *v = (double)xb_data_int[xb_data_pos]; else *v = atof(xb_data_str[xb_data_pos]); xb_data_pos++; }\n");
    out.push_str("static char* xb_read_str(void) { if (xb_data_pos >= xb_data_count) return xb_str(\"\"); char* r; if (xb_data_tag[xb_data_pos] == 2) r = xb_strdup(xb_data_str[xb_data_pos]); else { char buf[400]; if (xb_data_tag[xb_data_pos] == 0) snprintf(buf, 400, \"%d\", xb_data_int[xb_data_pos]); else xb_fmt_float(xb_data_float[xb_data_pos], buf, 400); r = xb_from_cstr(buf); } xb_data_pos++; return r; }\n");
    out.push_str("static void xb_restore(int idx) { xb_data_pos = idx; }\n");
    out.push_str("static int xb_error_code = 0;\n");
    out.push_str("static int xb_error(int n) { int old = xb_error_code; if (n != -1) xb_error_code = n; return old; }\n");
    out.push_str("static char* xb_error_str(int n) { char buf[32]; snprintf(buf, 32, \"error %d\", n); return xb_from_cstr(buf); }\n");
    out.push_str("static int xb_csize(const char* s) { const char* p = s; while (*p) p++; return (int)(p - s); }\n");
    out.push_str("static char* xb_csize_str(const char* s) { return xb_from_cstr(s); }\n");
    out.push_str(
        "static char* xb_program_name(int _) { (void)_; return xb_from_cstr(xb_program_name_str); }\n",
    );
    out.push_str("static FILE* xb_files[256]; static int xb_file_count = 3;\n");
    out.push_str("static int xb_open(const char* name, int mode) {\n");
    out.push_str("    int nonblock = (mode & 0x0800) != 0;\n");
    out.push_str("    int base = mode & ~0x0800;\n");
    out.push_str("    FILE* f = NULL;\n");
    out.push_str("#ifdef _WIN32\n");
    out.push_str("    (void)nonblock;\n");
    out.push_str("    if (base == 0 || base == 0x10) f = fopen(name, \"rb\");\n");
    out.push_str("    else if (base == 1 || base == 3 || base == 4) f = fopen(name, \"w+b\");\n");
    out.push_str("    else if (base == 2 || base == 0x20 || base == 0x30) { f = fopen(name, \"r+b\"); if (!f) f = fopen(name, \"w+b\"); }\n");
    out.push_str("    else f = fopen(name, \"rb\");\n");
    out.push_str("#else\n");
    out.push_str("    int flags, access;\n");
    out.push_str("    if (base == 0 || base == 0x10) { flags = O_RDONLY; access = 0; }\n");
    out.push_str("    else if (base == 1 || base == 3) { flags = O_WRONLY | O_CREAT | O_TRUNC; access = 1; }\n");
    out.push_str("    else if (base == 2) { flags = O_RDWR | O_CREAT; access = 2; }\n");
    out.push_str("    else if (base == 4) { flags = O_RDWR | O_CREAT | O_TRUNC; access = 2; }\n");
    out.push_str("    else if (base == 0x20) { flags = O_WRONLY | O_CREAT; access = 1; }\n");
    out.push_str("    else if (base == 0x30) { flags = O_RDWR | O_CREAT; access = 2; }\n");
    out.push_str("    else { flags = O_RDONLY; access = 0; }\n");
    out.push_str("    if (nonblock) flags |= O_NONBLOCK;\n");
    out.push_str("    int fd = open(name, flags, 0666);\n");
    out.push_str("    if (fd >= 0) { f = fdopen(fd, access == 0 ? \"rb\" : (access == 1 ? \"wb\" : \"r+b\")); if (!f) close(fd); }\n");
    out.push_str("#endif\n");
    out.push_str("    if (!f) return -1;\n");
    out.push_str("    if (xb_file_count >= 256) return -1;\n");
    out.push_str("    int fn = xb_file_count++;\n");
    out.push_str("    xb_files[fn] = f;\n");
    out.push_str("    return fn;\n");
    out.push_str("}\n");
    out.push_str("static int xb_close(int fn) {\n");
    out.push_str("    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;\n");
    out.push_str("    int r = fclose(xb_files[fn]);\n");
    out.push_str("    xb_files[fn] = NULL;\n");
    out.push_str("    return r == 0 ? 0 : -1;\n");
    out.push_str("}\n");
    out.push_str("static int xb_lof(int fn) {\n");
    out.push_str("    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;\n");
    out.push_str("    FILE* f = xb_files[fn];\n");
    out.push_str("    long cur = ftell(f);\n");
    out.push_str("    fseek(f, 0, SEEK_END);\n");
    out.push_str("    long len = ftell(f);\n");
    out.push_str("    fseek(f, cur, SEEK_SET);\n");
    out.push_str("    return (int)len;\n");
    out.push_str("}\n");
    out.push_str("static int xb_pof(int fn) {\n");
    out.push_str("    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;\n");
    out.push_str("    return (int)ftell(xb_files[fn]);\n");
    out.push_str("}\n");
    out.push_str("static int xb_seek(int fn, int pos) {\n");
    out.push_str("    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return -1;\n");
    out.push_str("    return fseek(xb_files[fn], pos, SEEK_SET) == 0 ? pos : -1;\n");
    out.push_str("}\n");
    out.push_str("static int xb_write_record(int fn, int count) {\n");
    out.push_str(
        "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn] || count < 0) return -1;\n",
    );
    out.push_str("    if (count == 0) return 0;\n");
    out.push_str("    unsigned char* buf = (unsigned char*)calloc((size_t)count, 1);\n");
    out.push_str("    if (!buf) return -1;\n");
    out.push_str("    size_t put = fwrite(buf, 1, (size_t)count, xb_files[fn]);\n");
    out.push_str("    free(buf);\n");
    out.push_str("    if (fflush(xb_files[fn]) != 0) return -1;\n");
    out.push_str("    return put == (size_t)count ? count : -1;\n");
    out.push_str("}\n");
    out.push_str("static int xb_read_record(int fn, int count) {\n");
    out.push_str(
        "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn] || count < 0) return -1;\n",
    );
    out.push_str("    if (count == 0) return 0;\n");
    out.push_str("    unsigned char* buf = (unsigned char*)malloc((size_t)count);\n");
    out.push_str("    if (!buf) return -1;\n");
    out.push_str("    size_t got = fread(buf, 1, (size_t)count, xb_files[fn]);\n");
    out.push_str("    free(buf);\n");
    out.push_str("    return (int)got;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_infile(int fn) {\n");
    out.push_str("    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return xb_str(\"\");\n");
    out.push_str("    char buf[65536];\n");
    out.push_str("    if (!fgets(buf, sizeof(buf), xb_files[fn])) return xb_str(\"\");\n");
    out.push_str("    int len = (int)strlen(buf);\n");
    out.push_str("    if (len > 0 && buf[len-1] == '\\n') buf[len-1] = 0;\n");
    out.push_str("    return xb_from_cstr(buf);\n");
    out.push_str("}\n");
    out.push_str("static char* xb_tab(int cur, int col) { if (col <= cur) return xb_str(\"\"); int n = col - cur; char* r = xb_alloc((size_t)n); memset(r, ' ', (size_t)n); return r; }\n");
    out.push_str("static char* xb_tab_0(int col) { return xb_tab(0, col); }\n");
    out.push_str("static int xb_isdata(const char* s) { return (s && s[0]) ? -1 : 0; }\n");
    out.push_str("static char* xb_inkey(void) {\n");
    out.push_str("    int c = getchar();\n");
    out.push_str("    if (c == EOF) return xb_str(\"\");\n");
    out.push_str("    char buf[2]; buf[0] = (char)c; buf[1] = 0;\n");
    out.push_str("    return xb_from_cstr(buf);\n");
    out.push_str("}\n");
    out.push_str("static int xb_waitkey(void) { int c = getchar(); return (c == EOF) ? 0 : c; }\n");
    out.push_str("static int xb_isnode(const char* s) { return 0; }\n");
    out.push_str("static intptr_t xb_goaddr(intptr_t x) { return x; }\n");
    out.push_str("static intptr_t xb_subaddr(intptr_t x) { return x; }\n");
    out.push_str("static intptr_t xb_funcaddress(intptr_t x) { return x; }\n");
    out.push_str("static char* xb_cstring(intptr_t addr) { return addr ? xb_from_cstr((char*)addr) : xb_str(\"\"); }\n");
    out.push_str("static int xb_sbyteat(intptr_t addr, intptr_t off) { return (int)(*(signed char*)(addr + off)); }\n");
    out.push_str("static int xb_ubyteat(intptr_t addr, intptr_t off) { return (int)(*(unsigned char*)(addr + off)); }\n");
    out.push_str("static int xb_sshortat(intptr_t addr, intptr_t off) { return (int)(*(signed short*)(addr + off)); }\n");
    out.push_str("static int xb_ushortat(intptr_t addr, intptr_t off) { return (int)(*(unsigned short*)(addr + off)); }\n");
    out.push_str("static int xb_slongat(intptr_t addr, intptr_t off) { return (int)(*(signed int*)(addr + off)); }\n");
    out.push_str("static int xb_ulongat(intptr_t addr, intptr_t off) { return (int)(*(unsigned int*)(addr + off)); }\n");
    out.push_str("static intptr_t xb_xlongat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }\n");
    out.push_str("static intptr_t xb_giantat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }\n");
    out.push_str("static double xb_singleat(intptr_t addr, intptr_t off) { return (double)(*(float*)(addr + off)); }\n");
    out.push_str("static double xb_doubleat(intptr_t addr, intptr_t off) { return *(double*)(addr + off); }\n");
    out.push_str("static intptr_t xb_subaddrat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }\n");
    out.push_str("static intptr_t xb_goaddrat(intptr_t addr, intptr_t off) { return *(intptr_t*)(addr + off); }\n");

    out.push_str("static void xb_mid_assign(char* dst, int start, int len, const char* src) {\n");
    out.push_str("    int dlen = xb_len(dst);\n");
    out.push_str("    int slen = xb_len(src);\n");
    out.push_str("    if (start < 1 || start > dlen) return;\n");
    out.push_str("    int si = start - 1;\n");
    out.push_str("    int copy = (len < 0) ? slen : len;\n");
    out.push_str("    if (copy > slen) copy = slen;\n");
    out.push_str("    if (si + copy > dlen) copy = dlen - si;\n");
    out.push_str("    memcpy(dst + si, src, copy);\n");
    out.push_str("}\n");
    out.push_str("static void xb_setch(char* s, intptr_t index, intptr_t ch) {\n");
    out.push_str("    if (index >= 0 && index < xb_len(s)) s[index] = (char)ch;\n");
    out.push_str("}\n");
    out.push_str("static void* xb_gosub_stack[256]; static int xb_gosub_sp = 0;\n");
}

/// Sanitize an XBasic name for use as a C identifier. Delegates to the single
/// source of truth `c_emit_expr::sanitize_c_ident` (replaces `.`/`$`/`!`/`#`/`@`
/// with `_`/`_s`/`_f`/`_d`/`_a`) so a forward-decl param name can't drift from
/// the definition's — an `@`-suffixed name (SBYTE, e.g. XBSourceLib `value@`)
/// previously leaked a literal `@` into a forward declaration and broke cc.
fn sanitize_c_name(name: &str) -> String {
    crate::c_emit_expr::sanitize_c_ident(name)
}

use crate::c_emit::c_type;
use crate::ir::{IrItem, IrProgram};
use crate::ValueType;

pub(crate) fn emit_forward_decls(program: &IrProgram, out: &mut String) {
    let mut seen = std::collections::HashSet::new();
    for item in &program.items {
        if let IrItem::Function {
            name,
            params,
            return_type,
            return_type_name,
            ..
        } = item
        {
            // Match emit_functions / the interpreter's find_function: one decl per
            // name (first-wins), since XBasic forward declarations lower to a
            // duplicate function item.
            if !seen.insert(name.clone()) {
                continue;
            }
            // Skip EXTERNAL FUNCTION declarations for recognized builtins —
            // their call sites use the C runtime helper, not xb_user_*.
            let body_empty = match item {
                IrItem::Function { body, .. } => body.is_empty(),
                _ => true,
            };
            if body_empty && crate::is_builtin::is_builtin(name) {
                continue;
            }
            if let Some(tn) = return_type_name.as_deref() {
                if tn == "DCOMPLEX" || tn == "SCOMPLEX" {
                    out.push_str(crate::c_emit::composite_c_type(tn));
                } else {
                    out.push_str(c_type(*return_type));
                }
            } else {
                out.push_str(c_type(*return_type));
            }
            out.push(' ');
            out.push_str("xb_user_");
            out.push_str(name);
            out.push('(');
            if params.is_empty() {
                out.push_str("void");
            } else {
                let byref = crate::c_emit::defined_param_byref(name).unwrap_or_default();
                let descriptors = crate::c_emit::fn_descriptor_params(name);
                for (i, p) in params.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    if p.is_array && descriptors.contains(&p.name) {
                        crate::c_emit::emit_descriptor_param_decl(p, out);
                        continue;
                    }
                    // Match emit_functions: a by-ref scalar sharing an array param's
                    // name stays a plain value param (Kittedy's `@adjacent`+`@adjacent[]`).
                    let p_byref = byref.get(i).copied().unwrap_or(false)
                        && !params.iter().any(|q| q.is_array && q.name == p.name);
                    out.push_str(c_type(p.value_type));
                    // Array param → pointer; a by-ref SCALAR param is also a
                    // pointer (`x_ref`, copy-in/out) — must match emit_functions.
                    out.push_str(if p.is_array || p_byref { " *" } else { " " });
                    out.push_str("xb_");
                    out.push_str(if p.value_type == ValueType::String {
                        "str_"
                    } else {
                        "var_"
                    });
                    out.push_str(&sanitize_c_name(&p.name));
                    if p_byref && !p.is_array {
                        out.push_str("_ref");
                    }
                    // Keep prototypes consistent with emit_functions' dup rename:
                    // only when the emitted C name actually collides (same raw
                    // name AND same string-ness).
                    let p_str = p.value_type == ValueType::String;
                    if params[i + 1..]
                        .iter()
                        .any(|q| q.name == p.name && (q.value_type == ValueType::String) == p_str)
                    {
                        out.push_str(&format!("__dup{i}"));
                    }
                }
            }
            out.push_str(");\n");
        }
    }
    out.push('\n');
}

pub(crate) fn emit_globals(program: &IrProgram, out: &mut String) {
    for item in &program.items {
        if let IrItem::ConstantDefinition { name, value, .. } = item {
            out.push_str(&format!("#define XB_CONST_{name} {value}\n"));
        }
    }
    let mut seen = std::collections::HashSet::new();
    collect_shared(&program.items, &mut seen, out);
    // Non-dual-use module-shared arrays (CGEN-SHARED-ARR): ONE heap global each —
    // `T* data` (dyn pointer) + `intptr_t ub` — so a write in one function is seen
    // by a read in another (the interpreter keeps them in `state.shared`). A
    // per-function local gave each function its own uninitialized copy. Access and
    // DIM/REDIM sites already name these via emit_array_var_name / _ub_ref (they
    // are dyn + not undimmed for a shared array). Dual-use shared arrays are
    // excluded by the gate (they keep the old local emission).
    let weak = crate::c_emit::weak_symbols_enabled();
    for (name, vt) in crate::c_emit::shared_arrays_sorted() {
        let sym = crate::ir::IrSymbol {
            name: name.clone(),
            value_type: vt,
        };
        if weak {
            out.push_str("__attribute__((weak)) ");
        }
        out.push_str(c_type(vt));
        out.push_str("* ");
        crate::c_emit::emit_array_var_name(&sym, out);
        out.push_str(" = 0;\n");
        if weak {
            out.push_str("__attribute__((weak)) ");
        }
        out.push_str("intptr_t ");
        crate::c_emit::emit_array_ub_ref(&name, out);
        out.push_str(" = -1;\n");
    }
    out.push('\n');
}

fn collect_shared(
    items: &[IrItem],
    seen: &mut std::collections::HashSet<String>,
    out: &mut String,
) {
    for item in items {
        match item {
            IrItem::SharedAssignment { target, value } => {
                if seen.insert(target.name.clone()) {
                    if crate::c_emit::weak_symbols_enabled() {
                        out.push_str("__attribute__((weak)) ");
                    }
                    out.push_str(c_type(target.value_type));
                    out.push_str(" xb_shared_");
                    out.push_str(&sanitize_c_name(&target.name));
                    out.push_str(" = 0;\n");
                }
                collect_shared_expr(value, seen, out);
            }
            IrItem::Dim {
                symbol,
                is_array: false,
                shared: true,
                ..
            } => {
                if seen.insert(symbol.name.clone()) {
                    if crate::c_emit::weak_symbols_enabled() {
                        out.push_str("__attribute__((weak)) ");
                    }
                    out.push_str(c_type(symbol.value_type));
                    out.push_str(" xb_shared_");
                    out.push_str(&sanitize_c_name(&symbol.name));
                    out.push_str(" = 0;\n");
                }
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                // The condition can be the ONLY reference to a read-only shared var
                // (`IF ##XBSystem != …`), so it must be walked or the global is
                // never declared (undeclared `xb_shared_*`).
                collect_shared_expr(condition, seen, out);
                collect_shared(then_body, seen, out);
                if let Some(eb) = else_body {
                    collect_shared(eb, seen, out);
                }
            }
            IrItem::While {
                condition, body, ..
            } => {
                collect_shared_expr(condition, seen, out);
                collect_shared(body, seen, out);
            }
            IrItem::For {
                start,
                end,
                step,
                body,
                ..
            } => {
                collect_shared_expr(start, seen, out);
                collect_shared_expr(end, seen, out);
                if let Some(s) = step {
                    collect_shared_expr(s, seen, out);
                }
                collect_shared(body, seen, out);
            }
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
                ..
            } => {
                if let Some((e, _)) = pre_condition {
                    collect_shared_expr(e, seen, out);
                }
                if let Some((e, _)) = post_condition {
                    collect_shared_expr(e, seen, out);
                }
                collect_shared(body, seen, out);
            }
            IrItem::Print { items: exprs, .. } => {
                for e in exprs {
                    collect_shared_expr(e, seen, out);
                }
            }
            IrItem::Assignment { value, .. } => collect_shared_expr(value, seen, out),
            IrItem::ArrayAssignment {
                index,
                extra_indices,
                value,
                ..
            } => {
                collect_shared_expr(index, seen, out);
                for x in extra_indices {
                    collect_shared_expr(x, seen, out);
                }
                collect_shared_expr(value, seen, out);
            }
            IrItem::Call { args, .. } => {
                for a in args {
                    collect_shared_expr(a, seen, out);
                }
            }
            IrItem::Return { value: Some(e) } => collect_shared_expr(e, seen, out),
            IrItem::Function { body, .. } => collect_shared(body, seen, out),
            IrItem::Compound(items) => collect_shared(items, seen, out),
            IrItem::SelectCase {
                selector,
                cases,
                default,
                ..
            } => {
                collect_shared_expr(selector, seen, out);
                for c in cases {
                    for cond in &c.conditions {
                        collect_shared_expr(cond, seen, out);
                    }
                    collect_shared(&c.body, seen, out);
                }
                if let Some(b) = default {
                    collect_shared(b, seen, out);
                }
            }
            _ => {}
        }
    }
}

fn collect_shared_expr(
    e: &crate::ir::IrExpr,
    seen: &mut std::collections::HashSet<String>,
    out: &mut String,
) {
    use crate::ir::IrExprKind;
    match &e.kind {
        IrExprKind::SharedVariable(s) => {
            if seen.insert(s.name.clone()) {
                if crate::c_emit::weak_symbols_enabled() {
                    out.push_str("__attribute__((weak)) ");
                }
                out.push_str(c_type(s.value_type));
                out.push_str(" xb_shared_");
                out.push_str(&sanitize_c_name(&s.name));
                out.push_str(" = 0;\n");
            }
        }
        IrExprKind::Symbol(_)
        | IrExprKind::StringLiteral(_)
        | IrExprKind::IntegerLiteral(_)
        | IrExprKind::FloatLiteral(_)
        | IrExprKind::Constant { .. }
        | IrExprKind::LabelAddress(_)
        | IrExprKind::FuncAddr(_)
        | IrExprKind::SizeOf { .. }
        | IrExprKind::SizeOfType { .. } => {}
        IrExprKind::ByRef(inner) => collect_shared_expr(inner, seen, out),
        IrExprKind::Comparison { left, right, .. } => {
            collect_shared_expr(left, seen, out);
            collect_shared_expr(right, seen, out);
        }
        IrExprKind::Arithmetic { left, right, .. } => {
            collect_shared_expr(left, seen, out);
            collect_shared_expr(right, seen, out);
        }
        IrExprKind::Not(inner) | IrExprKind::Unary { operand: inner, .. } => {
            collect_shared_expr(inner, seen, out);
        }
        IrExprKind::Boolean { left, right, .. } | IrExprKind::Logical { left, right, .. } => {
            collect_shared_expr(left, seen, out);
            collect_shared_expr(right, seen, out);
        }
        IrExprKind::FunctionCall { args, .. } => {
            for a in args {
                collect_shared_expr(a, seen, out);
            }
        }
        IrExprKind::ArrayAccess {
            index,
            extra_indices,
            ..
        } => {
            collect_shared_expr(index, seen, out);
            for x in extra_indices {
                collect_shared_expr(x, seen, out);
            }
        }
        IrExprKind::ArrayUBound { .. } => {}
    }
}

/// `XstStringToNumber` C runtime — a byte-for-byte port of the interpreter's
/// `xst::parse_number` (crates/xb-runtime/src/xst.rs). Gated: emitted only when
/// the program calls `xb_xst_str_to_num(` (byte-neutral for the whole shared
/// corpus, which never uses Xst). Also mirrored in `selfhost/cgen.x`.
pub(crate) fn emit_xst_runtime(out: &mut String) {
    out.push_str("static void xb_xst_int_result(int64_t val, intptr_t after, intptr_t* pa, intptr_t* pr, int64_t* pv) { int rt; if (val >= -2147483648LL && val <= 2147483647LL) rt = 6; else if (val >= 0 && val <= 4294967295LL) rt = 8; else rt = 12; *pa = after; *pr = (intptr_t)rt; *pv = val; }\n");
    out.push_str("static int xb_xst_str_to_num(const char* s, intptr_t start, intptr_t* after, intptr_t* rtype, int64_t* value) {\n");
    out.push_str(
        "    int n = xb_len(s); intptr_t i = start; if (i < 0) i = 0; if (i > n) i = n;\n",
    );
    out.push_str(
        "    while (i < n && ((unsigned char)s[i] <= ' ' || (unsigned char)s[i] >= 0x7f)) i++;\n",
    );
    out.push_str(
        "    intptr_t bad = i; int neg = (i < n && s[i] == '-'); intptr_t sign_start = i;\n",
    );
    out.push_str("    if (i < n && (s[i] == '+' || s[i] == '-')) i++;\n");
    out.push_str("    if (i + 1 < n && s[i] == '0') {\n");
    out.push_str("        int c = s[i+1] | 0x20; int radix = 0, hex = 0;\n");
    out.push_str("        if (c == 'x') { radix = 16; hex = 1; } else if (c == 'b') radix = 2; else if (c == 'o') radix = 8;\n");
    out.push_str("        if (radix) {\n");
    out.push_str("            intptr_t ds = i + 2, j = ds; int64_t val = 0;\n");
    out.push_str("            while (j < n) { int d = -1; char ch = s[j];\n");
    out.push_str("                if (hex) { if (ch >= '0' && ch <= '9') d = ch - '0'; else if ((ch|0x20) >= 'a' && (ch|0x20) <= 'f') d = (ch|0x20) - 'a' + 10; }\n");
    out.push_str("                else { if (ch >= '0' && ch < '0' + radix) d = ch - '0'; }\n");
    out.push_str("                if (d < 0) break; val = val * radix + d; j++; }\n");
    out.push_str("            if (j == ds) { *after = bad; *rtype = 0; *value = 0; return -1; }\n");
    out.push_str("            if (neg) val = -val; xb_xst_int_result(val, j, after, rtype, value); return 0;\n");
    out.push_str("        }\n");
    out.push_str("    }\n");
    out.push_str("    intptr_t j = i, int_start = j;\n");
    out.push_str("    while (j < n && s[j] >= '0' && s[j] <= '9') j++;\n");
    out.push_str("    int has_int = j > int_start; int is_float = 0, has_frac = 0;\n");
    out.push_str("    if (j < n && s[j] == '.') { is_float = 1; j++; intptr_t fs = j; while (j < n && s[j] >= '0' && s[j] <= '9') j++; has_frac = j > fs; }\n");
    out.push_str(
        "    if (!has_int && !has_frac) { *after = bad; *rtype = 0; *value = 0; return -1; }\n",
    );
    out.push_str("    if (j < n && (s[j]|0x20) == 'e') { intptr_t k = j + 1; if (k < n && (s[k]=='+'||s[k]=='-')) k++;\n");
    out.push_str("        if (k < n && s[k] >= '0' && s[k] <= '9') { is_float = 1; j = k; while (j < n && s[j] >= '0' && s[j] <= '9') j++; } }\n");
    out.push_str("    if (is_float) { char buf[64]; intptr_t len = j - sign_start; if (len > 63) len = 63; memcpy(buf, s + sign_start, (size_t)len); buf[len] = 0;\n");
    out.push_str("        double f = strtod(buf, 0); int64_t bits; memcpy(&bits, &f, 8); *after = j; *rtype = 14; *value = bits; return 0; }\n");
    out.push_str("    char buf[32]; intptr_t len = j - int_start; if (len > 31) len = 31; memcpy(buf, s + int_start, (size_t)len); buf[len] = 0;\n");
    out.push_str("    int64_t mag = (int64_t)strtoll(buf, 0, 10); int64_t val = neg ? -mag : mag; xb_xst_int_result(val, j, after, rtype, value); return 0;\n");
    out.push_str("}\n");
}

/// `XstBackStringToBinString$` C runtime — byte-for-byte port of
/// `xst::back_to_bin`. Gated: emitted only when `xb_back_to_bin(` is used
/// (byte-neutral for the Xst-free corpus). Result may contain embedded NULs, so
/// it's length-prefixed via `xb_alloc` (not a C string).
pub(crate) fn emit_back_to_bin_runtime(out: &mut String) {
    out.push_str("static char* xb_back_to_bin(const char* s) {\n");
    out.push_str(
        "    int n = xb_len(s); char* tmp = (char*)malloc((size_t)n + 1); int oi = 0, i = 0;\n",
    );
    out.push_str("    while (i < n) {\n");
    out.push_str("        if (s[i] == '\\\\' && i + 1 < n) {\n");
    out.push_str("            char c = s[i+1]; i += 2;\n");
    out.push_str("            if (c == '\"') tmp[oi++] = 0x22;\n");
    out.push_str("            else if (c == '\\\\') tmp[oi++] = 0x5C;\n");
    out.push_str("            else if (c == 'a') tmp[oi++] = 0x07;\n");
    out.push_str("            else if (c == 'b') tmp[oi++] = 0x08;\n");
    out.push_str("            else if (c == 't') tmp[oi++] = 0x09;\n");
    out.push_str("            else if (c == 'n') tmp[oi++] = 0x0A;\n");
    out.push_str("            else if (c == 'v') tmp[oi++] = 0x0B;\n");
    out.push_str("            else if (c == 'f') tmp[oi++] = 0x0C;\n");
    out.push_str("            else if (c == 'r') tmp[oi++] = 0x0D;\n");
    out.push_str("            else if (c == 'x') { int val=0,k=0; while(k<2 && i<n){ char h=s[i]; int d; if(h>='0'&&h<='9')d=h-'0'; else if(h>='a'&&h<='f')d=h-'a'+10; else if(h>='A'&&h<='F')d=h-'A'+10; else break; val=val*16+d; i++; k++; } tmp[oi++]=(char)val; }\n");
    out.push_str("            else if (c>='0'&&c<='9') tmp[oi++]=c-'0';\n");
    out.push_str("            else if (c>='A'&&c<='F') tmp[oi++]=c-'A'+0x0A;\n");
    out.push_str("            else if (c>='G'&&c<='V') tmp[oi++]=c-'G'+0x10;\n");
    out.push_str("            else if (c=='Z') tmp[oi++]=(char)0xFF;\n");
    out.push_str("            else tmp[oi++]=c;\n");
    out.push_str("        } else { tmp[oi++]=s[i++]; }\n");
    out.push_str("    }\n");
    out.push_str(
        "    char* r = xb_alloc((size_t)oi); memcpy(r, tmp, (size_t)oi); free(tmp); return r;\n",
    );
    out.push_str("}\n");
}

/// `XstQuickSort` C runtime — matches interp `xst::quicksort`. Array elements are
/// 8-byte slots (i64/double/char*); reorder via 8-byte copies + an `et`-dispatched
/// (0=int64,1=double,2=string) *stable* insertion sort (ties keep ascending
/// original index). Resizes+fills the index array `n` via `nd`/`nub`.
pub(crate) fn emit_quicksort_runtime(out: &mut String) {
    out.push_str("static int xb_qs_gt(const uint64_t* a, int et, intptr_t i, intptr_t j, int decr, int ci) {\n");
    out.push_str("    int c;\n");
    out.push_str("    if (et == 1) { double x, y; memcpy(&x, &a[i], 8); memcpy(&y, &a[j], 8); c = (x > y) - (x < y); }\n");
    out.push_str("    else if (et == 2) { const char* x = (const char*)a[i]; const char* y = (const char*)a[j];\n");
    out.push_str("        int lx = xb_len(x), ly = xb_len(y), m = lx < ly ? lx : ly, r = 0;\n");
    out.push_str("        for (int k = 0; k < m; k++) { unsigned char cx = (unsigned char)x[k], cy = (unsigned char)y[k]; if (ci) { if (cx>='A'&&cx<='Z') cx+=32; if (cy>='A'&&cy<='Z') cy+=32; } if (cx != cy) { r = cx < cy ? -1 : 1; break; } }\n");
    out.push_str("        if (r == 0) r = (lx > ly) - (lx < ly); c = r; }\n");
    out.push_str(
        "    else { int64_t x = (int64_t)a[i], y = (int64_t)a[j]; c = (x > y) - (x < y); }\n",
    );
    out.push_str("    if (decr) c = -c;\n");
    out.push_str("    return c > 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_quicksort(void* ap, int et, intptr_t alen, intptr_t** nd, intptr_t* nub, intptr_t low, intptr_t high, intptr_t mode) {\n");
    out.push_str(
        "    uint64_t* a = (uint64_t*)ap; int decr = (int)(mode & 1), ci = (int)(mode & 2);\n",
    );
    out.push_str("    if (low <= high && high < alen) {\n");
    out.push_str("        intptr_t rng = high - low + 1;\n");
    out.push_str("        intptr_t* idx = (intptr_t*)malloc((size_t)rng * sizeof(intptr_t));\n");
    out.push_str("        for (intptr_t k = 0; k < rng; k++) idx[k] = low + k;\n");
    out.push_str("        for (intptr_t k = 1; k < rng; k++) { intptr_t cur = idx[k]; intptr_t m = k - 1; while (m >= 0 && xb_qs_gt(a, et, idx[m], cur, decr, ci)) { idx[m+1] = idx[m]; m--; } idx[m+1] = cur; }\n");
    out.push_str("        uint64_t* tmp = (uint64_t*)malloc((size_t)rng * 8);\n");
    out.push_str("        for (intptr_t k = 0; k < rng; k++) tmp[k] = a[idx[k]];\n");
    out.push_str("        for (intptr_t k = 0; k < rng; k++) a[low + k] = tmp[k];\n");
    out.push_str("        if (nd && nub && *nub >= 0) {\n");
    out.push_str("            *nd = (intptr_t*)realloc(*nd, (size_t)alen * sizeof(intptr_t)); *nub = alen - 1;\n");
    out.push_str("            for (intptr_t k = 0; k < alen; k++) (*nd)[k] = k;\n");
    out.push_str("            for (intptr_t k = 0; k < rng; k++) (*nd)[low + k] = idx[k];\n");
    out.push_str("        }\n");
    out.push_str("        free(idx); free(tmp);\n");
    out.push_str("    }\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
}

/// `XstCopyArray` C runtime — resize `*dst_d` to `srclen` and copy elements
/// (8-byte slots; strings deep-copied via `xb_strdup`). Matches interp copyarray.
pub(crate) fn emit_copyarray_runtime(out: &mut String) {
    out.push_str("static int xb_copyarray(void* srcp, intptr_t srclen, int et, void** dst_d, intptr_t* dst_ub) {\n");
    out.push_str("    if (!dst_d || !dst_ub) return 0;\n");
    out.push_str("    uint64_t* src = (uint64_t*)srcp;\n");
    out.push_str("    *dst_d = realloc(*dst_d, (size_t)(srclen < 1 ? 1 : srclen) * 8); *dst_ub = srclen - 1;\n");
    out.push_str("    uint64_t* dst = (uint64_t*)*dst_d;\n");
    out.push_str("    for (intptr_t k = 0; k < srclen; k++) {\n");
    out.push_str(
        "        if (et == 2) dst[k] = (uint64_t)(intptr_t)xb_strdup((const char*)src[k]);\n",
    );
    out.push_str("        else dst[k] = src[k];\n");
    out.push_str("    }\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
}

/// Headless Xgr/Xui `XuiGetNextCallback` C runtime — mirrors interp `gui_builtin`:
/// deliver one synthetic `CloseWindow` (set `@grid`=1, `@message$`="CloseWindow"),
/// then FALSE, so a GUI demo's message loop exits after setup (docs/12 winit
/// runtime deferred). Gated: emitted only when a demo uses it.
pub(crate) fn emit_gui_runtime(out: &mut String) {
    out.push_str("static int xb_gui_close_sent = 0;\n");
    out.push_str("static int xb_gui_next_callback(intptr_t* grid, char** msg) {\n");
    out.push_str("    if (!xb_gui_close_sent) { xb_gui_close_sent = 1; *grid = 1; *msg = xb_from_cstr(\"CloseWindow\"); return -1; }\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
}

/// RT-KERNEL32 Win32-CGI stdio — mirrors interp call.rs kernel32_* helpers.
/// Handles: 0 stdin, 1 stdout, 2 stderr (GetStdHandle -10/-11/-12). Gated:
/// emitted only when a program calls WriteFile/ReadFile.
pub(crate) fn emit_kernel32_runtime(out: &mut String) {
    out.push_str("static int xb_getstdhandle(int dev) { if (dev == -10) return 0; if (dev == -11) return 1; if (dev == -12) return 2; return -1; }\n");
    out.push_str(
        "static int xb_write_file(int h, const char* buf, int bytes, int* written, void* ov) {\n",
    );
    out.push_str("    (void)ov; if (written) *written = 0;\n");
    out.push_str("    if (h != 1 && h != 2) return 0;\n");
    out.push_str("    if (!buf || bytes <= 0) return bytes == 0 ? 1 : 0;\n");
    out.push_str("    FILE* f = (h == 1) ? stdout : stderr;\n");
    out.push_str("    size_t n = fwrite(buf, 1, (size_t)bytes, f);\n");
    out.push_str("    if (h == 1) fflush(stdout);\n");
    out.push_str("    if (written) *written = (int)n;\n");
    out.push_str("    return (int)n == bytes ? 1 : 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_read_file(int h, char** buf, int bytes, int* read, void* ov) {\n");
    out.push_str("    (void)ov; if (read) *read = 0;\n");
    out.push_str("    if (h != 0 || !buf || bytes <= 0) return 0;\n");
    out.push_str("    char* tmp = (char*)malloc((size_t)bytes);\n");
    out.push_str("    if (!tmp) return 0;\n");
    out.push_str("    size_t n = fread(tmp, 1, (size_t)bytes, stdin);\n");
    out.push_str("    char* d = xb_alloc(n); if (n) memcpy(d, tmp, n);\n");
    out.push_str("    free(tmp); *buf = d;\n");
    out.push_str("    if (read) *read = (int)n;\n");
    out.push_str("    return n > 0 ? 1 : 0;\n");
    out.push_str("}\n");
}

/// Headless `XgrProcessMessages` C runtime — mirrors the interp's `Quit { code: 0 }`:
/// the real Xgr library processes GUI events and dispatches callbacks; without it
/// the demo would hang forever. Terminate immediately (exit 0) so the demo's output
/// (produced before the message loop) is flushed. Gated: emitted only when used.
pub(crate) fn emit_xgr_process_messages_runtime(out: &mut String) {
    out.push_str("static void xb_xgr_process_messages(intptr_t mode) { (void)mode; exit(0); }\n");
}
