pub(crate) fn emit_header(out: &mut String) {
    out.push_str("#include <stdio.h>\n");
    out.push_str("#include <stdlib.h>\n");
    out.push_str("#include <string.h>\n");
    out.push_str("#include <math.h>\n");
    out.push_str("#include <ctype.h>\n");
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
        "static char* xb_chr(int c) { char* r = malloc(2); r[0] = (char)c; r[1] = 0; return r; }\n",
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
    out.push_str("static int xb_instr(const char* s, const char* sub) {\n");
    out.push_str("    const char* p = strstr(s, sub);\n");
    out.push_str("    return p ? (int)(p - s) + 1 : 0;\n");
    out.push_str("}\n");
    out.push_str("static int xb_val(const char* s) { return atoi(s); }\n");
    out.push_str(
        "static char* xb_str_num(int v) { char* r = malloc(16); snprintf(r, 16, \"%d\", v); return r; }\n",
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
    out.push_str("static char* xb_ucase(const char* s) { char* r = xb_strdup(s); for (char* p = r; *p; p++) *p = toupper((unsigned char)*p); return r; }\n");
    out.push_str("static char* xb_lcase(const char* s) { char* r = xb_strdup(s); for (char* p = r; *p; p++) *p = tolower((unsigned char)*p); return r; }\n");
    out.push_str("static char* xb_trim(const char* s) { const char* start = s; while (*start == ' ' || *start == '\\t') start++; const char* end = s + strlen(s) - 1; while (end > start && (*end == ' ' || *end == '\\t')) end--; int len = end - start + 1; char* r = malloc(len + 1); memcpy(r, start, len); r[len] = 0; return r; }\n");
    out.push_str("static char* xb_ltrim(const char* s) { const char* start = s; while (*start == ' ' || *start == '\\t') start++; return xb_strdup(start); }\n");
    out.push_str("static char* xb_rtrim(const char* s) { int len = (int)strlen(s); while (len > 0 && (s[len-1] == ' ' || s[len-1] == '\\t')) len--; char* r = malloc(len + 1); memcpy(r, s, len); r[len] = 0; return r; }\n");
    out.push_str("static char* xb_space(int n) { if (n < 0) n = 0; char* r = malloc(n + 1); memset(r, ' ', n); r[n] = 0; return r; }\n");
    out.push_str("static int xb_abs(int v) { return v < 0 ? -v : v; }\n");
    out.push_str("static int xb_sgn(int v) { return (v > 0) - (v < 0); }\n");
    out.push_str("static int xb_int(int v) { return v; }\n");
    out.push_str("static int xb_fix(int v) { return v; }\n");
    out.push_str("static int xb_max(int a, int b) { return a > b ? a : b; }\n");
    out.push_str("static int xb_min(int a, int b) { return a < b ? a : b; }\n");
    out.push('\n');
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
