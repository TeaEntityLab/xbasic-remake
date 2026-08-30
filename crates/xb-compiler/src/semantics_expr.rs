use xb_frontend::{ArithmeticOp, BooleanOp, ComparisonOp, Expression};

use crate::checked::{CheckedExpr, CheckedExprKind, CheckedItem, CheckedSymbol};
use crate::semantics::{Analyzer, CompositeLayout, ExprResult, ItemResult, ValueType};

/// The value type for a symbol reference. Uses the explicit `suffix` when the
/// lexer separated one; otherwise infers from a trailing type char embedded in
/// `name`. A `#`-prefixed `SharedName` embeds its suffix in the name with
/// `suffix: None` (`#foo$` lexes to name `"foo$"`), so `from_suffix(None)` would
/// wrongly type it Integer and a `"s" + #foo$` concat / `#foo$ = "x"` assign
/// would raise a spurious type mismatch. Mirrors `auto_symbol`. A plain
/// `Identifier` never reaches here with `suffix: None` *and* a trailing `$`/`!`/`#`
/// (the lexer separates those), so inspecting the last char is safe.
pub(crate) fn ref_value_type(name: &str, suffix: Option<xb_frontend::TypeSuffix>) -> ValueType {
    match suffix {
        Some(_) => ValueType::from_suffix(suffix),
        None => match name.chars().last() {
            Some('$') => ValueType::String,
            Some('!') | Some('#') => ValueType::Float,
            _ => ValueType::Integer,
        },
    }
}

impl Analyzer {
    pub(crate) fn expr(&self, expr: &Expression) -> ExprResult {
        match expr {
            Expression::IntegerLiteral(v) => {
                // A DECIMAL literal that overflows signed 32-bit is a GIANT
                // (XstStringToNumber spec). Hex/binary/octal are bit-patterns and
                // stay XLONG (i32) — e.g. `0xEDB88320` is -1, not 3_988_292_384.
                let is_radix = ["0x", "0X", "0b", "0B", "0o", "0O"]
                    .iter()
                    .any(|p| v.starts_with(p));
                let vt = match (is_radix, v.parse::<i64>()) {
                    (false, Ok(n)) if n > i32::MAX as i64 || n < i32::MIN as i64 => {
                        ValueType::Giant
                    }
                    _ => ValueType::Integer,
                };
                Ok(CheckedExpr::new(
                    CheckedExprKind::IntegerLiteral(v.clone()),
                    vt,
                ))
            }
            Expression::FloatLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::FloatLiteral(v.clone()),
                ValueType::Float,
            )),
            Expression::StringLiteral(v) => Ok(CheckedExpr::new(
                CheckedExprKind::StringLiteral(v.clone()),
                ValueType::String,
            )),
            Expression::SystemConstant { name } => self.constant(name),
            Expression::SystemVariable { name, suffix } => self.shared_variable(name, *suffix),
            Expression::Identifier { name, suffix } => self.symbol(name, *suffix),
            Expression::ByRefIdentifier { name, suffix } => self.byref_symbol(name, *suffix),
            Expression::Comparison { op, left, right } => self.comparison(*op, left, right),
            Expression::Arithmetic { op, left, right } => self.arithmetic(*op, left, right),
            Expression::Not(inner) => self.not_expr(inner),
            Expression::Unary { op, operand } => self.unary(*op, operand),
            Expression::Boolean { op, left, right } => self.boolean(*op, left, right),
            Expression::Logical { op, left, right } => self.logical(*op, left, right),
            Expression::FunctionCall { name, args } => self.function_call(name, args),
            Expression::ArrayAccess {
                name,
                index,
                extra_indices,
            } => self.array_access(name, index, extra_indices),
            Expression::ArrayRef { name } => self.array_ref(name),
            Expression::FuncAddr(name) => self.func_addr(name),
        }
    }

    fn func_addr(&self, name: &str) -> ExprResult {
        // `&Func()` — address of a function; an intptr-sized id resolved at runtime.
        Ok(CheckedExpr::new(
            CheckedExprKind::FuncAddr(name.to_owned()),
            ValueType::Integer,
        ))
    }

    pub(crate) fn array_access(
        &self,
        name: &str,
        index: &Expression,
        extra: &[Expression],
    ) -> ExprResult {
        // A composite member array (a dotted leaf name like `library.name`) stores
        // its declared element type in `self.arrays`, NOT `self.symbols` — so
        // `auto_symbol` would default it to Integer (the member `name` carries no
        // `$`/`!`/`#` suffix). Prefer the declared array element type so e.g. a
        // `SHARED DLL library[]` read `library[i].name` (String member) emits
        // `xb_str_library_name`, not an undeclared `xb_var_library_name`.
        // When the array is a SHARED global not dimmed in this function
        // (`XxxGetSymbolInfo` sees `m_addr$` param shadowing global `m_addr[]`),
        // `self.arrays.get` misses and `auto_symbol` would incorrectly return
        // the param's String type for `m_addr[tokNumber]` (no `$`), emitting
        // `xb_str_m_addr_arr` instead of `xb_var_m_addr_arr` (xcol 6 errors).
        // Infer from the identifier's own suffix; `m_addr` → Integer,
        // `m_addr$` → String, which matches the global array's declared type.
        let vt = self.arrays.get(name).copied().unwrap_or_else(|| {
            if name.contains('.') {
                // Dotted composite member (e.g. `host.alias` string member):
                // `self.arrays` holds the array facet; `auto_symbol` finds the
                // scalar facet's String type, which matches the array element
                // type (`host.alias:string` scalar vs `host.alias:string[]`).
                // Suffix inference would give Integer (`host.alias` no `$`).
                self.auto_symbol(name).value_type
            } else {
                // Non-dotted: infer from identifier's own suffix. When a SHARED
                // global `m_addr[]` (integer) is shadowed by param `m_addr$`
                // (string) in `XxxGetSymbolInfo`, `self.arrays.get` misses and
                // `auto_symbol("m_addr")` would incorrectly return String
                // (the param). `m_addr` with no `$` is Integer, `m_addr$` with
                // `$` is String, matching the global array's declared type.
                match name.chars().last() {
                    Some('$') => ValueType::String,
                    Some('!') | Some('#') => ValueType::Float,
                    _ => ValueType::Integer,
                }
            }
        });
        let sym = CheckedSymbol::new(name.to_owned(), vt);
        let idx = self.expr(index)?;
        let extra_indices = extra
            .iter()
            .map(|e| self.expr(e))
            .collect::<Result<Vec<_>, _>>()?;
        Ok(CheckedExpr::new(
            CheckedExprKind::ArrayAccess {
                symbol: sym,
                index: Box::new(idx),
                extra_indices,
            },
            vt,
        ))
    }

    fn array_ref(&self, name: &str) -> ExprResult {
        let sym = self.auto_symbol(name);
        let vt = sym.value_type;
        Ok(CheckedExpr::new(
            CheckedExprKind::ArrayRef { symbol: sym },
            vt,
        ))
    }

    fn comparison(&self, op: ComparisonOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        if !self.permissive && lv.value_type != rv.value_type {
            return Err(crate::checked::SemanticError::ComparisonTypeMismatch {
                left: lv.value_type,
                right: rv.value_type,
            });
        }
        Ok(CheckedExpr::new(
            CheckedExprKind::Comparison {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }

    fn arithmetic(&self, op: ArithmeticOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        let l_str = lv.value_type == ValueType::String;
        let r_str = rv.value_type == ValueType::String;
        if l_str && r_str && op == ArithmeticOp::Add {
            return Ok(CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op,
                    left: Box::new(lv),
                    right: Box::new(rv),
                },
                ValueType::String,
            ));
        }
        if l_str || r_str {
            if !self.permissive {
                return Err(crate::checked::SemanticError::ArithmeticStringOperand);
            }
            // Permissive: string operands are treated as 0 in numeric context.
            return Ok(CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op,
                    left: Box::new(lv),
                    right: Box::new(rv),
                },
                ValueType::Integer,
            ));
        }
        let has_giant = lv.value_type == ValueType::Giant || rv.value_type == ValueType::Giant;
        let has_float = lv.value_type == ValueType::Float || rv.value_type == ValueType::Float;
        // GIANT (i64) dominates INTEGER but yields to FLOAT (the interpreter widens
        // a Giant to f64 when the other operand is a Float — see arith.rs).
        let rt = if has_giant && !has_float {
            ValueType::Giant
        } else if op.is_integer_op() || !has_float {
            ValueType::Integer
        } else {
            ValueType::Float
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::Arithmetic {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            rt,
        ))
    }

    fn not_expr(&self, inner: &Expression) -> ExprResult {
        let v = self.expr(inner)?;
        // Allow any type in NOT (XBasic treats strings as boolean)
        Ok(CheckedExpr::new(
            CheckedExprKind::Not(Box::new(v)),
            ValueType::Integer,
        ))
    }

    fn unary(&self, op: xb_frontend::UnaryOp, operand: &Expression) -> ExprResult {
        let v = self.expr(operand)?;
        let vt = match op {
            // POS is identity (interp `Pos => v`): the result keeps the operand's
            // type, so `+s$` stays String and `arith(+s$ + "!")` concatenates
            // (rather than being mis-typed Integer, which crashes the interp and
            // emits `+`-on-`char*` in C — xrun.x `+ log$ + …`).
            xb_frontend::UnaryOp::Pos => v.value_type,
            // NEG on a String is a runtime error; type it Integer (numeric default).
            xb_frontend::UnaryOp::Neg => match v.value_type {
                ValueType::String => ValueType::Integer,
                other => other,
            },
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::Unary {
                op,
                operand: Box::new(v),
            },
            vt,
        ))
    }

    fn boolean(&self, op: BooleanOp, l: &Expression, r: &Expression) -> ExprResult {
        let lv = self.expr(l)?;
        let rv = self.expr(r)?;
        // Allow any type in boolean ops (XBasic treats strings as boolean)
        Ok(CheckedExpr::new(
            CheckedExprKind::Boolean {
                op,
                left: Box::new(lv),
                right: Box::new(rv),
            },
            ValueType::Integer,
        ))
    }
    /// Per-element layout if the expression names a composite type or a
    /// composite variable (scalar or array reference).
    fn composite_layout_of(&self, expr: &Expression) -> Option<&CompositeLayout> {
        let name = match expr {
            Expression::Identifier { name, .. } => name,
            Expression::ArrayRef { name } => name,
            _ => return None,
        };
        if let Some(layout) = self.composites.get(name) {
            return Some(layout);
        }
        let type_name = self.composite_vars.get(name)?;
        self.composites.get(type_name)
    }

    /// SIZE() of a composite type/variable: per-element bytes for a scalar or
    /// type name, or per-element bytes times the element count for an array.
    fn composite_size(&self, expr: &Expression) -> Option<CheckedExpr> {
        let layout = self.composite_layout_of(expr)?;
        let byte_len = layout.byte_len;
        let len_lit = |n: usize| {
            CheckedExpr::new(
                CheckedExprKind::IntegerLiteral(n.to_string()),
                ValueType::Integer,
            )
        };
        if let Expression::ArrayRef { name } = expr {
            let member0 = layout.members.first()?;
            let member_sym =
                CheckedSymbol::new(format!("{name}.{}", member0.name), member0.value_type);
            let count = CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op: ArithmeticOp::Add,
                    left: Box::new(CheckedExpr::new(
                        CheckedExprKind::ArrayUBound { symbol: member_sym },
                        ValueType::Integer,
                    )),
                    right: Box::new(len_lit(1)),
                },
                ValueType::Integer,
            );
            return Some(CheckedExpr::new(
                CheckedExprKind::Arithmetic {
                    op: ArithmeticOp::Mul,
                    left: Box::new(len_lit(byte_len)),
                    right: Box::new(count),
                },
                ValueType::Integer,
            ));
        }
        Some(len_lit(byte_len))
    }

    pub(crate) fn function_call(&self, name: &str, args: &[Expression]) -> ExprResult {
        // Composite TYPE builtins resolve from the captured type layout.
        if name == "LEN" && args.len() == 1 {
            if let Some(layout) = self.composite_layout_of(&args[0]) {
                return Ok(CheckedExpr::new(
                    CheckedExprKind::IntegerLiteral(layout.byte_len.to_string()),
                    ValueType::Integer,
                ));
            }
        }
        if name == "SIZE" && args.len() == 1 {
            if let Some(result) = self.composite_size(&args[0]) {
                return Ok(result);
            }
        }
        if self.arrays.contains_key(name) && args.len() == 1 {
            let sym = self.auto_symbol(name);
            let vt = sym.value_type;
            let index = self.expr(&args[0])?;
            return Ok(CheckedExpr::new(
                CheckedExprKind::ArrayAccess {
                    symbol: sym,
                    index: Box::new(index),
                    extra_indices: Vec::new(),
                },
                vt,
            ));
        }
        if name == "UBOUND" && args.len() == 1 {
            // Composite array UBOUND resolves to its first member array.
            let composite_member0 = match &args[0] {
                Expression::Identifier { name, .. } | Expression::ArrayRef { name } => self
                    .composite_vars
                    .get(name)
                    .and_then(|tn| self.composites.get(tn))
                    .and_then(|layout| layout.members.first().map(|m| (name.clone(), m.clone()))),
                _ => None,
            };
            if let Some((var, m0)) = composite_member0 {
                return Ok(CheckedExpr::new(
                    CheckedExprKind::ArrayUBound {
                        symbol: CheckedSymbol::new(format!("{var}.{}", m0.name), m0.value_type),
                    },
                    ValueType::Integer,
                ));
            }
            if let Expression::ArrayRef { name: arr_name } = &args[0] {
                let sym = self.auto_symbol(arr_name);
                return Ok(CheckedExpr::new(
                    CheckedExprKind::ArrayUBound { symbol: sym },
                    ValueType::Integer,
                ));
            }
            if let Expression::Identifier { name: var_name, .. } = &args[0] {
                // UBOUND(var) for a string or array variable (last valid index).
                let sym = self.auto_symbol(var_name);
                return Ok(CheckedExpr::new(
                    CheckedExprKind::ArrayUBound { symbol: sym },
                    ValueType::Integer,
                ));
            }
        }
        if name == "SIZE" && args.len() == 1 {
            if let Expression::ArrayRef { name: arr_name } = &args[0] {
                let sym = self.auto_symbol(arr_name);
                return Ok(CheckedExpr::new(
                    CheckedExprKind::SizeOf { symbol: sym },
                    ValueType::Integer,
                ));
            }
            if let Expression::Identifier {
                name: var_name,
                suffix,
            } = &args[0]
            {
                let type_map = [
                    ("XLONG", ValueType::Integer),
                    ("SBYTE", ValueType::Integer),
                    ("UBYTE", ValueType::Integer),
                    ("SSHORT", ValueType::Integer),
                    ("USHORT", ValueType::Integer),
                    ("SLONG", ValueType::Integer),
                    ("ULONG", ValueType::Integer),
                    ("GIANT", ValueType::Integer),
                    ("DOUBLE", ValueType::Float),
                    ("SINGLE", ValueType::Float),
                    ("STRING", ValueType::String),
                ];
                for (tn, vt) in type_map {
                    if var_name.eq_ignore_ascii_case(tn) {
                        return Ok(CheckedExpr::new(
                            CheckedExprKind::SizeOfType { value_type: vt },
                            ValueType::Integer,
                        ));
                    }
                }
                // Resolve the variable exactly like a normal read (via `symbol`,
                // honoring the `$`/`!`/`#` suffix + slot-name/collision rules) so
                // the SizeOf symbol's name AND type match its slot — otherwise
                // `auto_symbol` drops the suffix and `SIZE(time$)` becomes an
                // Integer `time`, emitting an undeclared `xb_var_time`.
                let sym = match self.symbol(var_name, *suffix)?.kind {
                    CheckedExprKind::Symbol(s) => s,
                    _ => self.auto_symbol(var_name),
                };
                return Ok(CheckedExpr::new(
                    CheckedExprKind::SizeOf { symbol: sym },
                    ValueType::Integer,
                ));
            }
        }
        if (name == "SUBADDRESS" || name == "GOADDRESS") && args.len() == 1 {
            if let Expression::Identifier {
                name: label_name,
                suffix: None,
            } = &args[0]
            {
                return Ok(CheckedExpr::new(
                    CheckedExprKind::LabelAddress(label_name.clone()),
                    ValueType::Integer,
                ));
            }
        }
        if let Some(result) = self.type_conversion(name, args) {
            return result;
        }
        if let Some(rt) = crate::builtin::builtin_return_type(name) {
            return crate::builtin::builtin_call(self, name, args, rt);
        }
        // Brace-notation byte read: `s${i}` parses as a call `s$(i)`. When `s$`
        // is a declared scalar string variable, lower it to ASC(MID$(s, i+1, 1))
        // (the byte offset is 0-based; MID$ is 1-based).
        {
            let base = name.trim_end_matches('$');
            // Real builtins were dispatched above, so a `$`-suffixed 1-arg call
            // on a known (non-array, non-function) variable is a byte read. Use
            // `contains_key(base)` — not `== String` — so it also fires when an
            // Integer `string` and String `string$` collide (symbols[base] is
            // then Integer, but `string$` is still a byte-indexable string).
            if name.ends_with('$')
                && args.len() == 1
                && !self.functions.contains_key(name)
                && !self.arrays.contains_key(name)
                && self.symbols.contains_key(base)
            {
                return self.string_byte_read(base, &args[0]);
            }
            // `text${n}` on a STRING ARRAY: byte n of element 0 →
            // ASC(MID$(text$[0], n+1, 1)) — same composition, element base.
            if name.ends_with('$')
                && self.checked_symbol(name).map(|s| s.value_type) == Ok(ValueType::String)
                && !self.functions.contains_key(name)
            {
                let sym = self.auto_symbol(name);
                let idx = self.expr(&args[0])?;
                let one = CheckedExpr::new(
                    CheckedExprKind::IntegerLiteral("1".to_owned()),
                    ValueType::Integer,
                );
                let zero = CheckedExpr::new(
                    CheckedExprKind::IntegerLiteral("0".to_owned()),
                    ValueType::Integer,
                );
                let elem = CheckedExpr::new(
                    CheckedExprKind::ArrayAccess {
                        symbol: sym,
                        index: Box::new(zero),
                        extra_indices: Vec::new(),
                    },
                    ValueType::String,
                );
                let pos = CheckedExpr::new(
                    CheckedExprKind::Arithmetic {
                        op: ArithmeticOp::Add,
                        left: Box::new(idx),
                        right: Box::new(one.clone()),
                    },
                    ValueType::Integer,
                );
                let mid = CheckedExpr::new(
                    CheckedExprKind::FunctionCall {
                        name: "MID$".to_owned(),
                        args: vec![elem, pos, one],
                    },
                    ValueType::String,
                );
                return Ok(CheckedExpr::new(
                    CheckedExprKind::FunctionCall {
                        name: "ASC".to_owned(),
                        args: vec![mid],
                    },
                    ValueType::Integer,
                ));
            }
        }
        let (resolved_name, sig) = if let Some(s) = self.functions.get(name) {
            (name.to_owned(), s)
        } else {
            let with_suffix = format!("{name}$");
            match self.functions.get(&with_suffix) {
                Some(s) => (with_suffix, s),
                None => {
                    if let Some(extu) = self.scalar_bitfield_call(name, args) {
                        return extu;
                    }
                    if !self.permissive {
                        return Err(crate::checked::SemanticError::UnknownFunction {
                            name: name.to_owned(),
                        });
                    }
                    // Permissive: stub unknown functions (String for a $ suffix, else Integer).
                    let rt = if name.ends_with('$') {
                        ValueType::String
                    } else {
                        ValueType::Integer
                    };
                    let checked_args: Vec<CheckedExpr> = args
                        .iter()
                        .map(|a| self.call_arg(a))
                        .collect::<Result<_, _>>()?;
                    return Ok(CheckedExpr::new(
                        CheckedExprKind::FunctionCall {
                            name: name.to_owned(),
                            args: checked_args,
                        },
                        rt,
                    ));
                }
            }
        };
        let normalized = resolved_name.trim_end_matches('$').to_owned();
        if !self.permissive && args.len() != sig.params.len() {
            return Err(crate::checked::SemanticError::FunctionArgCount {
                name: normalized.clone(),
                expected: sig.params.len(),
                actual: args.len(),
            });
        }
        let checked = if sig.param_composites.iter().any(|c| c.is_some()) {
            let pc = sig.param_composites.clone();
            self.flatten_call_args(&pc, args)?
        } else {
            let mut checked = Vec::with_capacity(args.len());
            for (i, arg) in args.iter().enumerate() {
                let v = self.call_arg(arg)?;
                let expected = sig.params.get(i).copied().unwrap_or(ValueType::Integer);
                if !self.permissive && !types_coercible(v.value_type, expected) {
                    return Err(crate::checked::SemanticError::FunctionArgType {
                        name: normalized.clone(),
                        index: i,
                        expected,
                        actual: v.value_type,
                    });
                }
                // Coerce compatible mismatches (e.g. Integer -> Float).
                let v = if v.value_type != expected {
                    CheckedExpr::new(v.kind.clone(), expected)
                } else {
                    v
                };
                checked.push(v);
            }
            checked
        };
        Ok(CheckedExpr::new(
            CheckedExprKind::FunctionCall {
                name: normalized,
                args: checked,
            },
            sig.return_type,
        ))
    }

    fn symbol(&self, name: &str, suffix: Option<xb_frontend::TypeSuffix>) -> ExprResult {
        let full = xb_frontend::full_name(name.to_owned(), suffix);
        let suffix_vt = ref_value_type(name, suffix);
        // Single-`#` SharedName reads of shared-written names go to the shared
        // slot (checked first; a local DIM of the same name keeps the local).
        // Keyword-`SHARED` scalar declared in this scope: reads hit the
        // shared slot (classic BASIC).
        if self.shared_scalars.contains(&self.slot_name(name, suffix)) {
            let slot = self.slot_name(name, suffix);
            return self.shared_variable(slot.as_str(), None);
        }
        if let Some(shared) = self.shared_read_symbol(name, suffix) {
            return shared;
        }
        if !name.contains('.') && self.collisions.contains(name) {
            return Ok(CheckedExpr::new(
                CheckedExprKind::Symbol(CheckedSymbol::new(
                    self.slot_name(name, suffix),
                    suffix_vt,
                )),
                suffix_vt,
            ));
        }
        match self.checked_symbol(name) {
            Ok(s) => {
                // A composite member slot (dotted name) has an authoritative
                // declared type and no suffix; trust it. An unsuffixed name
                // also trusts the declared type — `DOUBLE a` in a function
                // parameter list declares `a` as Float, and referencing `a`
                // (no suffix) must resolve to Float, not the Integer default.
                // A differing *suffix* denotes a distinct variable (`v0` vs `v0$`).
                if suffix.is_none() || s.value_type == suffix_vt || name.contains('.') {
                    Ok(CheckedExpr::new(
                        CheckedExprKind::Symbol(s.clone()),
                        s.value_type,
                    ))
                } else {
                    // Type conflict: v0 (Integer) vs v0$ (String) — treat as different variable
                    Ok(CheckedExpr::new(
                        CheckedExprKind::Symbol(CheckedSymbol::new(full, suffix_vt)),
                        suffix_vt,
                    ))
                }
            }
            Err(_) => {
                if self.constants.contains_key(name) {
                    self.constant(name)
                } else if crate::builtin::is_zero_arg_builtin(&full) {
                    let rt = crate::builtin::builtin_return_type(&full).unwrap();
                    Ok(CheckedExpr::new(
                        CheckedExprKind::FunctionCall {
                            name: full,
                            args: vec![],
                        },
                        rt,
                    ))
                } else if !self.permissive {
                    Err(crate::checked::SemanticError::UnknownSymbol {
                        name: name.to_owned(),
                    })
                } else {
                    // Auto-declare unknown variables based on type suffix
                    Ok(CheckedExpr::new(
                        CheckedExprKind::Symbol(CheckedSymbol::new(name.to_owned(), suffix_vt)),
                        suffix_vt,
                    ))
                }
            }
        }
    }

    /// A single-`#` SharedName READ resolves through the shared slot when the
    /// name is written via `#name = value` anywhere in the program — legacy
    /// `#x` IS the shared scalar form. A local DIM of the same name keeps the
    /// local slot (decl+read pairing, e.g. acgibin's `XLONG #hStdOut` when no
    /// shared write exists). Only fires for bare names (no suffix split).
    fn shared_read_symbol(
        &self,
        name: &str,
        suffix: Option<xb_frontend::TypeSuffix>,
    ) -> Option<ExprResult> {
        if suffix.is_some() || !self.shared_writes.contains(name) {
            return None;
        }
        // A local declaration of this exact name pairs with the read: keep
        // the local slot (fall through to the normal symbol path).
        if self.symbols.contains_key(name) || self.arrays.contains_key(name) {
            return None;
        }
        Some(self.shared_variable(name, None))
    }

    fn byref_symbol(&self, name: &str, suffix: Option<xb_frontend::TypeSuffix>) -> ExprResult {
        let _suffix_vt = ref_value_type(name, suffix);
        // Keyword-`SHARED` scalar: the byref "address" is the shared slot's —
        // callee writebacks must land in `xb_shared_<name>` / state.shared.
        if self.shared_scalars.contains(&self.slot_name(name, suffix)) {
            let slot = self.slot_name(name, suffix);
            return self.shared_variable(slot.as_str(), None);
        }
        let _suffix_vt = ref_value_type(name, suffix);
        // sites (see `call_arg`), where write-back into the caller is meaningful.
        // Resolve the name exactly like `symbol()` so `@line$` (byref arg) and a
        // plain `line$` read canonicalize to the SAME slot on a type conflict
        // (an Integer `line` coexisting with a String `line$` → full name
        // `line$`); otherwise the writeback target and the reader diverge.
        let suffix_vt = ref_value_type(name, suffix);
        let sym = match self.checked_symbol(name) {
            Ok(s) if s.value_type == suffix_vt || name.contains('.') => s,
            Ok(_) => CheckedSymbol::new(xb_frontend::full_name(name.to_owned(), suffix), suffix_vt),
            Err(_) => CheckedSymbol::new(name.to_owned(), suffix_vt),
        };
        Ok(CheckedExpr::new(CheckedExprKind::Symbol(sym), suffix_vt))
    }

    /// Analyze a call argument, wrapping `@x` by-reference args in `ByRef` so the
    /// runtime writes the callee's final value back into the caller's lvalue.
    fn call_arg(&self, arg: &Expression) -> ExprResult {
        let checked = self.expr(arg)?;
        if matches!(arg, Expression::ByRefIdentifier { .. }) {
            let vt = checked.value_type;
            Ok(CheckedExpr::new(
                CheckedExprKind::ByRef(Box::new(checked)),
                vt,
            ))
        } else {
            Ok(checked)
        }
    }
    /// Flatten composite call arguments into scalar member arguments, matching the
    /// callee's flattened composite params. An `@`-composite arg produces ByRef
    /// members (per-member write-back); scalars pass through `call_arg`.
    fn flatten_call_args(
        &self,
        param_composites: &[Option<String>],
        args: &[Expression],
    ) -> Result<Vec<CheckedExpr>, crate::checked::SemanticError> {
        let mut out = Vec::new();
        for (i, arg) in args.iter().enumerate() {
            let composite = param_composites.get(i).and_then(|o| o.as_ref());
            if let Some(tn) = composite {
                if let Some(layout) = self.composites.get(tn).cloned() {
                    let (var, by_ref) = match arg {
                        Expression::Identifier { name, .. } => (Some(name.clone()), false),
                        Expression::ByRefIdentifier { name, .. } => (Some(name.clone()), true),
                        Expression::ArrayRef { name } => (Some(name.clone()), false),
                        _ => (None, false),
                    };
                    if let Some(var) = var {
                        let mut leaves = Vec::new();
                        self.flatten_composite(&var, &layout, &mut leaves);
                        for (mname, mvt) in leaves {
                            let sym = CheckedExpr::new(
                                CheckedExprKind::Symbol(CheckedSymbol::new(mname, mvt)),
                                mvt,
                            );
                            out.push(if by_ref {
                                CheckedExpr::new(CheckedExprKind::ByRef(Box::new(sym)), mvt)
                            } else {
                                sym
                            });
                        }
                        continue;
                    }
                }
            }
            out.push(self.call_arg(arg)?);
        }
        Ok(out)
    }

    pub(crate) fn call_stmt(&self, name: &str, args: &[Expression]) -> ItemResult {
        // Composite record I/O: `WRITE/READ [f], compositearr[]` transfers
        // SIZE(arr) bytes. SIZE is byte_len*(UBOUND(member0)+1), evaluated at
        // runtime, so a READ after re-DIM transfers the smaller count.
        let is_write = name.eq_ignore_ascii_case("WRITE");
        let is_read = name.eq_ignore_ascii_case("READ");
        if (is_write || is_read) && args.len() == 2 {
            if let Some(size) = self.composite_size(&args[1]) {
                let file = self.expr(&args[0])?;
                let record = if is_write {
                    "__WRITE_RECORD"
                } else {
                    "__READ_RECORD"
                };
                return Ok(CheckedItem::Call {
                    name: record.to_owned(),
                    args: vec![file, size],
                });
            }
        }
        let checked_call = self.function_call(name, args)?;
        let resolved = match checked_call.kind {
            CheckedExprKind::FunctionCall { ref name, .. } => name.clone(),
            _ => name.to_owned(),
        };
        let param_composites = self
            .funcaddr_member_param_composites(name)
            .or_else(|| self.functions.get(name).map(|s| s.param_composites.clone()))
            .unwrap_or_default();
        let checked_args = self.flatten_call_args(&param_composites, args)?;
        Ok(CheckedItem::Call {
            name: resolved,
            args: checked_args,
        })
    }

    /// If `name` is a `FUNCADDR` composite member (`dog.setName`), return the
    /// param-composite signature declared on the member's type so an indirect
    /// call flattens composite args the way the target function's params are.
    fn funcaddr_member_param_composites(&self, name: &str) -> Option<Vec<Option<String>>> {
        let (var, member) = name.rsplit_once('.')?;
        let type_name = self.composite_vars.get(var)?;
        let layout = self.composites.get(type_name)?;
        let m = layout.members.iter().find(|m| m.name == member)?;
        if m.funcaddr_params.is_empty() {
            return None;
        }
        Some(
            m.funcaddr_params
                .iter()
                .map(|t| self.composites.contains_key(t).then(|| t.clone()))
                .collect(),
        )
    }

    /// Scalar `{field}` / `{w, o}`: `curByte{$MODE}` parses as a call. When the
    /// name is a known non-function, non-array symbol, lower to `EXTU`.
    /// Array 1-arg FORTRAN index is handled earlier; 2-arg array stays a call.
    fn scalar_bitfield_call(&self, name: &str, args: &[Expression]) -> Option<ExprResult> {
        // `upper {11, 20}` parses as a call `upper(11, 20)`. When the name is
        // a known non-function, non-array scalar and ALL args are integer
        // literals (constant bitfield specs), lower to `EXTU(name, args…)`.
        // The all-integer-literal check avoids the xit dispatch regression where
        // `func(dispatch[i,1])` (indirect call via func variable with an array
        // access arg) was mis-identified as a bitfield extract.
        if !(1..=2).contains(&args.len()) {
            return None;
        }
        if self.arrays.contains_key(name) || self.functions.contains_key(name) {
            return None;
        }
        // All args must be integer literals — a bitfield spec like `{11, 20}`
        // or `{$MODE}`. Non-constant args (array access, identifier, etc.) mean
        // this is a real function call, not a bitfield extract.
        if !args
            .iter()
            .all(|a| matches!(a, Expression::IntegerLiteral(_)))
        {
            return None;
        }
        let is_scalar = self.symbols.contains_key(name)
            || self.shared.contains_key(name)
            || self.shared_scalars.contains(name);
        if !is_scalar {
            return None;
        }
        let mut extu_args = Vec::with_capacity(1 + args.len());
        extu_args.push(Expression::Identifier {
            name: name.to_owned(),
            suffix: None,
        });
        extu_args.extend_from_slice(args);
        Some(crate::builtin::builtin_call(
            self,
            "EXTU",
            &extu_args,
            ValueType::Integer,
        ))
    }

    /// Lower a brace-notation byte read `s${off}` to `ASC(MID$(s, off + 1, 1))`.
    fn string_byte_read(&self, var: &str, index: &Expression) -> ExprResult {
        // Resolve the string through the same path as a normal `s$` read so its
        // IR name matches the assignment target: on an Integer/String type
        // conflict (`raw` and `raw$`), both resolve to the full name `raw$`;
        // otherwise both stay bare. checked_symbol(bare) alone always returned
        // the bare name, mismatching the `raw$` assignment (afile/agrids/atools).
        let s_expr = self.symbol(var, Some(xb_frontend::TypeSuffix::String))?;
        let idx = self.expr(index)?;
        let one = CheckedExpr::new(
            CheckedExprKind::IntegerLiteral("1".to_owned()),
            ValueType::Integer,
        );
        let pos = CheckedExpr::new(
            CheckedExprKind::Arithmetic {
                op: ArithmeticOp::Add,
                left: Box::new(idx),
                right: Box::new(one.clone()),
            },
            ValueType::Integer,
        );
        let mid = CheckedExpr::new(
            CheckedExprKind::FunctionCall {
                name: "MID$".to_owned(),
                args: vec![s_expr, pos, one],
            },
            ValueType::String,
        );
        Ok(CheckedExpr::new(
            CheckedExprKind::FunctionCall {
                name: "ASC".to_owned(),
                args: vec![mid],
            },
            ValueType::Integer,
        ))
    }
}

/// A value type is numeric when it participates in implicit numeric coercion.
pub(crate) fn is_numeric_type(t: ValueType) -> bool {
    matches!(t, ValueType::Integer | ValueType::Float)
}

/// Types are coercible when identical or both numeric (Integer <-> Float).
/// String never coerces to a numeric type.
pub(crate) fn types_coercible(a: ValueType, b: ValueType) -> bool {
    a == b || (is_numeric_type(a) && is_numeric_type(b))
}
