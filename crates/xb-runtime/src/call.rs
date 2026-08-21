use std::collections::BTreeMap;
use xb_compiler::{IrExpr, IrExprKind, IrItem, IrParam, IrProgram, ValueType};
type FuncInfo<'a> = (&'a str, &'a [IrParam], &'a [IrItem], ValueType);

use crate::eval::eval;
use crate::interpreter::{exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue, TypedSlot};

/// The function id stored in slot `name`, if it holds a positive `&Func` id.
fn funcptr_slot_id(state: &ExecutionState, name: &str) -> Option<i32> {
    let slot = state.slots.get(name).or_else(|| state.shared.get(name))?;
    match slot.value() {
        RuntimeValue::Integer(id) if *id > 0 => Some(*id),
        _ => None,
    }
}

/// Name of the `id`-th top-level function (1-based), inverse of `eval::function_id`.
fn function_name_by_id(program: &IrProgram, id: i32) -> Option<String> {
    let mut cur = 0;
    for item in &program.items {
        if let IrItem::Function { name, .. } = item {
            cur += 1;
            if cur == id {
                return Some(name.clone());
            }
        }
    }
    None
}

pub(crate) fn call_function(
    program: &IrProgram,
    name: &str,
    args: &[IrExpr],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<RuntimeValue, RuntimeError> {
    match name {
        "READLINE$" => {
            if state.input_pos < state.input.len() {
                let line = state.input[state.input_pos].clone();
                state.input_pos += 1;
                return Ok(RuntimeValue::from_string(line));
            }
            return Ok(RuntimeValue::from_str(""));
        }
        "INLINE$" => {
            if let Some(IrExpr {
                kind: xb_compiler::IrExprKind::StringLiteral(prompt),
                ..
            }) = args.first()
            {
                output.push(prompt.clone());
            }
            if state.input_pos < state.input.len() {
                let line = state.input[state.input_pos].clone();
                state.input_pos += 1;
                return Ok(RuntimeValue::from_string(line));
            }
            return Ok(RuntimeValue::from_str(""));
        }
        "EOF" => {
            return Ok(RuntimeValue::Integer(
                if state.input_pos >= state.input.len() {
                    1
                } else {
                    0
                },
            ));
        }
        "VERSION$" => {
            return Ok(RuntimeValue::from_string(
                state.metadata.version.clone().unwrap_or_default(),
            ));
        }
        "PROGRAM$" => {
            return Ok(RuntimeValue::from_string(
                state.metadata.program_name.clone().unwrap_or_default(),
            ));
        }
        "OPEN" => {
            let arg0 = eval(program, &args[0], state, output)?;
            let arg1 = eval(program, &args[1], state, output)?;
            let RuntimeValue::String(name) = arg0 else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::String,
                    actual: arg0.value_type(),
                });
            };
            let name = String::from_utf8_lossy(&name).into_owned();
            let RuntimeValue::Integer(mode) = arg1 else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg1.value_type(),
                });
            };
            // Mode values from xst.dec: 0=RD,1=WR,2=RW,3=WRNEW,4=RWNEW, plus
            // share bits 0x10/0x20/0x30 and 0x800 nonblock. All modes create a
            // missing file; NEW/WR modes start it fresh.
            let write = matches!(mode, 1 | 2 | 3 | 4) || matches!(mode & 0x30, 0x20 | 0x30);
            let read = matches!(mode, 0 | 2 | 4) || matches!(mode & 0x30, 0x10 | 0x30) || !write;
            let truncate = matches!(mode, 1 | 3 | 4);
            match std::fs::OpenOptions::new()
                .read(read)
                .write(write)
                .create(write)
                .truncate(truncate)
                .open(&name)
            {
                Ok(f) => {
                    let fn_num = state.files.len() + 3;
                    state.files.push(Some(f));
                    return Ok(RuntimeValue::Integer(fn_num as i32));
                }
                Err(_) => return Ok(RuntimeValue::Integer(-1)),
            }
        }
        "CLOSE" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::Integer(fn_num) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() {
                return Ok(RuntimeValue::Integer(-1));
            }
            state.files[idx] = None;
            return Ok(RuntimeValue::Integer(0));
        }
        "__WRITE_RECORD" => {
            let f = eval(program, &args[0], state, output)?;
            let n = eval(program, &args[1], state, output)?;
            let (RuntimeValue::Integer(fn_num), RuntimeValue::Integer(count)) = (f, n) else {
                return Ok(RuntimeValue::Integer(-1));
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() || count < 0 {
                return Ok(RuntimeValue::Integer(-1));
            }
            use std::io::Write;
            let file = state.files[idx].as_mut().unwrap();
            let buf = vec![0u8; count as usize];
            let _ = file.write_all(&buf);
            return Ok(RuntimeValue::Integer(count));
        }
        "__READ_RECORD" => {
            let f = eval(program, &args[0], state, output)?;
            let n = eval(program, &args[1], state, output)?;
            let (RuntimeValue::Integer(fn_num), RuntimeValue::Integer(count)) = (f, n) else {
                return Ok(RuntimeValue::Integer(-1));
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() || count < 0 {
                return Ok(RuntimeValue::Integer(-1));
            }
            use std::io::Read;
            let file = state.files[idx].as_mut().unwrap();
            let mut buf = vec![0u8; count as usize];
            let got = file.read(&mut buf).unwrap_or(0);
            return Ok(RuntimeValue::Integer(got as i32));
        }
        "LOF" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::Integer(fn_num) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() {
                return Ok(RuntimeValue::Integer(-1));
            }
            use std::io::{Seek, SeekFrom};
            let f = state.files[idx].as_mut().unwrap();
            let cur = f.stream_position().unwrap_or(0);
            let len = f.seek(SeekFrom::End(0)).unwrap_or(0);
            let _ = f.seek(SeekFrom::Start(cur));
            return Ok(RuntimeValue::Integer(len as i32));
        }
        "POF" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::Integer(fn_num) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() {
                return Ok(RuntimeValue::Integer(-1));
            }
            use std::io::Seek;
            let pos = state.files[idx]
                .as_ref()
                .unwrap()
                .stream_position()
                .unwrap_or(0);
            return Ok(RuntimeValue::Integer(pos as i32));
        }
        "SEEK" => {
            let arg0 = eval(program, &args[0], state, output)?;
            let arg1 = eval(program, &args[1], state, output)?;
            let RuntimeValue::Integer(fn_num) = arg0 else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg0.value_type(),
                });
            };
            let RuntimeValue::Integer(pos) = arg1 else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg1.value_type(),
                });
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() {
                return Ok(RuntimeValue::Integer(-1));
            }
            use std::io::Seek;
            let r = state.files[idx]
                .as_mut()
                .unwrap()
                .seek(std::io::SeekFrom::Start(pos as u64));
            return Ok(RuntimeValue::Integer(r.map(|p| p as i32).unwrap_or(-1)));
        }
        "INFILE$" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::Integer(fn_num) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            let idx = (fn_num - 3) as usize;
            if idx >= state.files.len() || state.files[idx].is_none() {
                return Ok(RuntimeValue::from_str(""));
            }
            use std::io::Read;
            let mut buf: Vec<u8> = Vec::new();
            let f = state.files[idx].as_mut().unwrap();
            let mut byte = [0u8; 1];
            loop {
                match f.read(&mut byte) {
                    Ok(0) => break,
                    Ok(_) => {
                        if byte[0] == b'\n' {
                            break;
                        }
                        if byte[0] != b'\r' {
                            buf.push(byte[0]);
                        }
                    }
                    Err(_) => break,
                }
            }
            return Ok(RuntimeValue::String(buf));
        }
        "ERROR" | "ERROR$" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::Integer(n) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            if name == "ERROR" {
                let old = state.error_code;
                if n != -1 {
                    state.error_code = n;
                }
                return Ok(RuntimeValue::Integer(old));
            }
            return Ok(RuntimeValue::from_string(format!("error {n}")));
        }
        "QUIT" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::Integer(code) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            return Err(RuntimeError::Quit { code });
        }
        "SHELL" => {
            let arg = eval(program, &args[0], state, output)?;
            let RuntimeValue::String(cmd) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::String,
                    actual: arg.value_type(),
                });
            };
            let cmd = String::from_utf8_lossy(&cmd).into_owned();
            let code = std::process::Command::new("sh")
                .arg("-c")
                .arg(&cmd)
                .status()
                .map(|s| s.code().unwrap_or(-1))
                .unwrap_or(-1);
            return Ok(RuntimeValue::Integer(code));
        }
        "LIBRARY" => return Ok(RuntimeValue::Integer(0)),
        "XstStringToNumber" => return xst_string_to_number(program, args, state, output),
        "XstBackStringToBinString$" => {
            let s = match eval(program, &args[0], state, output)? {
                RuntimeValue::String(bytes) => bytes,
                other => other.render().into_bytes(),
            };
            return Ok(RuntimeValue::String(crate::xst::back_to_bin(&s)));
        }
        "XstQuickSort" => return xst_quicksort(program, args, state, output),
        "XstCopyArray" => return xst_copyarray(program, args, state, output),
        "XuiGetNextCallback" if args.len() >= 2 => {
            return gui_next_callback(args, state);
        }
        _ => {}
    }
    if is_builtin(name) {
        let mut vals = Vec::with_capacity(args.len());
        for arg in args {
            vals.push(eval(program, arg, state, output)?);
        }
        // Coerce a Giant argument to i32 where the builtin's declared parameter is
        // Integer (e.g. STR$/ABS), matching the C backends' parameter coercion
        // instead of erroring. Giant/Float/String-parameter builtins (e.g. GHIGH,
        // which legitimately take a Giant) are untouched.
        if let Some(params) = xb_compiler::builtin_param_types(name) {
            for (v, pt) in vals.iter_mut().zip(params) {
                if *pt == xb_compiler::ValueType::Integer {
                    if let RuntimeValue::Giant(g) = *v {
                        *v = RuntimeValue::Integer(g as i32);
                    }
                }
            }
        }
        return crate::builtin::eval_builtin(name, &vals);
    }
    let (fname, params, body, return_type) = match find_function(program, name) {
        Ok(info) => info,
        Err(_) => {
            // Indirect call through a FUNCADDR value: the callee name is a slot
            // holding a function id (from `&Func`); resolve it to the real target.
            if let Some(id) = funcptr_slot_id(state, name) {
                if let Some(target) = function_name_by_id(program, id) {
                    return call_function(program, &target, args, state, output);
                }
            }
            // Stub: unknown functions return 0 or empty string
            if name.ends_with('$') {
                return Ok(RuntimeValue::from_str(""));
            }
            return Ok(RuntimeValue::Integer(0));
        }
    };
    let mut local = BTreeMap::new();
    let mut ret_slot = TypedSlot::new(return_type);
    if return_type == ValueType::String {
        ret_slot.set(RuntimeValue::from_str(""));
    }
    local.insert(fname.to_string(), ret_slot);
    let mut writebacks: Vec<(String, String)> = Vec::new();
    for (p, arg) in params.iter().zip(args) {
        let mut slot = TypedSlot::new(p.value_type);
        // If the argument names an array (directly or via `@`), pass its storage
        // (elements + shape) into the callee so it can read/UBOUND/REDIM the array;
        // `@`-args are also written back after the call (see below).
        let arg_symbol = match &arg.kind {
            xb_compiler::IrExprKind::ByRef(inner) => match &inner.kind {
                xb_compiler::IrExprKind::Symbol(s) => Some(s),
                _ => None,
            },
            xb_compiler::IrExprKind::Symbol(s) => Some(s),
            _ => None,
        };
        let mut passed_array = false;
        if let Some(s) = arg_symbol {
            if let Some(src) = state.slots.get(&s.name).or_else(|| state.shared.get(&s.name)) {
                if src.array.is_some() {
                    slot.array = src.array.clone();
                    slot.dims = src.dims.clone();
                    passed_array = true;
                }
            }
        }
        if !passed_array {
            // Coerce each scalar argument to the parameter type (XBasic implicit coercion).
            let v = crate::helpers::coerce_value(eval(program, arg, state, output)?, p.value_type);
            slot.set(v);
        }
        local.insert(p.name.clone(), slot);
        // `@x` (by-ref): record the caller lvalue to write the param back into.
        if let xb_compiler::IrExprKind::ByRef(inner) = &arg.kind {
            if let xb_compiler::IrExprKind::Symbol(s) = &inner.kind {
                writebacks.push((p.name.clone(), s.name.clone()));
            }
        }
    }
    let mut sub = ExecutionState {
        metadata: state.metadata.clone(),
        slots: local,
        shared: state.shared.clone(),
        input: state.input.clone(),
        input_pos: state.input_pos,
        data_segment: Vec::new(),
        data_pos: 0,
        error_code: state.error_code,
        files: Vec::new(),
        label_addresses: std::collections::HashMap::new(),
        gui_close_sent: state.gui_close_sent,
    };
    let result = match exec_items(program, body, body, 0, &mut sub, output)? {
        Flow::Return(Some(v)) => Ok(v),
        Flow::Return(None) => {
            let ret = sub.slots.get(fname).map(|s| s.value.clone());
            Ok(ret.unwrap_or(RuntimeValue::Integer(0)))
        }
        _ => {
            let ret = sub.slots.get(fname).map(|s| s.value.clone());
            Ok(ret.unwrap_or(RuntimeValue::Integer(0)))
        }
    };
    state.input_pos = sub.input_pos;
    state.shared = sub.shared;
    state.error_code = sub.error_code;
    // Propagate by-ref (`@`) parameter results back into the caller's lvalues.
    for (pname, target) in &writebacks {
        if let Some(src) = sub.slots.get(pname) {
            if src.array.is_some() {
                // Array by-ref: write the (possibly REDIM'd) elements + shape back
                // into the caller's array so callee resize/fill propagates.
                let arr = src.array.clone();
                let dims = src.dims.clone();
                let vt = src.value_type;
                let dst = state
                    .slots
                    .entry(target.clone())
                    .or_insert_with(|| TypedSlot::new(vt));
                dst.array = arr;
                dst.dims = dims;
            } else {
                let val = src.value.clone();
                let vt = state
                    .slots
                    .get(target)
                    .map(|s| s.value_type())
                    .unwrap_or_else(|| val.value_type());
                let coerced = crate::helpers::coerce_value(val, vt);
                state
                    .slots
                    .entry(target.clone())
                    .or_insert_with(|| TypedSlot::new(vt))
                    .set(coerced);
            }
        }
    }
    result
}

/// `XstStringToNumber(s$, startOff, @afterOff, @rtype, @value$$)` — a by-ref
/// builtin whose out-params (2..4) write back into the caller's lvalues, so it
/// is dispatched here rather than through the by-value `eval_builtin` path.
fn xst_string_to_number(
    program: &IrProgram,
    args: &[IrExpr],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<RuntimeValue, RuntimeError> {
    let s = match eval(program, &args[0], state, output)? {
        RuntimeValue::String(bytes) => bytes,
        other => other.render().into_bytes(),
    };
    let start = match eval(program, &args[1], state, output)? {
        RuntimeValue::Integer(n) => n.max(0) as usize,
        RuntimeValue::Giant(n) => n.max(0) as usize,
        _ => 0,
    };
    let r = crate::xst::parse_number(&s, start);
    xst_write_back(&args[2], RuntimeValue::Integer(r.after), state);
    xst_write_back(&args[3], RuntimeValue::Integer(r.rtype), state);
    xst_write_back(&args[4], RuntimeValue::Giant(r.value), state);
    Ok(RuntimeValue::Integer(r.spec_type))
}

/// Write `val` (coerced to the lvalue's declared type) into the caller's slot
/// named by an `@arg` (`ByRef`) or a bare symbol / shared reference.
fn xst_write_back(expr: &IrExpr, val: RuntimeValue, state: &mut ExecutionState) {
    let target = match &expr.kind {
        IrExprKind::ByRef(inner) => &inner.kind,
        other => other,
    };
    let (name, vt, shared) = match target {
        IrExprKind::Symbol(s) => (s.name.clone(), s.value_type, false),
        IrExprKind::SharedVariable(s) => (s.name.clone(), s.value_type, true),
        _ => return,
    };
    let coerced = crate::helpers::coerce_value(val, vt);
    let table = if shared { &mut state.shared } else { &mut state.slots };
    table
        .entry(name)
        .or_insert_with(|| TypedSlot::new(vt))
        .set(coerced);
}

/// Resolve an `@array[]` (or bare array) argument to its caller slot name and
/// whether it lives in the shared table.
fn array_lvalue(expr: &IrExpr) -> (String, bool) {
    let inner = match &expr.kind {
        IrExprKind::ByRef(b) => &b.kind,
        k => k,
    };
    match inner {
        IrExprKind::Symbol(s) => (s.name.clone(), false),
        IrExprKind::SharedVariable(s) => (s.name.clone(), true),
        _ => (String::new(), false),
    }
}

fn slot_array(state: &ExecutionState, name: &str, shared: bool) -> Vec<RuntimeValue> {
    let tbl = if shared { &state.shared } else { &state.slots };
    tbl.get(name).and_then(|s| s.array.clone()).unwrap_or_default()
}

/// `XstQuickSort(@a[], @n[], low, high, mode)` — stably sort `a[low..=high]` in
/// place and, if `n[]` is a non-empty array, fill it with the permutation (resized
/// to match `a[]`). Runs in the caller's state → the `@` arrays mutate directly.
fn xst_quicksort(
    program: &IrProgram,
    args: &[IrExpr],
    state: &mut ExecutionState,
    output: &mut Vec<String>,
) -> Result<RuntimeValue, RuntimeError> {
    let idx_of = |v: RuntimeValue| -> usize {
        match v {
            RuntimeValue::Integer(n) => n.max(0) as usize,
            RuntimeValue::Giant(n) => n.max(0) as usize,
            RuntimeValue::Float(n) => n.max(0.0) as usize,
            RuntimeValue::String(_) => 0,
        }
    };
    let low = idx_of(eval(program, &args[2], state, output)?);
    let high = idx_of(eval(program, &args[3], state, output)?);
    let mode = match eval(program, &args[4], state, output)? {
        RuntimeValue::Integer(n) => n as i64,
        RuntimeValue::Giant(n) => n,
        _ => 0,
    };
    let (a_name, a_shared) = array_lvalue(&args[0]);
    let elems = slot_array(state, &a_name, a_shared);
    let (sorted, perm) = crate::xst::quicksort(&elems, low, high, mode);
    let sorted_len = sorted.len();
    {
        let tbl = if a_shared { &mut state.shared } else { &mut state.slots };
        if let Some(slot) = tbl.get_mut(&a_name) {
            slot.array = Some(sorted);
        }
    }
    let (n_name, n_shared) = array_lvalue(&args[1]);
    let tbl = if n_shared { &mut state.shared } else { &mut state.slots };
    if let Some(slot) = tbl.get_mut(&n_name) {
        if slot.array.as_ref().is_some_and(|a| !a.is_empty()) {
            slot.array = Some(perm.iter().map(|&x| RuntimeValue::Integer(x as i32)).collect());
            slot.dims = vec![sorted_len];
        }
    }
    Ok(RuntimeValue::Integer(0))
}

/// `XstCopyArray(@src[], @dst[])` — resize `dst[]` to `src[]`'s length and copy.
fn xst_copyarray(
    _program: &IrProgram,
    args: &[IrExpr],
    state: &mut ExecutionState,
    _output: &mut Vec<String>,
) -> Result<RuntimeValue, RuntimeError> {
    let (src_name, src_shared) = array_lvalue(&args[0]);
    let (dst_name, dst_shared) = array_lvalue(&args[1]);
    let src = slot_array(state, &src_name, src_shared);
    let len = src.len();
    let tbl = if dst_shared { &mut state.shared } else { &mut state.slots };
    if let Some(slot) = tbl.get_mut(&dst_name) {
        slot.array = Some(src);
        slot.dims = vec![len];
    }
    Ok(RuntimeValue::Integer(0))
}

/// Headless `XuiGetNextCallback(@grid, @message$, …)`: the real Xgr/Xui libraries
/// (winit + softbuffer, docs/12) are not linked, so rather than block on a display
/// event loop, deliver a single synthetic `CloseWindow` — the demos' loops `QUIT`
/// on it — then FALSE. This lets every GUI demo run to completion + become
/// differential-testable (interp==cgen). Writes exactly `@grid` (nonzero handle)
/// and `@message$` (mirrors cgen's `xb_gui_next_callback`); all other Xgr*/Xui*
/// keep the existing unknown-callee stub (`$`→"", else 0), already faithful.
fn gui_next_callback(
    args: &[IrExpr],
    state: &mut ExecutionState,
) -> Result<RuntimeValue, RuntimeError> {
    if state.gui_close_sent {
        return Ok(RuntimeValue::Integer(0));
    }
    state.gui_close_sent = true;
    xst_write_back(&args[0], RuntimeValue::Integer(1), state);
    xst_write_back(&args[1], RuntimeValue::String(b"CloseWindow".to_vec()), state);
    Ok(RuntimeValue::Integer(-1))
}

fn find_function<'a>(program: &'a IrProgram, name: &str) -> Result<FuncInfo<'a>, RuntimeError> {
    for item in &program.items {
        if let IrItem::Function {
            name: fname,
            params,
            body,
            return_type,
        } = item
        {
            if fname == name {
                return Ok((fname, params, body, *return_type));
            }
        }
    }
    Err(RuntimeError::UnknownFunction {
        name: name.to_owned(),
    })
}

fn is_builtin(name: &str) -> bool {
    crate::is_builtin::is_builtin(name)
}
