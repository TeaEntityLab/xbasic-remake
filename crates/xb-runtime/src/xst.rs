//! `XstStringToNumber` — parse a number out of a string, matching the legacy
//! XBasic runtime (spec: `xbasic/help/misc.hlp`, decl `xst.dec:254`,
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

/// `XstBackStringToBinString$` — convert XBasic backslash escapes to their
/// binary bytes (spec: `xbasic/help/xst.hlp`). Pure (no by-ref). Escapes:
/// `\"`→0x22, `\\`→0x5C, `\a\b\t\n\v\f\r`→07..0D, `\0`-`\9`→0x00-0x09,
/// `\A`-`\F`→0x0A-0x0F, `\G`-`\V`→0x10-0x1F, `\Z`→0xFF, `\xHH`→hex byte;
/// any other `\c` passes `c` literally. Duplicated byte-for-byte in the C
/// runtime (`c_runtime.rs::emit_back_to_bin_runtime`).
pub(crate) fn back_to_bin(bytes: &[u8]) -> Vec<u8> {
    let n = bytes.len();
    let mut out = Vec::with_capacity(n);
    let mut i = 0;
    while i < n {
        if bytes[i] == b'\\' && i + 1 < n {
            let c = bytes[i + 1];
            i += 2;
            match c {
                b'"' => out.push(0x22),
                b'\\' => out.push(0x5C),
                b'a' => out.push(0x07),
                b'b' => out.push(0x08),
                b't' => out.push(0x09),
                b'n' => out.push(0x0A),
                b'v' => out.push(0x0B),
                b'f' => out.push(0x0C),
                b'r' => out.push(0x0D),
                b'x' => {
                    let mut val: u8 = 0;
                    let mut k = 0;
                    while k < 2 && i < n {
                        let d = match bytes[i] {
                            h @ b'0'..=b'9' => h - b'0',
                            h @ b'a'..=b'f' => h - b'a' + 10,
                            h @ b'A'..=b'F' => h - b'A' + 10,
                            _ => break,
                        };
                        val = val.wrapping_mul(16).wrapping_add(d);
                        i += 1;
                        k += 1;
                    }
                    out.push(val);
                }
                b'0'..=b'9' => out.push(c - b'0'),
                b'A'..=b'F' => out.push(c - b'A' + 0x0A),
                b'G'..=b'V' => out.push(c - b'G' + 0x10),
                b'Z' => out.push(0xFF),
                other => out.push(other),
            }
        } else {
            out.push(bytes[i]);
            i += 1;
        }
    }
    out
}

use crate::interpreter::RuntimeValue;
use std::cmp::Ordering;

fn as_f64(v: &RuntimeValue) -> f64 {
    match v {
        RuntimeValue::Integer(n) => *n as f64,
        RuntimeValue::Giant(n) => *n as f64,
        RuntimeValue::Float(n) => *n,
        RuntimeValue::String(_) => 0.0,
    }
}

/// Compare two `XstQuickSort` elements (homogeneous typed array; mixed → numeric).
/// `ci` = case-insensitive strings.
fn xst_cmp(a: &RuntimeValue, b: &RuntimeValue, ci: bool) -> Ordering {
    match (a, b) {
        (RuntimeValue::Integer(x), RuntimeValue::Integer(y)) => x.cmp(y),
        (RuntimeValue::Giant(x), RuntimeValue::Giant(y)) => x.cmp(y),
        (RuntimeValue::Float(x), RuntimeValue::Float(y)) => {
            x.partial_cmp(y).unwrap_or(Ordering::Equal)
        }
        (RuntimeValue::String(x), RuntimeValue::String(y)) => {
            if ci {
                let lx: Vec<u8> = x.iter().map(|b| b.to_ascii_lowercase()).collect();
                let ly: Vec<u8> = y.iter().map(|b| b.to_ascii_lowercase()).collect();
                lx.cmp(&ly)
            } else {
                x.cmp(y)
            }
        }
        _ => as_f64(a).partial_cmp(&as_f64(b)).unwrap_or(Ordering::Equal),
    }
}

/// `XstQuickSort(@a[], @n[], low, high, mode)` core: stably sort `a[low..=high]`
/// (ties keep ascending original index), returning the reordered full array + the
/// permutation `n` (`n[new] = old`; outside `[low,high]` maps to self). `mode`
/// bit0 = decreasing, bit1 = case-insensitive.
pub(crate) fn quicksort(
    elems: &[RuntimeValue],
    low: usize,
    high: usize,
    mode: i64,
) -> (Vec<RuntimeValue>, Vec<i64>) {
    let len = elems.len();
    let mut result = elems.to_vec();
    let mut n: Vec<i64> = (0..len as i64).collect();
    if len == 0 || low > high || high >= len {
        return (result, n);
    }
    let decreasing = mode & 1 != 0;
    let ci = mode & 2 != 0;
    let mut idx: Vec<usize> = (low..=high).collect();
    idx.sort_by(|&i, &j| {
        let ord = xst_cmp(&elems[i], &elems[j], ci);
        let ord = if decreasing { ord.reverse() } else { ord };
        ord.then(i.cmp(&j))
    });
    for (k, &orig) in idx.iter().enumerate() {
        result[low + k] = elems[orig].clone();
        n[low + k] = orig as i64;
    }
    (result, n)
}
