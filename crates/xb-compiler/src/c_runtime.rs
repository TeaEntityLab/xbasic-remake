pub(crate) fn emit_header(out: &mut String) {
    out.push_str("#include <stdio.h>\n");
    out.push_str("#include <stdlib.h>\n");
    out.push_str("#include <string.h>\n");
    out.push_str("#include <math.h>\n");
    out.push_str("#include <ctype.h>\n");
    out.push_str("#include <time.h>\n");
    out.push('\n');
    out.push_str("static char* xb_strdup(const char* s) { size_t n = strlen(s) + 1; char* r = (char*)malloc(n); memcpy(r, s, n); return r; }\n");
    out.push_str("static char* xb_str(const char* s) { return xb_strdup(s); }\n");
    out.push_str("static char* xb_concat(const char* a, const char* b) {\n");
    out.push_str("    size_t la = strlen(a), lb = strlen(b);\n");
    out.push_str("    char* r = malloc(la + lb + 1);\n");
    out.push_str("    memcpy(r, a, la);\n");
    out.push_str("    memcpy(r + la, b, lb);\n");
    out.push_str("    r[la + lb] = 0;\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static int xb_len(const char* s) { return (int)strlen(s); }\n");
    out.push_str("static int xb_asc(const char* s) { return (unsigned char)s[0]; }\n");
    out.push_str(
        "static char* xb_chr(int c, int count) { if (count < 1) count = 1; char* r = malloc(count + 1); for (int i = 0; i < count; i++) r[i] = (char)c; r[count] = 0; return r; }\n",
    );
    out.push_str("static char* xb_left(const char* s, int n) {\n");
    out.push_str("    int len = (int)strlen(s);\n");
    out.push_str("    if (n < 0) n = 0;\n");
    out.push_str("    if (n > len) n = len;\n");
    out.push_str("    char* r = malloc(n + 1);\n");
    out.push_str("    memcpy(r, s, n);\n");
    out.push_str("    r[n] = 0;\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_right(const char* s, int n) {\n");
    out.push_str("    int len = (int)strlen(s);\n");
    out.push_str("    if (n < 0) n = 0;\n");
    out.push_str("    if (n > len) n = len;\n");
    out.push_str("    char* r = malloc(n + 1);\n");
    out.push_str("    memcpy(r, s + len - n, n);\n");
    out.push_str("    r[n] = 0;\n");
    out.push_str("    return r;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_mid(const char* s, int start, int len) {\n");
    out.push_str("    int slen = (int)strlen(s);\n");
    out.push_str("    if (start < 1) start = 1;\n");
    out.push_str("    int off = start - 1;\n");
    out.push_str("    if (off >= slen) return xb_strdup(\"\");\n");
    out.push_str("    if (len < 0) len = slen - off;\n");
    out.push_str("    if (off + len > slen) len = slen - off;\n");
    out.push_str("    char* r = malloc(len + 1);\n");
    out.push_str("    memcpy(r, s + off, len);\n");
    out.push_str("    r[len] = 0;\n");
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
        "static char* xb_str_num(int v) { char* r = malloc(16); snprintf(r, 16, \"%d\", v); return r; }\n",
    );
    out.push_str(
        "static char* xb_str_float(double v) { char* r = malloc(32); snprintf(r, 32, \"%.17g\", v); return r; }\n",
    );
    out.push_str("static int xb_eof(void) {\n");
    out.push_str("    int c = fgetc(stdin);\n");
    out.push_str("    if (c == EOF) return 1;\n");
    out.push_str("    ungetc(c, stdin);\n");
    out.push_str("    return 0;\n");
    out.push_str("}\n");
    out.push_str("static char* xb_readline(void) {\n");
    out.push_str("    char buf[65536];\n");
    out.push_str("    if (!fgets(buf, sizeof(buf), stdin)) return xb_strdup(\"\");\n");
    out.push_str("    int len = (int)strlen(buf);\n");
    out.push_str("    if (len > 0 && buf[len-1] == '\\n') buf[len-1] = 0;\n");
    out.push_str("    return xb_strdup(buf);\n");
    out.push_str("}\n");
    out.push_str("static void xb_print_int(int v) { printf(\"%d\\n\", v); }\n");
    out.push_str("static void xb_print_str(const char* s) { printf(\"%s\\n\", s); }\n");
    out.push_str("static void xb_print_float(double v) { printf(\"%.17g\\n\", v); }\n");
    out.push_str("static char* xb_ucase(const char* s) { char* r = xb_strdup(s); for (char* p = r; *p; p++) *p = toupper((unsigned char)*p); return r; }\n");
    out.push_str("static char* xb_lcase(const char* s) { char* r = xb_strdup(s); for (char* p = r; *p; p++) *p = tolower((unsigned char)*p); return r; }\n");
    out.push_str("static char* xb_trim(const char* s) { const char* start = s; while (*start == ' ' || *start == '\\t') start++; const char* end = s + strlen(s) - 1; while (end > start && (*end == ' ' || *end == '\\t')) end--; int len = end - start + 1; char* r = malloc(len + 1); memcpy(r, start, len); r[len] = 0; return r; }\n");
    out.push_str("static char* xb_ltrim(const char* s) { const char* start = s; while (*start == ' ' || *start == '\\t') start++; return xb_strdup(start); }\n");
    out.push_str("static char* xb_rtrim(const char* s) { int len = (int)strlen(s); while (len > 0 && (s[len-1] == ' ' || s[len-1] == '\\t')) len--; char* r = malloc(len + 1); memcpy(r, s, len); r[len] = 0; return r; }\n");
    out.push_str("static char* xb_space(int n) { if (n < 0) n = 0; char* r = malloc(n + 1); memset(r, ' ', n); r[n] = 0; return r; }\n");
    out.push_str("static int xb_abs(int v) { return v < 0 ? -v : v; }\n");
    out.push_str("static double xb_fabs(double v) { return fabs(v); }\n");
    out.push_str("static int xb_sgn(int v) { return (v > 0) - (v < 0); }\n");
    out.push_str("static int xb_int(double v) { return (int)floor(v); }\n");
    out.push_str("static int xb_fix(double v) { return (int)trunc(v); }\n");
    out.push_str("static int xb_max(int a, int b) { return a > b ? a : b; }\n");
    out.push_str("static int xb_min(int a, int b) { return a < b ? a : b; }\n");
    out.push_str("static char* xb_hex(int v) { char* r = malloc(16); snprintf(r, 16, \"%X\", v); return r; }\n");
    out.push_str("static char* xb_hex2(int v, int w) { char* r = malloc(32); if (w > 0) snprintf(r, 32, \"%0*X\", w, v); else snprintf(r, 32, \"%X\", v); return r; }\n");
    out.push_str("static char* xb_bin(int v) { char* r = malloc(33); int n = 0; if (v == 0) { r[0] = '0'; r[1] = 0; return r; } int t = v; while (t) { n++; t >>= 1; } r[n] = 0; t = v; while (t) { r[--n] = (t & 1) ? '1' : '0'; t >>= 1; } return r; }\n");
    out.push_str("static char* xb_oct(int v) { char* r = malloc(16); snprintf(r, 16, \"%o\", v); return r; }\n");
    out.push_str("static char* xb_string(int v) { char* r = malloc(16); snprintf(r, 16, \"%d\", v); return r; }\n");
    out.push_str("static char* xb_signed(int v) { char* r = malloc(16); if (v >= 0) snprintf(r, 16, \"+%d\", v); else snprintf(r, 16, \"%d\", v); return r; }\n");
    out.push_str("static char* xb_null(int n) { if (n < 0) n = 0; char* r = malloc(n + 1); memset(r, 0, n); r[n] = 0; return r; }\n");
    crate::c_runtime_math::emit_math_functions(out);
    out.push_str("static int xb_data_int[256]; static double xb_data_float[256]; static char* xb_data_str[256]; static int xb_data_tag[256]; static int xb_data_count = 0; static int xb_data_pos = 0;\n");
    out.push_str("static void xb_data_add_int(int v) { xb_data_tag[xb_data_count] = 0; xb_data_int[xb_data_count] = v; xb_data_count++; }\n");
    out.push_str("static void xb_data_add_float(double v) { xb_data_tag[xb_data_count] = 1; xb_data_float[xb_data_count] = v; xb_data_count++; }\n");
    out.push_str("static void xb_data_add_str(const char* v) { xb_data_tag[xb_data_count] = 2; xb_data_str[xb_data_count] = xb_strdup(v); xb_data_count++; }\n");
    out.push_str("static void xb_read_int(int* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 0) *v = xb_data_int[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 1) *v = (int)xb_data_float[xb_data_pos]; else *v = atoi(xb_data_str[xb_data_pos]); xb_data_pos++; }\n");
    out.push_str("static void xb_read_float(double* v) { if (xb_data_pos >= xb_data_count) { *v = 0; return; } if (xb_data_tag[xb_data_pos] == 1) *v = xb_data_float[xb_data_pos]; else if (xb_data_tag[xb_data_pos] == 0) *v = (double)xb_data_int[xb_data_pos]; else *v = atof(xb_data_str[xb_data_pos]); xb_data_pos++; }\n");
    out.push_str("static char* xb_read_str(void) { if (xb_data_pos >= xb_data_count) return xb_strdup(\"\"); char* r; if (xb_data_tag[xb_data_pos] == 2) r = xb_strdup(xb_data_str[xb_data_pos]); else { r = malloc(32); if (xb_data_tag[xb_data_pos] == 0) snprintf(r, 32, \"%d\", xb_data_int[xb_data_pos]); else snprintf(r, 32, \"%.17g\", xb_data_float[xb_data_pos]); } xb_data_pos++; return r; }\n");
    out.push_str("static void xb_restore(int idx) { xb_data_pos = idx; }\n");
}

use crate::ir::{IrItem, IrProgram};
use crate::ValueType;

pub(crate) fn c_type(vt: ValueType) -> &'static str {
    match vt {
        ValueType::Integer => "int",
        ValueType::Float => "double",
        ValueType::String => "char*",
    }
}

pub(crate) fn emit_forward_decls(program: &IrProgram, out: &mut String) {
    for item in &program.items {
        if let IrItem::Function {
            name,
            params,
            return_type,
            ..
        } = item
        {
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
                    out.push(' ');
                    out.push_str("xb_");
                    out.push_str(if p.value_type == ValueType::String {
                        "str_"
                    } else {
                        "var_"
                    });
                    out.push_str(&p.name);
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
            IrItem::SharedAssignment { target, .. } => {
                if seen.insert(target.name.clone()) {
                    out.push_str(c_type(target.value_type));
                    out.push_str(" xb_shared_");
                    out.push_str(&target.name);
                    out.push_str(" = 0;\n");
                }
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
            IrItem::While { body, .. } => collect_shared(body, seen, out),
            IrItem::Function { body, .. } => collect_shared(body, seen, out),
            _ => {}
        }
    }
}
