pub fn fsin(value: f64) -> f64 {
    value.sin()
}

pub fn fcos(value: f64) -> f64 {
    value.cos()
}

pub fn fsqrt(value: f64) -> f64 {
    value.sqrt()
}

pub fn fptan(value: f64) -> f64 {
    value.tan()
}

pub fn fpatan(y: f64, x: f64) -> f64 {
    y.atan2(x)
}

pub fn fprem(value: f64, divisor: f64) -> f64 {
    value % divisor
}

pub fn fprem1(value: f64, divisor: f64) -> f64 {
    let quotient = (value / divisor).round_ties_even();
    value - (quotient * divisor)
}

pub fn fscale(value: f64, power: f64) -> f64 {
    value * 2.0_f64.powf(power.trunc())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_plain_f64_for_default_math_path() {
        assert_eq!(fsin(0.0), 0.0);
        assert_eq!(fcos(0.0), 1.0);
        assert_eq!(fsqrt(9.0), 3.0);
    }

    #[test]
    fn fprem1_uses_nearest_even_quotient() {
        assert_eq!(fprem1(5.5, 2.0), -0.5);
    }
}
