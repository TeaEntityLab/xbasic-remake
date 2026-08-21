//! `XstStringToNumber` — parse a number out of a string, matching the legacy
//! XBasic runtime (spec: `xbasic-6.4.5/help/misc.hlp`, decl `xst.dec:254`,
//! reference asm `xbasic-6.4.5/src/linux/lib/xlib.s`).
//!
//! Contract (from the `msc.x` `MscStringTo*` wrappers, the real consumers):
//!   `specType = XstStringToNumber(s$, startOff, @afterOff, @rtype, @value$$)`
//!   * `specType` — 0 on success (no explicit type), -1 on numeric-format error.
//!   * `afterOff` — offset just past the parsed number (or the offending byte
//!     on error).
//!   * `rtype`    — natural type: SLONG(6)/XLONG(8)/GIANT(12)/DOUBLE(14).
//!   * `value$$`  — a GIANT (i64) holding either the integer value or the raw
//!     f64 bits (extracted by the caller with `DMAKE(GHIGH,GLOW)` for DOUBLE).
//!
//! The whole helper is duplicated byte-for-byte in the C runtime
//! (`c_runtime.rs::emit_xst_runtime`) and the self-hosted generator
//! (`selfhost/cgen.x`); keep the three in lock-step (locked by the
//! `cgen_matches_interpreter_on_xst_string_to_number` differential test).

pub(crate) const RTYPE_ERROR: i32 = 0;
pub(crate) const RTYPE_SLONG: i32 = 6;
pub(crate) const RTYPE_XLONG: i32 = 8;
pub(crate) const RTYPE_GIANT: i32 = 12;
pub(crate) const RTYPE_DOUBLE: i32 = 14;

/// The four outputs of a parse (return value + the three `@` out-params).
pub(crate) struct XstNumber {
    pub spec_type: i32,
    pub after: i32,
    pub rtype: i32,
    pub value: i64,
}

impl XstNumber {
    fn error(at: usize) -> Self {
        Self {
            spec_type: -1,
            after: at as i32,
            rtype: RTYPE_ERROR,
            value: 0,
        }
    }
}

/// Natural type + `value$$` encoding for a parsed *integer* (the sign is
/// already folded in). SLONG if it fits signed 32-bit, XLONG if it fits
/// unsigned 32-bit, otherwise GIANT — matching the wrappers' extraction
/// (`GLOW` for SLONG, whole `value$$` for XLONG).
fn integer_result(val: i64, after: usize) -> XstNumber {
    let rtype = if (i32::MIN as i64..=i32::MAX as i64).contains(&val) {
        RTYPE_SLONG
    } else if (0..=u32::MAX as i64).contains(&val) {
        RTYPE_XLONG
    } else {
        RTYPE_GIANT
    };
    XstNumber {
        spec_type: 0,
        after: after as i32,
        rtype,
        value: val,
    }
}

fn hex_val(b: u8) -> Option<i64> {
    match b {
        b'0'..=b'9' => Some((b - b'0') as i64),
        b'a'..=b'f' => Some((b - b'a' + 10) as i64),
        b'A'..=b'F' => Some((b - b'A' + 10) as i64),
        _ => None,
    }
}

/// Parse `bytes[start..]`. See the module docs for the contract.
pub(crate) fn parse_number(bytes: &[u8], start: usize) -> XstNumber {
    let n = bytes.len();
    let mut i = start.min(n);
    // Skip leading whitespace + unprintable characters.
    while i < n && (bytes[i] <= b' ' || bytes[i] >= 0x7f) {
        i += 1;
    }
    let bad = i; // offset reported if nothing valid begins here
    let sign_start = i;

    // Optional leading sign.
    let neg = i < n && bytes[i] == b'-';
    if i < n && (bytes[i] == b'+' || bytes[i] == b'-') {
        i += 1;
    }

    // Radix prefixes: 0x / 0b / 0o (case-insensitive), always integers.
    if i + 1 < n && bytes[i] == b'0' {
        let radix = match bytes[i + 1] | 0x20 {
            b'x' => Some((16i64, true)),
            b'b' => Some((2, false)),
            b'o' => Some((8, false)),
            _ => None,
        };
        if let Some((radix, hex)) = radix {
            let ds = i + 2;
            let mut j = ds;
            let mut val: i64 = 0;
            while j < n {
                let d = if hex {
                    hex_val(bytes[j])
                } else if bytes[j].is_ascii_digit() && ((bytes[j] - b'0') as i64) < radix {
                    Some((bytes[j] - b'0') as i64)
                } else {
                    None
                };
                match d {
                    Some(d) => {
                        val = val.wrapping_mul(radix).wrapping_add(d);
                        j += 1;
                    }
                    None => break,
                }
            }
            if j == ds {
                // "0x"/"0b"/"0o" with no following digit.
                return XstNumber::error(bad);
            }
            if neg {
                val = val.wrapping_neg();
            }
            return integer_result(val, j);
        }
    }

    // Decimal integer or float.
    let mut j = i;
    let int_start = j;
    while j < n && bytes[j].is_ascii_digit() {
        j += 1;
    }
    let has_int = j > int_start;

    let mut is_float = false;
    let mut has_frac = false;
    if j < n && bytes[j] == b'.' {
        is_float = true;
        j += 1;
        let frac_start = j;
        while j < n && bytes[j].is_ascii_digit() {
            j += 1;
        }
        has_frac = j > frac_start;
    }

    // Need at least one digit somewhere (guards ".", "+", "e3").
    if !has_int && !has_frac {
        return XstNumber::error(bad);
    }

    // Optional exponent `[eE][+-]?digits` — only consumed if well-formed.
    if j < n && (bytes[j] | 0x20) == b'e' {
        let mut k = j + 1;
        if k < n && (bytes[k] == b'+' || bytes[k] == b'-') {
            k += 1;
        }
        if k < n && bytes[k].is_ascii_digit() {
            is_float = true;
            j = k;
            while j < n && bytes[j].is_ascii_digit() {
                j += 1;
            }
        }
    }

    let text = std::str::from_utf8(&bytes[sign_start..j]).unwrap_or("");
    if is_float {
        let f: f64 = text.parse().unwrap_or(0.0);
        XstNumber {
            spec_type: 0,
            after: j as i32,
            rtype: RTYPE_DOUBLE,
            value: f.to_bits() as i64,
        }
    } else {
        // Decimal integer; parse as i64 (sign included), wrapping on overflow.
        let digits = std::str::from_utf8(&bytes[int_start..j]).unwrap_or("");
        let mag: i64 = digits.parse().unwrap_or(0);
        let val = if neg { mag.wrapping_neg() } else { mag };
        integer_result(val, j)
    }
}
