use std::env;
use std::io::Write;
use std::process::ExitCode;

fn main() -> ExitCode {
    let args = env::args().skip(1).collect::<Vec<_>>();
    match xb_cli::run(&args) {
        Ok(output) => {
            // Emit byte-faithfully: the interpreter renders string output as one `char`
            // per source byte (see `render_faithful`), so high bytes / embedded NULs pass
            // through raw here, matching the compiled backends. `--emit-ir`/`--emit-c` text
            // is plain ASCII, so this is identical for them.
            let bytes: Vec<u8> = output.chars().map(|c| c as u8).collect();
            let _ = std::io::stdout().write_all(&bytes);
            ExitCode::SUCCESS
        }
        Err(err) => {
            eprintln!("{err}");
            ExitCode::FAILURE
        }
    }
}
