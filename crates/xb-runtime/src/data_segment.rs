use crate::interpreter::DataEntry;
use crate::slot::ExecutionState;
use xb_compiler::IrProgram;

pub(crate) fn init_data_segment(program: &IrProgram, state: &mut ExecutionState) {
    for (tag, val) in &program.data_values {
        let entry = match tag.as_str() {
            "int" => DataEntry::Integer(val.parse().unwrap_or(0)),
            "float" => DataEntry::Float(val.parse().unwrap_or(0.0)),
            _ => DataEntry::String(val.clone()),
        };
        state.data_segment.push(entry);
    }
}

pub(crate) fn exec_read(
    symbols: &[xb_compiler::IrSymbol],
    state: &mut ExecutionState,
) -> Result<(), crate::interpreter::RuntimeError> {
    use crate::interpreter::{DataEntry, RuntimeError, RuntimeValue};
    for sym in symbols {
        if state.data_pos >= state.data_segment.len() {
            return Err(RuntimeError::UnknownSlot {
                name: sym.name.clone(),
            });
        }
        let entry = &state.data_segment[state.data_pos];
        state.data_pos += 1;
        let val = match entry {
            DataEntry::Integer(n) => RuntimeValue::Integer(*n),
            DataEntry::Giant(n) => RuntimeValue::Giant(*n),
            DataEntry::Float(f) => RuntimeValue::Float(*f),
            DataEntry::String(s) => RuntimeValue::from_string(s.clone()),
        };
        if !state.slots.contains_key(&sym.name) {
            state.slots.insert(
                sym.name.clone(),
                crate::slot::TypedSlot::new(sym.value_type),
            );
        }
        let slot = state.slots.get_mut(&sym.name).unwrap();
        slot.value = val;
    }
    Ok(())
}

pub(crate) fn exec_restore(state: &mut ExecutionState) {
    state.data_pos = 0;
}
