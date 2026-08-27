use crate::checked::{PrintSep, ValueType};
use crate::ir::{IrItem, IrParam, IrProgram};

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

    /// Emit the program with an additive `facet` header. The header is
    /// optional and backward-compatible: `TextIrParser` accepts it as `Nop`.
    /// This is the second slice of `docs/19` — facets now reflect the
    /// frontend's real storage/dual classification (dyn via `collect_dyn_names`,
    /// dual via `collect_dual_use`, descriptor via `collect_descriptor_params`)
    /// instead of the initial fixed/dyn-by-size heuristic.
    pub fn emit_program_with_facets(self, program: &IrProgram) -> String {
        let mut out = String::new();
        let mut facets: Vec<String> = Vec::new();
        let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();
        self.collect_facets_accurate(program, &mut facets, &mut seen);
        // Emit version / program_name first if present, then facets, then rest.
        let mut rest_start = 0;
        for (idx, item) in program.items.iter().enumerate() {
            match item {
                IrItem::Version(_) | IrItem::ProgramName(_) => {
                    self.emit_item(item, &mut out, 0);
                    rest_start = idx + 1;
                }
                _ => break,
            }
        }
        for f in &facets {
            out.push_str(f);
            out.push('\n');
        }
        for item in &program.items[rest_start..] {
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

    fn collect_facets_accurate(
        self,
        program: &IrProgram,
        out: &mut Vec<String>,
        seen: &mut std::collections::HashSet<String>,
    ) {
        use std::collections::{HashMap, HashSet};
        let desc_map = crate::c_emit_hoist::collect_descriptor_params(program);
        let top_items: Vec<IrItem> = program
            .items
            .iter()
            .filter(|it| !matches!(it, IrItem::Function { .. }))
            .cloned()
            .collect();
        if !top_items.is_empty() {
            self.emit_facets_for_scope(&top_items, "*", &[], &HashMap::new(), out, seen);
        }
        for item in &program.items {
            if let IrItem::Function { name, params, body, .. } = item {
                let desc_locals: HashMap<String, crate::checked::ValueType> = desc_map
                    .get(name)
                    .map(|(_, m)| m.clone())
                    .unwrap_or_default();
                self.emit_facets_for_scope(body, name, params, &desc_locals, out, seen);
                self.collect_facets_nested(body, out, seen, &desc_map);
            }
        }
    }

    fn collect_facets_nested(
        self,
        items: &[IrItem],
        out: &mut Vec<String>,
        seen: &mut std::collections::HashSet<String>,
        desc_map: &std::collections::HashMap<String, (std::collections::HashSet<String>, std::collections::HashMap<String, crate::checked::ValueType>)>,
    ) {
        for item in items {
            if let IrItem::Function { name, params, body, .. } = item {
                let desc_locals = desc_map.get(name).map(|(_, m)| m.clone()).unwrap_or_default();
                self.emit_facets_for_scope(body, name, params, &desc_locals, out, seen);
                self.collect_facets_nested(body, out, seen, desc_map);
            } else if let IrItem::If { then_body, else_body, .. } = item {
                self.collect_facets_nested(then_body, out, seen, desc_map);
                if let Some(eb) = else_body {
                    self.collect_facets_nested(eb, out, seen, desc_map);
                }
            } else if let IrItem::While { body, .. } | IrItem::For { body, .. } | IrItem::DoLoop { body, .. } = item {
                self.collect_facets_nested(body, out, seen, desc_map);
            } else if let IrItem::SelectCase { cases, default, .. } = item {
                for cl in cases {
                    self.collect_facets_nested(&cl.body, out, seen, desc_map);
                }
                if let Some(d) = default {
                    self.collect_facets_nested(d, out, seen, desc_map);
                }
            } else if let IrItem::Compound(inner) = item {
                self.collect_facets_nested(inner, out, seen, desc_map);
            }
        }
    }

    fn emit_facets_for_scope(
        self,
        items: &[IrItem],
        scope: &str,
        params: &[IrParam],
        desc_locals: &std::collections::HashMap<String, crate::checked::ValueType>,
        out: &mut Vec<String>,
        seen: &mut std::collections::HashSet<String>,
    ) {
        use std::collections::{HashMap, HashSet};
        let has_gosub = crate::c_emit_hoist::has_gosub(items);
        let mut array_dimmed: HashSet<String> = HashSet::new();
        crate::c_emit_hoist::collect_array_dimmed_names(items, &mut array_dimmed);
        let dual_use = crate::c_emit_hoist::collect_dual_use(items, &array_dimmed);
        let dyn_names = crate::c_emit_hoist::collect_dyn_names(items, params, has_gosub, desc_locals);
        let mut dim_info: HashMap<String, (bool, usize, ValueType, String)> = HashMap::new();
        for it in items {
            if let IrItem::Dim { symbol, size, extra_dims, is_array, shared, .. } = it {
                if *is_array {
                    let rank = if size.is_some() {
                        1 + extra_dims.len()
                    } else if extra_dims.is_empty() {
                        1
                    } else {
                        extra_dims.len()
                    };
                    let is_shared = *shared;
                    let storage = if is_shared {
                        "shared".to_string()
                    } else if dyn_names.arrays.contains_key(&symbol.name) {
                        "dyn".to_string()
                    } else {
                        "fixed".to_string()
                    };
                    dim_info.insert(symbol.name.clone(), (is_shared, rank, symbol.value_type, storage));
                }
            }
        }
        for (name, (is_shared, rank, vt, storage)) in &dim_info {
            let key = format!("{}:{}", name, scope);
            if !seen.insert(key) {
                continue;
            }
            let dual = if dual_use.contains(name) { 1 } else { 0 };
            let sh = if *is_shared { " shared" } else { "" };
            out.push(format!(
                "facet {}:{} scope={} storage={} rank={} dual={}{}",
                name,
                self.emit_type(*vt),
                scope,
                storage,
                rank,
                dual,
                sh
            ));
        }
        for (name, vt) in desc_locals {
            let key = format!("{}:{}", name, scope);
            if seen.contains(&key) {
                continue;
            }
            if dim_info.contains_key(name) {
                continue;
            }
            seen.insert(key);
            let dual = if dual_use.contains(name) { 1 } else { 0 };
            out.push(format!(
                "facet {}:{} scope={} storage=dyn rank=1 dual={}",
                name,
                self.emit_type(*vt),
                scope,
                dual
            ));
        }
        for p in params {
            if p.is_array {
                let key = format!("{}:{}", p.name, scope);
                if !seen.insert(key) {
                    continue;
                }
                let rank = 1;
                let dual = if dual_use.contains(&p.name) { 1 } else { 0 };
                out.push(format!(
                    "facet {}:{} scope={} storage=param rank={} dual={}",
                    p.name,
                    self.emit_type(p.value_type),
                    scope,
                    rank,
                    dual
                ));
            }
        }
    }


    #[allow(dead_code)]
    fn collect_facets(
        self,
        items: &[IrItem],
        scope: &str,
        out: &mut Vec<String>,
        seen: &mut std::collections::HashSet<String>,
    ) {
        for item in items {
            match item {
                IrItem::Dim {
                    symbol,
                    size,
                    extra_dims,
                    is_array,
                    shared,
                    ..
                } => {
                    if *is_array {
                        let rank = if size.is_some() {
                            1 + extra_dims.len()
                        } else {
                            extra_dims.len()
                        };
                        let storage = if size.is_none() && extra_dims.is_empty() {
                            "dyn"
                        } else {
                            "fixed"
                        };
                        let key = format!("{}:{}", symbol.name, scope);
                        if seen.insert(key) {
                            let sh = if *shared { " shared" } else { "" };
                            out.push(format!(
                                "facet {}:{} scope={} storage={} rank={} dual=0{}",
                                symbol.name,
                                self.emit_type(symbol.value_type),
                                scope,
                                storage,
                                rank,
                                sh
                            ));
                        }
                    }
                }
                IrItem::Function {
                    name, body, ..
                } => {
                    self.collect_facets(body, name, out, seen);
                }
                IrItem::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    self.collect_facets(then_body, scope, out, seen);
                    if let Some(eb) = else_body {
                        self.collect_facets(eb, scope, out, seen);
                    }
                }
                IrItem::While { body, .. }
                | IrItem::For { body, .. }
                | IrItem::DoLoop { body, .. } => {
                    self.collect_facets(body, scope, out, seen);
                }
                _ => {}
            }
        }
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
