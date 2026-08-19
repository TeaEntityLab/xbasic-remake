pub(crate) fn emit_math_functions(out: &mut String) {
    out.push_str("static double xb_sqrt(double v) { return sqrt(v); }\n");
    out.push_str("static double xb_sin(double v) { return sin(v); }\n");
    out.push_str("static double xb_cos(double v) { return cos(v); }\n");
    out.push_str("static double xb_tan(double v) { return tan(v); }\n");
    out.push_str("static double xb_exp(double v) { return exp(v); }\n");
    out.push_str("static double xb_log(double v) { return log(v); }\n");
    out.push_str("static double xb_acos(double v) { return acos(v); }\n");
    out.push_str("static double xb_asin(double v) { return asin(v); }\n");
    out.push_str("static double xb_atan(double v) { return atan(v); }\n");
    out.push_str("static double xb_atn(double v) { return atan(v); }\n");
    out.push_str("static double xb_atan2(double a, double b) { return atan2(a, b); }\n");
    out.push_str("static double xb_log10(double v) { return log10(v); }\n");
    out.push_str("static double xb_power(double a, double b) { return pow(a, b); }\n");
    out.push_str("static double xb_sinh(double v) { return sinh(v); }\n");
    out.push_str("static double xb_cosh(double v) { return cosh(v); }\n");
    out.push_str("static double xb_tanh(double v) { return tanh(v); }\n");
    out.push_str("static double xb_asinh(double v) { return asinh(v); }\n");
    out.push_str("static double xb_acosh(double v) { return acosh(v); }\n");
    out.push_str("static double xb_atanh(double v) { return atanh(v); }\n");
    out.push_str("static double xb_exp10(double v) { return pow(10.0, v); }\n");
    out.push_str("static double xb_exp2(double v) { return pow(2.0, v); }\n");
    out.push_str("static double xb_cot(double v) { return 1.0 / tan(v); }\n");
    out.push_str("static double xb_sec(double v) { return 1.0 / cos(v); }\n");
    out.push_str("static double xb_csc(double v) { return 1.0 / sin(v); }\n");
    out.push_str("static double xb_sech(double v) { return 1.0 / cosh(v); }\n");
    out.push_str("static double xb_csch(double v) { return 1.0 / sinh(v); }\n");
    out.push_str("static double xb_coth(double v) { return 1.0 / tanh(v); }\n");
    out.push_str(
        "static double xb_acot(double v) { return v > 1.0 ? atan(1.0/v) : M_PI_2 - atan(v); }\n",
    );
    out.push_str("static double xb_asec(double v) { return M_PI_2 - asin(1.0/v); }\n");
    out.push_str("static double xb_acsc(double v) { return asin(1.0/v); }\n");
    out.push_str("static double xb_acoth(double v) { return atanh(1.0/v); }\n");
    out.push_str("static double xb_asech(double v) { return acosh(1.0/v); }\n");
    out.push_str("static double xb_acsch(double v) { return asinh(1.0/v); }\n");
    out.push_str("static double xb_rnd(void) { return (double)rand() / RAND_MAX; }\n");
    out.push_str("static double xb_ceil(double v) { return ceil(v); }\n");
    out.push_str("static double xb_floor(double v) { return floor(v); }\n");
    out.push_str("static double xb_round(double v) { return round(v); }\n");
    out.push_str("static double xb_timer(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); return tm->tm_hour*3600.0 + tm->tm_min*60.0 + tm->tm_sec; }\n");
    out.push_str("static char* xb_time(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char buf[9]; snprintf(buf, 9, \"%02d:%02d:%02d\", tm->tm_hour, tm->tm_min, tm->tm_sec); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_date(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char buf[11]; snprintf(buf, 11, \"%04d-%02d-%02d\", tm->tm_year+1900, tm->tm_mon+1, tm->tm_mday); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_hexx(int v, int w) { char buf[34]; buf[0]='0'; buf[1]='x'; if (w > 0) snprintf(buf+2, 32, \"%0*X\", w, v); else snprintf(buf+2, 32, \"%X\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_rjust(const char* s, int w) { int len = xb_len(s); if (len >= w) return xb_strdup(s); char* r = xb_alloc((size_t)w); int pad = w - len; for (int i = 0; i < pad; i++) r[i] = ' '; memcpy(r + pad, s, (size_t)len); return r; }\n");
    out.push_str("static char* xb_ljust(const char* s, int w) { int len = xb_len(s); if (len >= w) return xb_strdup(s); char* r = xb_alloc((size_t)w); memcpy(r, s, (size_t)len); for (int i = len; i < w; i++) r[i] = ' '; return r; }\n");
    out.push_str("static char* xb_rclip1(const char* s) { int len = xb_len(s); while (len > 0 && isspace((unsigned char)s[len-1])) len--; char* r = xb_alloc((size_t)len); memcpy(r, s, (size_t)len); return r; }\n");
    out.push_str("static char* xb_rclip2(const char* s, int n) { int len = xb_len(s); if (n >= len) return xb_str(\"\"); int newlen = len - n; char* r = xb_alloc((size_t)newlen); memcpy(r, s, (size_t)newlen); return r; }\n");
    out.push_str("static char* xb_lclip1(const char* s) { int n = xb_len(s); int i = 0; while (i < n && isspace((unsigned char)s[i])) i++; int len = n - i; char* r = xb_alloc((size_t)len); memcpy(r, s + i, (size_t)len); return r; }\n");
    out.push_str("static char* xb_lclip2(const char* s, int n) { int len = xb_len(s); if (n >= len) return xb_str(\"\"); int nl = len - n; char* r = xb_alloc((size_t)nl); memcpy(r, s + n, (size_t)nl); return r; }\n");
    out.push_str("static int xb_inchr(const char* s, const char* set, int start) { int len = xb_len(s); for (int i = start - 1; i < len; i++) { if (strchr(set, s[i])) return i + 1; } return 0; }\n");
    out.push_str("static int xb_rinchr(const char* s, const char* set, int end) { int len = xb_len(s); int begin = end - 1; if (begin >= len) begin = len - 1; for (int i = begin; i >= 0; i--) { if (strchr(set, s[i])) return i + 1; } return 0; }\n");
    out.push_str("static int xb_inchri(const char* s, const char* set, int start) { int len = xb_len(s); char* lset = xb_strdup(set); for (char* p = lset; *p; p++) *p = (char)tolower((unsigned char)*p); for (int i = start - 1; i < len; i++) { if (strchr(lset, tolower((unsigned char)s[i]))) return i + 1; } return 0; }\n");
    out.push_str("static int xb_rinchri(const char* s, const char* set, int end) { int len = xb_len(s); int begin = end - 1; if (begin >= len) begin = len - 1; char* lset = xb_strdup(set); for (char* p = lset; *p; p++) *p = (char)tolower((unsigned char)*p); for (int i = begin; i >= 0; i--) { if (strchr(lset, tolower((unsigned char)s[i]))) return i + 1; } return 0; }\n");
    out.push_str(
        "static int xb_inchr2(const char* s, const char* set) { return xb_inchr(s, set, 1); }\n",
    );
    out.push_str("static int xb_rinchr2(const char* s, const char* set) { return xb_rinchr(s, set, xb_len(s)); }\n");
    out.push_str(
        "static int xb_inchri2(const char* s, const char* set) { return xb_inchri(s, set, 1); }\n",
    );
    out.push_str("static int xb_rinchri2(const char* s, const char* set) { return xb_rinchri(s, set, xb_len(s)); }\n");
    out.push_str("static char* xb_mid2(const char* s, int start) { int slen = xb_len(s); if (start < 1) start = 1; int off = start - 1; if (off >= slen) return xb_str(\"\"); int len = slen - off; char* r = xb_alloc((size_t)len); memcpy(r, s + off, (size_t)len); return r; }\n");
    out.push_str("static char* xb_stuff(const char* into, const char* from, int start, int len) { int ilen = xb_len(into); int flen = xb_len(from); int si = start - 1; if (si < 0) si = 0; if (si > ilen) si = ilen; int avail = ilen - si; int max_from = (len < 0) ? flen : (len < flen ? len : flen); int p2 = max_from < avail ? max_from : avail; char* r = xb_alloc((size_t)ilen); memcpy(r, into, (size_t)si); memcpy(r + si, from, (size_t)p2); memcpy(r + si + p2, into + si + p2, (size_t)(ilen - si - p2)); return r; }\n");
    out.push_str("static char* xb_version(int _) { (void)_; return xb_from_cstr(xb_version_str); }\n");
}
