pub mod entry;
pub mod exception;
pub mod fault;
pub mod math;

pub use entry::{xb_xxx_main, EntryCallback, StartApplicationCallback, XxxMainArgs};
pub use exception::{Exception, Signal};
pub use fault::{FaultHooks, HookStatus};
