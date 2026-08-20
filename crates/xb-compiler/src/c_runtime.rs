pub(crate) fn emit_header(out: &mut String) {
    out.push_str("#include <stdio.h>\n");
    out.push_str("#include <stdlib.h>\n");
    out.push_str("#include <string.h>\n");
    out.push_str("#include <math.h>\n");
    out.push_str("#include <ctype.h>\n");
    out.push_str("#include <time.h>\n");
    out.push_str("#include <stdint.h>\n");

    // Byte-strings: a string is a char* to its data with a size_t length in an 8-byte
    // header before the data (xb_len reads it) + a trailing NUL for legacy C-lib interop.
    // This makes CHR$(0)/embedded/high bytes byte-accurate through len/concat/print/compare.
    out.push_str("static char* xb_alloc(size_t n) { char* p = (char*)malloc(sizeof(size_t) + n + 1); *(size_t*)p = n; char* d = p + sizeof(size_t); d[n] = 0; return d; }\n");
    out.push_str("static int xb_len(const char* s) { return (int)*((size_t*)s - 1); }\n");
    out.push_str("static char* xb_from_cstr(const char* s) { size_t n = strlen(s); char* d = xb_alloc(n); memcpy(d, s, n); return d; }\n");
    out.push_str("static char* xb_strdup(const char* s) { int n = xb_len(s); char* d = xb_alloc((size_t)n); memcpy(d, s, (size_t)n); return d; }\n");
    out.push_str("static char* xb_str(const char* s) { return xb_from_cstr(s); }\n");
    out.push_str("static char* xb_concat(const char* a, const char* b) {\n");
    out.push_str("    int la = xb_len(a), lb = xb_len(b);\n");
    out.push_str("    char* r = xb_alloc((size_t)(la + lb));\n");
    out.push_str("    memcpy(r, a, (size_t)la);\n");
    out.push_str("    memcpy(r + la, b, (size_t)lb);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static int xb_asc(const char* s) { return (unsigned char)s[0]; }\n");
    out.push_str(
        "static char* xb_chr(int c, int count) { if (count < 1) count = 1; char* r = xb_alloc((size_t)count); for (int i = 0; i < count; i++) r[i] = (char)c; return r; }\n",
    );
    out.push_str("static int xb_scmp(const char* a, const char* b) { int la = xb_len(a), lb = xb_len(b); int m = la < lb ? la : lb; int r = memcmp(a, b, (size_t)m); if (r) return r; return (la > lb) - (la < lb); }\n");
    out.push_str("static char* xb_left(const char* s, int n) {\n");
    out.push_str("    int len = xb_len(s);\n");
    out.push_str("    if (n < 0) n = 0;\n");
    out.push_str("    if (n > len) n = len;\n");
    out.push_str("    char* r = xb_alloc((size_t)n);\n");
    out.push_str("    memcpy(r, s, (size_t)n);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_right(const char* s, int n) {\n");
    out.push_str("    int len = xb_len(s);\n");
    out.push_str("    if (n < 0) n = 0;\n");
    out.push_str("    if (n > len) n = len;\n");
    out.push_str("    char* r = xb_alloc((size_t)n);\n");
    out.push_str("    memcpy(r, s + len - n, (size_t)n);\n");
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
    out.push_str("    memcpy(r, s + off, (size_t)len);\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instr2(const char* s, const char* sub) {\n");
    out.push_str("    const char* p = strstr(s, sub);\n");
    out.push_str("    return p ? (int)(p - s) + 1 : 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instr3(const char* s, const char* sub, int start) {\n");
    out.push_str("    if (start < 1) start = 1;\n");
    out.push_str("    const char* base = s + start - 1;\n");
    out.push_str("    const char* p = strstr(base, sub);\n");
    out.push_str("    return p ? (int)(p - s) + 1 : 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstr2(const char* s, const char* sub) {\n");
    out.push_str("    int slen = strlen(s), sublen = strlen(sub);\n");
    out.push_str("    if (sublen == 0 || sublen > slen) return 0;\n");
    out.push_str("    for (int i = slen - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstr3(const char* s, const char* sub, int end) {\n");
    out.push_str("    int slen = strlen(s), sublen = strlen(sub);\n");
    out.push_str("    if (sublen == 0) return 0;\n");
    out.push_str("    if (end > slen) end = slen;\n");
    out.push_str("    for (int i = end - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instri2(const char* s, const char* sub) {\n");
    out.push_str("    int slen = strlen(s), sublen = strlen(sub);\n");
    out.push_str("    if (sublen == 0 || sublen > slen) return 0;\n");
    out.push_str("    for (int i = 0; i <= slen - sublen; i++)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_instri3(const char* s, const char* sub, int start) {\n");
    out.push_str("    int slen = strlen(s), sublen = strlen(sub);\n");
    out.push_str("    if (start < 1) start = 1;\n");
    out.push_str("    if (sublen == 0) return 0;\n");
    out.push_str("    for (int i = start - 1; i <= slen - sublen; i++)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstri2(const char* s, const char* sub) {\n");
    out.push_str("    int slen = strlen(s), sublen = strlen(sub);\n");
    out.push_str("    if (sublen == 0 || sublen > slen) return 0;\n");
    out.push_str("    for (int i = slen - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_rinstri3(const char* s, const char* sub, int end) {\n");
    out.push_str("    int slen = strlen(s), sublen = strlen(sub);\n");
    out.push_str("    if (sublen == 0) return 0;\n");
    out.push_str("    if (end > slen) end = slen;\n");
    out.push_str("    for (int i = end - sublen; i >= 0; i--)\n");
    out.push_str("        if (strncasecmp(s + i, sub, sublen) == 0) return i + 1;\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_val(const char* s) { return atoi(s); }\n");
    out.push_str(
        "static char* xb_str_num(int v) { char buf[16]; snprintf(buf, 16, \"%d\", v); return xb_from_cstr(buf); }\n",
    );
    out.push_str(
        "static char* xb_str_float(double v) { char buf[32]; snprintf(buf, 32, \"%.17g\", v); return xb_from_cstr(buf); }\n",
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
    out.push_str("static void xb_print_str(const char* s) { fwrite(s, 1, (size_t)xb_len(s), stdout); putchar('\\n'); }\n");
    out.push_str("static void xb_print_float(double v) { printf(\"%.17g\\n\", v); }\n");
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
    out.push_str("static void xb_read_int(int* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int)xb_data_float[xb_data_pos]; else *v = atoi(xb_data_str[xb_data_pos]); xb_data_pos++; }\n");
    out.push_str("static void xb_read_float(double* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 1) *v = xb_data_float[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 0) *v = (double)xb_data_int[xb_data_pos]; else *v = atof(xb_data_str[xb_data_pos]); xb_data_pos++; }\n");
    out.push_str("static char* xb_read_str(void) { if (xb_data_pos >= xb_data_count) return xb_str(\"\"); char* r; if (xb_data_tag[xb_data_pos] == 2) r = xb_strdup(xb_data_str[xb_data_pos]); else { char buf[32]; if (xb_data_tag[xb_data_pos] == 0) snprintf(buf, 32, \"%d\", xb_data_int[xb_data_pos]); else snprintf(buf, 32, \"%.17g\", xb_data_float[xb_data_pos]); r = xb_from_cstr(buf); } xb_data_pos++; return r; }\n");
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
    out.push_str("    const char* m = \"rb\";\n");
    out.push_str("    if (mode == 1 || mode == 2) m = \"r+b\";\n");
    out.push_str("    else if (mode == 3) m = \"wb\";\n");
    out.push_str("    else if (mode == 4) m = \"w+b\";\n");
    out.push_str("    FILE* f = fopen(name, m);\n");
    out.push_str("    if (!f) return -1;\n");
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
    out.push_str("static char* xb_infile(int fn) {\n");
    out.push_str(
        "    if (fn < 3 || fn >= xb_file_count || !xb_files[fn]) return xb_str(\"\");\n",
    );
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
    out.push_str("static void* xb_gosub_stack[256]; static int xb_gosub_sp = 0;\n");
}

/// Sanitize an XBasic name for use as a C identifier: replace `.`, `$`, `!`,
/// `#` with `_`, `_s`, `_f`, `_d` (mirrors `c_emit_expr::emit_var_name`).
fn sanitize_c_name(name: &str) -> String {
    name.replace('.', "_")
        .replace('$', "_s")
        .replace('!', "_f")
        .replace('#', "_d")
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
            ..
        } = item
        {
            // Match emit_functions / the interpreter's find_function: one decl per
            // name (first-wins), since XBasic forward declarations lower to a
            // duplicate function item.
            if !seen.insert(name.clone()) {
                continue;
            }
            out.push_str(c_type(*return_type));
            out.push(' ');
            out.push_str("xb_user_");
            out.push_str(name);
            out.push('(');
            if params.is_empty() {
                out.push_str("void");
            } else {
                for (i, p) in params.iter().enumerate() {
                    if i > 0 {
                        out.push_str(", ");
                    }
                    out.push_str(c_type(p.value_type));
                    // Array param → pointer (matches emit_functions).
                    out.push_str(if p.is_array { " *" } else { " " });
                    out.push_str("xb_");
                    out.push_str(if p.value_type == ValueType::String {
                        "str_"
                    } else {
                        "var_"
                    });
                    out.push_str(&sanitize_c_name(&p.name));
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
                    out.push_str(c_type(target.value_type));
                    out.push_str(" xb_shared_");
                    out.push_str(&sanitize_c_name(&target.name));
                    out.push_str(" = 0;\n");
                }
                collect_shared_expr(value, seen, out);
            }
            IrItem::If {
                then_body,
                else_body,
                ..
            } => {
                collect_shared(then_body, seen, out);
                if let Some(eb) = else_body {
                    collect_shared(eb, seen, out);
                }
            }
            IrItem::While { condition, body, .. } => {
                collect_shared_expr(condition, seen, out);
                collect_shared(body, seen, out);
            }
            IrItem::For { start, end, step, body, .. } => {
                collect_shared_expr(start, seen, out);
                collect_shared_expr(end, seen, out);
                if let Some(s) = step {
                    collect_shared_expr(s, seen, out);
                }
                collect_shared(body, seen, out);
            }
            IrItem::DoLoop { pre_condition, post_condition, body, .. } => {
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
            IrItem::ArrayAssignment { index, extra_indices, value, .. } => {
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
            IrItem::SelectCase { selector, cases, default, .. } => {
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

fn collect_shared_expr(e: &crate::ir::IrExpr, seen: &mut std::collections::HashSet<String>, out: &mut String) {
    use crate::ir::IrExprKind;
    match &e.kind {
        IrExprKind::SharedVariable(s) => {
            if seen.insert(s.name.clone()) {
                out.push_str(c_type(s.value_type));
                out.push_str(" xb_shared_");
                out.push_str(&sanitize_c_name(&s.name));
                out.push_str(" = 0;\n");
            }
        }
        IrExprKind::Symbol(_) | IrExprKind::StringLiteral(_) | IrExprKind::IntegerLiteral(_)
        | IrExprKind::FloatLiteral(_) | IrExprKind::Constant { .. } | IrExprKind::LabelAddress(_)
        | IrExprKind::FuncAddr(_) | IrExprKind::SizeOf { .. } | IrExprKind::SizeOfType { .. } => {}
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
        IrExprKind::ArrayAccess { index, extra_indices, .. } => {
            collect_shared_expr(index, seen, out);
            for x in extra_indices {
                collect_shared_expr(x, seen, out);
            }
        }
        IrExprKind::ArrayUBound { .. } => {}
    }
}
