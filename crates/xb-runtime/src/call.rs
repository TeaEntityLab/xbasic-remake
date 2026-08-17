use std::collections::BTreeMap;
use xb_compiler::{IrExpr, IrItem, IrParam, IrProgram, ValueType};
type FuncInfo<'a> = (&'a str, &'a [IrParam], &'a [IrItem], ValueType);

use crate::eval::eval;
use crate::interpreter::{exec_items, ExecutionState, Flow, RuntimeError, RuntimeValue, TypedSlot};

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
            let arg0 = eval(program, &args[0], state)?;
            let arg1 = eval(program, &args[1], state)?;
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
            let arg = eval(program, &args[0], state)?;
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
            let f = eval(program, &args[0], state)?;
            let n = eval(program, &args[1], state)?;
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
            let f = eval(program, &args[0], state)?;
            let n = eval(program, &args[1], state)?;
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
            let arg = eval(program, &args[0], state)?;
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
            let arg = eval(program, &args[0], state)?;
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
            let arg0 = eval(program, &args[0], state)?;
            let arg1 = eval(program, &args[1], state)?;
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
            let arg = eval(program, &args[0], state)?;
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
            let arg = eval(program, &args[0], state)?;
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
            let arg = eval(program, &args[0], state)?;
            let RuntimeValue::Integer(code) = arg else {
                return Err(RuntimeError::TypeMismatch {
                    expected: ValueType::Integer,
                    actual: arg.value_type(),
                });
            };
            return Err(RuntimeError::Quit { code });
        }
        "SHELL" => {
            let arg = eval(program, &args[0], state)?;
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
        _ => {}
    }
    if is_builtin(name) {
        let mut vals = Vec::with_capacity(args.len());
        for arg in args {
            vals.push(eval(program, arg, state)?);
        }
        return crate::builtin::eval_builtin(name, &vals);
    }
    let (fname, params, body, return_type) = match find_function(program, name) {
        Ok(info) => info,
        Err(_) => {
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
        // Coerce each argument to the parameter type (XBasic implicit coercion).
        let v = crate::helpers::coerce_value(eval(program, arg, state)?, p.value_type);
        let mut slot = TypedSlot::new(p.value_type);
        slot.set(v);
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
    result
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
