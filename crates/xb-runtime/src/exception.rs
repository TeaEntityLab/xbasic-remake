#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Signal {
    number: i32,
}

impl Signal {
    pub const fn new(number: i32) -> Self {
        Self { number }
    }

    pub const fn number(self) -> i32 {
        self.number
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Exception {
    None,
    Unknown,
    BreakKey,
    InvalidInstruction,
    Breakpoint,
    Alignment,
    InvalidOperation,
    SegmentViolation,
    Timer,
    StackOverflow,
    OutOfBounds,
    Denormal,
    DivideByZero,
    Overflow,
    StackCheck,
    Underflow,
    Privilege,
}

impl Exception {
    pub const fn from_xbasic_linux_signal(signal: Signal) -> Self {
        match signal.number() {
            0 => Self::None,
            1 => Self::Unknown,
            2 => Self::BreakKey,
            3 => Self::BreakKey,
            4 => Self::InvalidInstruction,
            5 => Self::Breakpoint,
            6 => Self::BreakKey,
            7 => Self::Alignment,
            8 => Self::InvalidOperation,
            9 => Self::Unknown,
            10 => Self::Unknown,
            11 => Self::SegmentViolation,
            12 => Self::Unknown,
            13 => Self::InvalidOperation,
            14 => Self::Timer,
            15 => Self::Unknown,
            16 => Self::StackOverflow,
            17 => Self::Unknown,
            18 => Self::Unknown,
            19 => Self::Unknown,
            20 => Self::Unknown,
            21 => Self::Unknown,
            22 => Self::Unknown,
            23 => Self::Unknown,
            24 => Self::Unknown,
            25 => Self::Unknown,
            26 => Self::Timer,
            27 => Self::Unknown,
            28 => Self::Unknown,
            29 => Self::Unknown,
            30 => Self::Unknown,
            31 => Self::Unknown,
            32 => Self::Unknown,
            35 => Self::Unknown,
            _ => Self::Unknown,
        }
    }

    pub const fn to_xbasic_linux_signal(self) -> Signal {
        match self {
            Self::SegmentViolation => Signal::new(11),
            Self::OutOfBounds => Signal::new(7),
            Self::Breakpoint => Signal::new(5),
            Self::BreakKey => Signal::new(2),
            Self::Alignment => Signal::new(7),
            Self::Denormal => Signal::new(8),
            Self::DivideByZero => Signal::new(8),
            Self::InvalidOperation => Signal::new(8),
            Self::Overflow => Signal::new(8),
            Self::StackCheck => Signal::new(11),
            Self::Underflow => Signal::new(8),
            Self::InvalidInstruction => Signal::new(4),
            Self::Privilege => Signal::new(11),
            Self::StackOverflow => Signal::new(11),
            Self::None | Self::Unknown | Self::Timer => Signal::new(11),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_645_sigstkflt_to_stack_overflow() {
        assert_eq!(
            Exception::from_xbasic_linux_signal(Signal::new(16)),
            Exception::StackOverflow
        );
    }

    #[test]
    fn maps_fpe_back_to_invalid_operation_for_runtime_traps() {
        assert_eq!(
            Exception::from_xbasic_linux_signal(Signal::new(8)),
            Exception::InvalidOperation
        );
    }
}
