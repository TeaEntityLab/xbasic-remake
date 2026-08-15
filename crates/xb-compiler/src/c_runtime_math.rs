pub(crate) fn emit_math_functions(out: &mut String) {
    out.push_str("static double xb_sqrt(double v) { return sqrt(v); }\n");
    out.push_str("static double xb_sin(double v) { return sin(v); }\n");
    out.push_str("static double xb_cos(double v) { return cos(v); }\n");
    out.push_str("static double xb_tan(double v) { return tan(v); }\n");
    out.push_str("static double xb_exp(double v) { return exp(v); }\n");
    out.push_str("static double xb_log(double v) { return log(v); }\n");
    out.push_str("static double xb_acos(double v) { return acos(v); }\n");
    out.push_str("static double xb_asin(double v) { return asin(v); }\n");
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
    out.push_str("static char* xb_time(void) { time_t t = time(NULL); struct tm *tm = localtime(&t); char* r = malloc(9); snprintf(r, 9, \"%02d:%02d:%02d\", tm->tm_hour, tm->tm_min, tm->tm_sec); return r; }\n");
    out.push_str("static char* xb_hexx(int v, int w) { char* r = malloc(32); if (w > 0) snprintf(r, 32, \"%0*X\", w, v); else snprintf(r, 32, \"%X\", v); return r; }\n");
    out.push_str("static char* xb_rjust(const char* s, int w) { int len = strlen(s); if (len >= w) return xb_strdup(s); char* r = malloc(w + 1); int pad = w - len; for (int i = 0; i < pad; i++) r[i] = ' '; memcpy(r + pad, s, len); r[w] = 0; return r; }\n");
    out.push_str("static char* xb_ljust(const char* s, int w) { int len = strlen(s); if (len >= w) return xb_strdup(s); char* r = malloc(w + 1); memcpy(r, s, len); for (int i = len; i < w; i++) r[i] = ' '; r[w] = 0; return r; }\n");
}
