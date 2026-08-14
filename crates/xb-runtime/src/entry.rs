use core::ffi::{c_char, c_int, c_void};

pub type EntryCallback = extern "C" fn() -> c_int;
pub type StartApplicationCallback = extern "C" fn() -> c_int;

#[derive(Clone, Copy)]
pub struct XxxMainArgs {
    pub argc: c_int,
    pub argv: *const *const c_char,
    pub envp: *const c_char,
    pub envx: *const c_char,
    pub main_fn: Option<EntryCallback>,
    pub start_app: Option<StartApplicationCallback>,
}

pub fn xb_xxx_main(args: XxxMainArgs) -> c_int {
    if let Some(start_app) = args.start_app {
        let status = start_app();
        if status != 0 {
            return status;
        }
    }
    match args.main_fn {
        Some(main_fn) => main_fn(),
        None => 0,
    }
}

/// C ABI mirror of the `crtl/xstart.c` call into `XxxMain`.
///
/// The argument list is intentionally wide because it is an external ABI copied
/// from the 6.4.5 C runtime experiment, not an internal Rust API.
#[export_name = "XxxMain"]
pub extern "C" fn xxx_main_abi(
    argc: c_int,
    argv: *const *const c_char,
    envp: *const c_char,
    envx: *const c_char,
    main_fn: Option<EntryCallback>,
    start_app: Option<StartApplicationCallback>,
) -> c_int {
    xb_xxx_main(XxxMainArgs {
        argc,
        argv,
        envp,
        envx,
        main_fn,
        start_app,
    })
}

#[allow(dead_code)]
fn _keep_c_void_available(_: *const c_void) {}

#[cfg(test)]
mod tests {
    use super::*;

    extern "C" fn ok_main() -> c_int {
        7
    }

    #[test]
    fn runs_main_callback_when_present() {
        let args = XxxMainArgs {
            argc: 0,
            argv: core::ptr::null(),
            envp: core::ptr::null(),
            envx: core::ptr::null(),
            main_fn: Some(ok_main),
            start_app: None,
        };
        assert_eq!(xb_xxx_main(args), 7);
    }
}
