/// Returns the C compiler to use for tests, respecting the `CC` env var.
pub fn cc() -> String {
    std::env::var("CC").unwrap_or_else(|_| "cc".to_string())
}
