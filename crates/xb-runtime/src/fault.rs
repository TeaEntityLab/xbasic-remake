use crate::{Exception, Signal};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HookStatus {
    Installed,
    Deferred,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct FaultHooks;

impl FaultHooks {
    pub const fn new() -> Self {
        Self
    }

    pub fn install(self) -> HookStatus {
        platform::install_fault_hooks()
    }

    pub fn classify_signal(self, signal: Signal) -> Exception {
        Exception::from_xbasic_linux_signal(signal)
    }
}

#[cfg(unix)]
mod platform {
    use super::HookStatus;

    pub fn install_fault_hooks() -> HookStatus {
        HookStatus::Deferred
    }
}

#[cfg(windows)]
mod platform {
    use super::HookStatus;

    pub fn install_fault_hooks() -> HookStatus {
        HookStatus::Deferred
    }
}

#[cfg(not(any(unix, windows)))]
mod platform {
    use super::HookStatus;

    pub fn install_fault_hooks() -> HookStatus {
        HookStatus::Deferred
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn classifies_signal_without_installing_platform_hook() {
        let hooks = FaultHooks::new();
        assert_eq!(
            hooks.classify_signal(Signal::new(16)),
            Exception::StackOverflow
        );
    }
}
