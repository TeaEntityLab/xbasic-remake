pub(crate) fn emit_bit_reinterp_runtime(out: &mut String) {
    out.push_str(
        "static int xb_dhigh(double v) { uint64_t b; memcpy(&b, &v, 8); return (int)(b >> 32); }\n",
    );
    out.push_str("static int xb_dlow(double v) { uint64_t b; memcpy(&b, &v, 8); return (int)(b & 0xFFFFFFFF); }\n");
    out.push_str("static double xb_dmake(int hi, int lo) { uint64_t b = ((uint64_t)(unsigned)hi << 32) | (unsigned)lo; double v; memcpy(&v, &b, 8); return v; }\n");
    out.push_str("static int xb_gmake(int hi, int lo) { return lo; }\n");
    out.push_str("static double xb_smake(int v) { float f; uint32_t b = (unsigned)v; memcpy(&f, &b, 4); return (double)f; }\n");
    out.push_str("static int xb_xmake(double v) { float f = (float)v; uint32_t b; memcpy(&b, &f, 4); return (int)b; }\n");
}

pub(crate) fn emit_bit_ops_runtime(out: &mut String) {
    out.push_str("static int xb_bitfield(int w, int o) { return (w << 8) | o; }\n");
    out.push_str("static int xb_exts(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); unsigned bits = ((unsigned)v >> o) & mask; if (w<32 && (bits & (1u<<(w-1)))) bits |= ~mask; return (int)bits; }\n");
    out.push_str("static int xb_extu(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)(((unsigned)v >> o) & mask); }\n");
    out.push_str("static int xb_clr(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)((unsigned)v & ~(mask << o)); }\n");
    out.push_str("static int xb_set(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)((unsigned)v | (mask << o)); }\n");
    out.push_str("static int xb_make(int v, int a, int b) { int w,o; if (b==-99999) { w=(a>>8)&0xFF; o=a&0xFF; } else { w=a; o=b; } unsigned mask = (w>=32)?0xFFFFFFFF:((1u<<w)-1); return (int)(((unsigned)v & mask) << o); }\n");
    out.push_str("static int xb_high0(int v) { unsigned b = ~(unsigned)v; int i; for (i=31; i>=0; i--) if (b & (1u<<i)) return i; return 0; }\n");
    out.push_str("static int xb_high1(int v) { unsigned b = (unsigned)v; int i; for (i=31; i>=0; i--) if (b & (1u<<i)) return i; return 0; }\n");
    out.push_str("static int xb_ghigh(int v) { return v >> 31; }\n");
    out.push_str("static int xb_glow(int v) { return v; }\n");
    out.push_str("static int xb_sign(double v) { return (v < 0.0) ? -1 : 1; }\n");
}

pub(crate) fn emit_str_misc_runtime(out: &mut String) {
    out.push_str("static char* xb_binb(int v) { char buf[35]; int n = 0; if (v == 0) { buf[0] = '0'; buf[1] = 'b'; buf[2] = '0'; buf[3] = 0; return xb_from_cstr(buf); } unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } buf[0] = '0'; buf[1] = 'b'; buf[n + 2] = 0; t = (unsigned int)v; while (t) { buf[--n + 2] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_binb2(int v, int d) { char buf[35]; int n = 0; unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } if (n < d) n = d; if (v == 0 && d == 0) { buf[0] = '0'; buf[1] = 'b'; buf[2] = '0'; buf[3] = 0; return xb_from_cstr(buf); } if (v == 0) n = d; buf[0] = '0'; buf[1] = 'b'; buf[n + 2] = 0; t = (unsigned int)v; int pos = n + 1; while (pos > 1) { buf[pos--] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_octo(int v) { char buf[18]; snprintf(buf, 18, \"0o%o\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_octo2(int v, int d) { char buf[20]; if (d > 0) snprintf(buf, 20, \"0o%0*o\", d, v); else snprintf(buf, 20, \"0o%o\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_bin2(int v, int d) { char buf[33]; int n = 0; unsigned int t = (unsigned int)v; while (t) { n++; t >>= 1; } if (n < d) n = d; if (v == 0) { if (d > 0) n = d; else { buf[0] = '0'; buf[1] = 0; return xb_from_cstr(buf); } } buf[n] = 0; t = (unsigned int)v; int pos = n - 1; while (pos >= 0) { buf[pos--] = (t & 1) ? '1' : '0'; t >>= 1; } return xb_from_cstr(buf); }\n");
    out.push_str("static char* xb_oct2(int v, int d) { char buf[18]; if (d > 0) snprintf(buf, 18, \"%0*o\", d, v); else snprintf(buf, 18, \"%o\", v); return xb_from_cstr(buf); }\n");
    out.push_str("static int xb_quit(int code) { exit(code); return 0; }\n");
    out.push_str("static char* xb_cjust(const char* s, int w) { int len = xb_len(s); if (len >= w) { char* r = xb_alloc((size_t)w); memcpy(r, s, (size_t)w); return r; } int total = w - len, left = total / 2, right = total - left; char* r = xb_alloc((size_t)w); memset(r, ' ', (size_t)left); memcpy(r + left, s, (size_t)len); memset(r + left + len, ' ', (size_t)right); return r; }\n");
    emit_format_runtime(out);
}

pub(crate) fn emit_format_runtime(out: &mut String) {
    out.push_str("static char* xb_format(const char* fmt, const char* sval, int ival, double fval, int is_float, int is_str) {\n");
    out.push_str("  if (is_str) {\n");
    out.push_str("    int slen = xb_len(sval);\n");
    out.push_str("    if (fmt[0] == '&') return xb_strdup(sval);\n");
    out.push_str("    if (fmt[0] == '<' || fmt[0] == '>' || fmt[0] == '|') {\n");
    out.push_str("      int w = 0; for (int i = 0; fmt[i] == fmt[0]; i++) w++;\n");
    out.push_str("      if (slen >= w) { char* r = xb_alloc((size_t)w); memcpy(r, sval, (size_t)w); return r; }\n");
    out.push_str("      int total = w - slen, left = total / 2, right = total - left;\n");
    out.push_str("      char* r = xb_alloc((size_t)w); int pos = 0;\n");
    out.push_str("      if (fmt[0] == '>') { for (int i = 0; i < total; i++) r[pos++] = ' '; memcpy(r + pos, sval, slen); }\n");
    out.push_str("      else if (fmt[0] == '|') { for (int i = 0; i < left; i++) r[pos++] = ' '; memcpy(r + pos, sval, slen); pos += slen; for (int i = 0; i < right; i++) r[pos++] = ' '; }\n");
    out.push_str("      else { memcpy(r, sval, slen); pos += slen; for (int i = 0; i < total; i++) r[pos++] = ' '; }\n");
    out.push_str("      return r;\n");
    out.push_str("    }\n");
    out.push_str("    return xb_strdup(sval);\n");
    out.push_str("  }\n");
    out.push_str("  double val = is_float ? fval : (double)ival;\n");
    out.push_str("  int int_digits = 0, frac_digits = 0, has_decimal = 0, has_commas = 0;\n");
    out.push_str(
        "  int dollar = 0, star_fill = 0, zero_fill = 0, leading_plus = 0, trailing_plus = 0;\n",
    );
    out.push_str("  int trailing_minus = 0, paren_neg = 0;\n");
    out.push_str("  for (int i = 0; fmt[i]; i++) {\n");
    out.push_str("    char c = fmt[i];\n");
    out.push_str("    if (c == '#') { if (has_decimal) frac_digits++; else int_digits++; }\n");
    out.push_str("    else if (c == '.') has_decimal = 1;\n");
    out.push_str("    else if (c == ',') has_commas = 1;\n");
    out.push_str("    else if (c == '$') dollar = 1;\n");
    out.push_str("    else if (c == '*') star_fill = 1;\n");
    out.push_str("    else if (c == '0') zero_fill = 1;\n");
    out.push_str("    else if (c == '+') { if (int_digits > 0) trailing_plus = 1; else leading_plus = 1; }\n");
    out.push_str("    else if (c == '-') { if (int_digits > 0) trailing_minus = 1; }\n");
    out.push_str("    else if (c == '(') paren_neg = 1;\n");
    out.push_str("    else if (c == '_') i++;\n");
    out.push_str("  }\n");
    out.push_str("  if (int_digits == 0 && frac_digits == 0 && !star_fill && !zero_fill) { char buf[64]; snprintf(buf, 64, \"%g\", val); return xb_from_cstr(buf); }\n");
    out.push_str("  int neg = val < 0.0; double abs_val = neg ? -val : val;\n");
    out.push_str("  char r[128]; r[0] = 0; int pos = 0;\n");
    out.push_str("  if (paren_neg && neg) r[pos++] = '(';\n");
    out.push_str("  else if (leading_plus) r[pos++] = neg ? '-' : '+';\n");
    out.push_str("  else if (neg && !trailing_plus && !trailing_minus) r[pos++] = '-';\n");
    out.push_str("  if (dollar) r[pos++] = '$';\n");
    out.push_str("  char numbuf[64];\n");
    out.push_str("  if (has_decimal && frac_digits > 0) snprintf(numbuf, 64, \"%.*f\", frac_digits, abs_val);\n");
    out.push_str("  else snprintf(numbuf, 64, \"%g\", abs_val);\n");
    out.push_str("  char* dot = strchr(numbuf, '.');\n");
    out.push_str("  int orig_int_len = dot ? (int)(dot - numbuf) : (int)strlen(numbuf);\n");
    out.push_str("  char fill = star_fill ? '*' : (zero_fill ? '0' : ' ');\n");
    out.push_str("  int commas = has_commas ? (orig_int_len - 1) / 3 : 0;\n");
    out.push_str("  int pad = int_digits > (orig_int_len + commas) ? int_digits - (orig_int_len + commas) : 0;\n");
    out.push_str("  for (int p = 0; p < pad; p++) r[pos++] = fill;\n");
    out.push_str("  if (has_commas) { for (int i = 0; i < orig_int_len; i++) { if (i > 0 && (orig_int_len - i) % 3 == 0) r[pos++] = ','; r[pos++] = numbuf[i]; } }\n");
    out.push_str("  else { memcpy(r + pos, numbuf, orig_int_len); pos += orig_int_len; }\n");
    out.push_str("  if (dot) { r[pos++] = '.'; int flen = (int)strlen(dot + 1); memcpy(r + pos, dot + 1, flen); pos += flen; }\n");
    out.push_str("  if (paren_neg && neg) r[pos++] = ')';\n");
    out.push_str("  else if (trailing_plus) r[pos++] = neg ? '-' : '+';\n");
    out.push_str("  else if (trailing_minus && neg) r[pos++] = '-';\n");
    out.push_str("  r[pos] = 0; return xb_from_cstr(r);\n}\n");
    out.push_str("static int xb_shell(const char* cmd) { return system(cmd); }\n");
    out.push_str("static int xb_library(int n) { return 0; }\n");
}
