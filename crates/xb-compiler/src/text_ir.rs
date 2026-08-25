use crate::checked::PrintSep;
use crate::ir::{IrItem, IrProgram};

#[derive(Debug, Clone, Copy, Default)]
pub struct TextIrEmitter;

impl TextIrEmitter {
    pub const fn new() -> Self {
        Self
    }

    pub fn emit_program(self, program: &IrProgram) -> String {
        let mut out = String::new();
        for item in &program.items {
            self.emit_item(item, &mut out, 0);
        }
        if !program.data_values.is_empty() {
            out.push_str("data");
            for (tag, val) in &program.data_values {
                out.push_str(&format!(" {tag}:{val}"));
            }
            out.push('\n');
        }
        out
    }

    fn emit_item(self, item: &IrItem, out: &mut String, indent: usize) {
        let prefix = "  ".repeat(indent);
        match item {
            IrItem::Version(value) => out.push_str(&format!("{prefix}version {value}\n")),
            IrItem::ProgramName(value) => out.push_str(&format!("{prefix}program_name {value}\n")),
            IrItem::Print { items, separators } => {
                if items.is_empty() {
                    out.push_str(&format!("{prefix}print\n"));
                } else {
                    let exprs: Vec<String> = items.iter().map(|e| self.emit_expr(e)).collect();
                    let mut line = format!("{prefix}print {}", exprs[0]);
                    for (sep, expr) in separators.iter().zip(exprs.iter().skip(1)) {
                        line.push_str(match sep {
                            PrintSep::Semicolon => " ; ",
                            PrintSep::Comma => " , ",
                        });
                        line.push_str(expr);
                    }
                    out.push_str(&format!("{line}\n"));
                }
            }
            IrItem::Dim {
                symbol,
                size,
                extra_dims,
                shared,
                ..
            } => {
                let sh = if *shared { "shared " } else { "" };
                match size {
                    Some(sz) => {
                        let mut dims = self.emit_expr(sz);
                        for e in extra_dims {
                            dims.push(',');
                            dims.push_str(&self.emit_expr(e));
                        }
                        out.push_str(&format!(
                            "{prefix}dim {sh}{}[{}]\n",
                            self.emit_symbol(symbol),
                            dims
                        ));
                    }
                    None => {
                        out.push_str(&format!("{prefix}dim {sh}{}\n", self.emit_symbol(symbol)))
                    }
                }
            }
            IrItem::Assignment { target, value } => {
                out.push_str(&format!(
                    "{prefix}assign {} = {}\n",
                    self.emit_symbol(target),
                    self.emit_expr(value)
                ));
            }
            IrItem::ArrayAssignment {
                target,
                index,
                extra_indices,
                value,
            } => {
                let mut idx = self.emit_expr(index);
                for e in extra_indices {
                    idx.push(',');
                    idx.push_str(&self.emit_expr(e));
                }
                out.push_str(&format!(
                    "{prefix}array_assign {}[{}] = {}\n",
                    self.emit_symbol(target),
                    idx,
                    self.emit_expr(value)
                ));
            }
            IrItem::MidAssign {
                target,
                start,
                length,
                value,
            } => {
                if let Some(len) = length {
                    out.push_str(&format!(
                        "{prefix}mid_assign {} | {} | {} | {}\n",
                        self.emit_expr(target),
                        self.emit_expr(start),
                        self.emit_expr(len),
                        self.emit_expr(value)
                    ));
                } else {
                    out.push_str(&format!(
                        "{prefix}mid_assign {} | {} | {}\n",
                        self.emit_expr(target),
                        self.emit_expr(start),
                        self.emit_expr(value)
                    ));
                }
            }
            IrItem::BuiltinAssign { name, args, value } => {
                let parts: Vec<String> = args.iter().map(|a| self.emit_expr(a)).collect();
                out.push_str(&format!(
                    "{prefix}builtin_assign {} {} = {}\n",
                    name,
                    parts.join(" "),
                    self.emit_expr(value)
                ));
            }
            IrItem::ConstantDefinition {
                name,
                value,
                value_type,
            } => out.push_str(&format!(
                "{prefix}const $${name}:{} = integer({value})\n",
                self.emit_type(*value_type)
            )),
            IrItem::SharedAssignment { target, value } => {
                out.push_str(&format!(
                    "{prefix}shared ##{} = {}\n",
                    self.emit_symbol(target),
                    self.emit_expr(value)
                ));
            }
            IrItem::If {
                condition,
                then_body,
                else_body,
            } => {
                out.push_str(&format!("{prefix}if {}\n", self.emit_expr(condition)));
                for item in then_body {
                    self.emit_item(item, out, indent + 1);
                }
                if let Some(else_body) = else_body {
                    out.push_str(&format!("{prefix}else\n"));
                    for item in else_body {
                        self.emit_item(item, out, indent + 1);
                    }
                }
                out.push_str(&format!("{prefix}end if\n"));
            }
            IrItem::While { condition, body } => {
                out.push_str(&format!("{prefix}while {}\n", self.emit_expr(condition)));
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                out.push_str(&format!("{prefix}wend\n"));
            }
            IrItem::DoLoop {
                pre_condition,
                post_condition,
                body,
            } => {
                match pre_condition {
                    Some((cond, is_while)) => {
                        let kw = if *is_while { "while" } else { "until" };
                        out.push_str(&format!("{prefix}do {kw} {}\n", self.emit_expr(cond)));
                    }
                    None => out.push_str(&format!("{prefix}do\n")),
                }
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                match post_condition {
                    Some((cond, is_while)) => {
                        let kw = if *is_while { "while" } else { "until" };
                        out.push_str(&format!("{prefix}loop {kw} {}\n", self.emit_expr(cond)));
                    }
                    None => out.push_str(&format!("{prefix}loop\n")),
                }
            }
            IrItem::For {
                var,
                start,
                end,
                step,
                body,
            } => {
                match step {
                    Some(s) => out.push_str(&format!(
                        "{prefix}for {} = {} to {} step {}\n",
                        self.emit_symbol(var),
                        self.emit_expr(start),
                        self.emit_expr(end),
                        self.emit_expr(s)
                    )),
                    None => out.push_str(&format!(
                        "{prefix}for {} = {} to {}\n",
                        self.emit_symbol(var),
                        self.emit_expr(start),
                        self.emit_expr(end)
                    )),
                }
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                out.push_str(&format!("{prefix}next\n"));
            }
            IrItem::Function {
                name,
                params,
                return_type,
                body,
            } => {
                let ps: Vec<String> = params
                    .iter()
                    .map(|p| {
                        format!(
                            "{}:{}{}",
                            p.name,
                            self.emit_type(p.value_type),
                            if p.is_array { "[]" } else { "" }
                        )
                    })
                    .collect();
                out.push_str(&format!(
                    "{prefix}function {}({}) -> {}\n",
                    name,
                    ps.join(", "),
                    self.emit_type(*return_type)
                ));
                for item in body {
                    self.emit_item(item, out, indent + 1);
                }
                out.push_str(&format!("{prefix}end function\n"));
            }
            IrItem::Return { value } => match value {
                Some(e) => out.push_str(&format!("{prefix}return {}\n", self.emit_expr(e))),
                None => out.push_str(&format!("{prefix}return\n")),
            },
            IrItem::Call { name, args } => {
                let as_str: Vec<String> = args.iter().map(|a| self.emit_expr(a)).collect();
                out.push_str(&format!("{prefix}call {}({})\n", name, as_str.join(", ")));
            }
            IrItem::ExitLoop => out.push_str(&format!("{prefix}exit_loop\n")),
            IrItem::ExitSelect => out.push_str(&format!("{prefix}exit_select\n")),
            IrItem::Swap { left, right } => {
                out.push_str(&format!(
                    "{prefix}swap {} {}\n",
                    self.emit_symbol(left),
                    self.emit_symbol(right)
                ));
            }
            IrItem::Nop => {}
            IrItem::SelectCase {
                selector,
                cases,
                default,
            } => {
                out.push_str(&format!(
                    "{prefix}select_case {}\n",
                    self.emit_expr(selector)
                ));
                for case in cases {
                    let conds: Vec<String> =
                        case.conditions.iter().map(|c| self.emit_expr(c)).collect();
                    out.push_str(&format!("{prefix}  case {}\n", conds.join(", ")));
                    for item in &case.body {
                        self.emit_item(item, out, indent + 2);
                    }
                }
                if let Some(def) = default {
                    out.push_str(&format!("{prefix}  case_else\n"));
                    for item in def {
                        self.emit_item(item, out, indent + 2);
                    }
                }
                out.push_str(&format!("{prefix}end_select\n"));
            }
            IrItem::Compound(items) => {
                for item in items {
                    self.emit_item(item, out, indent);
                }
            }
            IrItem::Read(symbols) => {
                let names: Vec<String> = symbols.iter().map(|s| self.emit_symbol(s)).collect();
                out.push_str(&format!("{prefix}read {}\n", names.join(", ")));
            }
            IrItem::Restore(label) => {
                let l = label.as_deref().unwrap_or("");
                let s = if l.is_empty() {
                    format!("{prefix}restore\n")
                } else {
                    format!("{prefix}restore {l}\n")
                };
                out.push_str(&s);
            }
            IrItem::Stop => out.push_str(&format!("{prefix}stop\n")),
            IrItem::Gosub(name) => out.push_str(&format!("{prefix}gosub {name}\n")),
            IrItem::Label(name) => out.push_str(&format!("{prefix}label {name}\n")),
            IrItem::Goto(name) => out.push_str(&format!("{prefix}goto {name}\n")),
            IrItem::GosubReturn => out.push_str(&format!("{prefix}gosub_return\n")),
            IrItem::GosubExpr(expr) => {
                out.push_str(&format!("{prefix}gosub_expr {}\n", self.emit_expr(expr)))
            }
            IrItem::GotoExpr(expr) => {
                out.push_str(&format!("{prefix}goto_expr {}\n", self.emit_expr(expr)))
            }
        }
    }
}
