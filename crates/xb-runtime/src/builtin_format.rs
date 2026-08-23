use crate::slot::{RuntimeError, RuntimeValue};
use xb_compiler::ValueType;

/// FORMAT$(format$, argument) — format a numeric or string argument.
/// Numeric format spec: # digit positions, . decimal point, , commas,
///   ^^^^ short exponent, ^^^^^ long exponent, $ leading dollar,
///   * leading zeros with *, 0 leading zeros, + leading/trailing sign,
///   - trailing minus, (###) negatives in parens, _ literal next char.
/// String format spec: & exact, < left justify, > right justify, | center.
pub(crate) fn eval_format(args: &[RuntimeValue]) -> Result<RuntimeValue, RuntimeError> {
    let RuntimeValue::String(fmt) = &args[0] else {
        return Err(type_err(args[0].value_type()));
    };
    let fmt = String::from_utf8_lossy(fmt);
    match &args[1] {
        RuntimeValue::String(s) => Ok(RuntimeValue::from_string(format_string(
            &fmt,
            &String::from_utf8_lossy(s),
        ))),
        RuntimeValue::Integer(n) => {
            Ok(RuntimeValue::from_string(format_num(&fmt, *n as f64, false)))
        }
        RuntimeValue::Giant(n) => {
            Ok(RuntimeValue::from_string(format_num(&fmt, *n as f64, false)))
        }
        RuntimeValue::Float(f) => Ok(RuntimeValue::from_string(format_num(&fmt, *f, true))),
    }
}

fn format_string(fmt: &str, s: &str) -> String {
    let chars: Vec<char> = fmt.chars().collect();
    if chars.is_empty() {
        return s.to_string();
    }
    match chars[0] {
        '&' => s.to_string(),
        '<' => {
            let w = chars.iter().filter(|c| **c == '<').count();
            if s.len() >= w {
                s[..w].to_string()
            } else {
                format!("{s:<w$}", w = w)
            }
        }
        '>' => {
            let w = chars.iter().filter(|c| **c == '>').count();
            if s.len() >= w {
                s[s.len() - w..].to_string()
            } else {
                format!("{s:>w$}", w = w)
            }
        }
        '|' => {
            let w = chars.iter().filter(|c| **c == '|').count();
            if s.len() >= w {
                s[..w].to_string()
            } else {
                let total = w - s.len();
                let left = total / 2;
                let right = total - left;
                format!("{}{}{}", " ".repeat(left), s, " ".repeat(right))
            }
        }
        _ => s.to_string(),
    }
}

fn format_num(fmt: &str, val: f64, is_float: bool) -> String {
    let chars: Vec<char> = fmt.chars().collect();
    let mut int_digits = 0usize;
    let mut frac_digits = 0usize;
    let mut has_decimal = false;
    let mut has_commas = false;
    let mut dollar = false;
    let mut star_fill = false;
    let mut zero_fill = false;
    let mut leading_plus = false;
    let mut trailing_plus = false;
    let mut trailing_minus = false;
    let mut paren_neg = false;
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        match c {
            '#' => {
                if has_decimal {
                    frac_digits += 1;
                } else {
                    int_digits += 1;
                }
            }
            '.' => has_decimal = true,
            ',' => has_commas = true,
            '$' => dollar = true,
            '*' => star_fill = true,
            '0' => zero_fill = true,
            '+' => {
                if int_digits > 0 {
                    trailing_plus = true;
                } else {
                    leading_plus = true;
                }
            }
            '-' => {
                if int_digits > 0 {
                    trailing_minus = true;
                }
            }
            '(' => paren_neg = true,
            '_' => i += 1,
            _ => {}
        }
        i += 1;
    }
    if int_digits == 0 && frac_digits == 0 && !star_fill && !zero_fill {
        return format!("{val}");
    }
    let neg = val < 0.0;
    let abs_val = val.abs();
    let int_part = abs_val.trunc() as i64;
    let frac_part = if has_decimal && frac_digits > 0 {
        format!("{:.*}", frac_digits, abs_val.fract())
    } else if has_decimal {
        String::new()
    } else if is_float {
        format!("{}", abs_val.fract())
    } else {
        String::new()
    };
    let mut int_str = int_part.to_string();
    if has_commas {
        int_str = add_commas(&int_str);
    }
    let fill_char = if star_fill {
        '*'
    } else if zero_fill {
        '0'
    } else {
        ' '
    };
    while int_str.len() < int_digits {
        int_str = format!("{fill_char}{int_str}");
    }
    let mut result = String::new();
    if paren_neg && neg {
        result.push('(');
    } else if leading_plus {
        result.push(if neg { '-' } else { '+' });
    } else if neg && !trailing_plus && !trailing_minus {
        result.push('-');
    }
    if dollar {
        result.push('$');
    }
    result.push_str(&int_str);
    if has_decimal {
        result.push('.');
        if !frac_part.is_empty() {
            let frac_clean = frac_part.trim_start_matches("0.");
            result.push_str(frac_clean);
        }
    }
    if paren_neg && neg {
        result.push(')');
    } else if trailing_plus {
        result.push(if neg { '-' } else { '+' });
    } else if trailing_minus && neg {
        result.push('-');
    }
    result
}

fn add_commas(s: &str) -> String {
    let mut result = String::new();
    let len = s.len();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (len - i).is_multiple_of(3) {
            result.push(',');
        }
        result.push(c);
    }
    result
}

fn type_err(actual: ValueType) -> RuntimeError {
    RuntimeError::TypeMismatch {
        expected: ValueType::String,
        actual,
    }
}
