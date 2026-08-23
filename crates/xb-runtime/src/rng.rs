use std::cell::Cell;

thread_local! {
    static RAND_STATE: Cell<u64> = const { Cell::new(0x853a49d51c4e0a8b) };
}

pub(crate) fn next_rand() -> f64 {
    RAND_STATE.with(|s| {
        let mut state = s.get();
        state = state
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);
        s.set(state);
        (state >> 11) as f64 / (1u64 << 53) as f64
    })
}

#[allow(dead_code)]
pub(crate) fn randomize(seed: i32) {
    RAND_STATE.with(|s| s.set(seed as u64 | 1));
}
