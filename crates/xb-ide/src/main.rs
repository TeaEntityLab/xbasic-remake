#[cfg(feature = "eframe-app")]
pub mod app {
    use eframe::egui;
    use xb_frontend::lex;

    pub struct XbIdeApp {
        source: String,
        status: String,
    }

    impl Default for XbIdeApp {
        fn default() -> Self {
            Self {
                source: "VERSION \"6.5.0-alpha.0\"\nPRINT \"hello from xbasic\"\n".to_owned(),
                status: "stage-0 Rust host, Win64 focus".to_owned(),
            }
        }
    }

    impl eframe::App for XbIdeApp {
        fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
            ui.horizontal(|ui| {
                ui.label("XBASIC 6.5.0");
                ui.separator();
                ui.label(&self.status);
            });
            ui.separator();
            ui.heading("Source");
            ui.add(
                egui::TextEdit::multiline(&mut self.source)
                    .code_editor()
                    .desired_rows(24),
            );
            if ui.button("Tokenize").clicked() {
                self.status = match lex(&self.source) {
                    Ok(tokens) => format!("{} tokens", tokens.len()),
                    Err(err) => err.to_string(),
                };
            }
        }
    }

    pub fn run() -> eframe::Result<()> {
        let native_options = eframe::NativeOptions::default();
        eframe::run_native(
            "XBASIC 6.5.0",
            native_options,
            Box::new(|_cc| Ok(Box::<XbIdeApp>::default())),
        )
    }
}

#[cfg(feature = "eframe-app")]
fn main() -> eframe::Result<()> {
    app::run()
}

#[cfg(not(feature = "eframe-app"))]
fn main() {
    println!("xb-ide scaffold built without the eframe-app feature");
}
