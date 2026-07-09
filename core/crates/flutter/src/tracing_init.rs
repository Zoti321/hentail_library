use std::sync::{Once, OnceLock};

use tracing_subscriber::{fmt, prelude::*, reload, EnvFilter};

use crate::log_file::SharedLogFileWriter;

static TRACING_INIT: Once = Once::new();
static FILTER_HANDLE: OnceLock<reload::Handle<EnvFilter, tracing_subscriber::Registry>> =
    OnceLock::new();

fn default_filter_string(verbose: bool) -> &'static str {
    if verbose {
        return "hentai_core=debug,hentai_flutter=debug";
    }
    if cfg!(debug_assertions) {
        "hentai_core=debug,hentai_flutter=debug"
    } else {
        "hentai_core=info,hentai_flutter=info"
    }
}

fn build_env_filter(verbose: bool) -> EnvFilter {
    EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(default_filter_string(verbose)))
}

pub fn init_tracing_subscriber() {
    TRACING_INIT.call_once(|| {
        let env_filter = build_env_filter(false);
        let (filter_layer, reload_handle) = reload::Layer::new(env_filter);
        let _ = FILTER_HANDLE.set(reload_handle);

        let stderr_layer = fmt::layer()
            .with_writer(std::io::stderr)
            .with_target(true);

        let file_layer = fmt::layer()
            .with_writer(SharedLogFileWriter::from_slot)
            .with_ansi(false)
            .with_target(true);

        tracing_subscriber::registry()
            .with(filter_layer)
            .with(stderr_layer)
            .with(file_layer)
            .init();

        tracing::info!("Rust tracing subscriber initialized");
    });
}

pub fn configure_log_directory(app_data_dir: &str) -> Result<(), String> {
    let log_path = crate::log_file::open_log_file(app_data_dir).map_err(|err| err.to_string())?;
    tracing::info!(path = %log_path.display(), "Rust log file configured");
    Ok(())
}

pub fn set_diagnostic_level(verbose: bool) {
    let Some(handle) = FILTER_HANDLE.get() else {
        return;
    };
    let filter = EnvFilter::new(default_filter_string(verbose));
    let _ = handle.modify(|current| *current = filter);
    tracing::info!(verbose, "Rust diagnostic log level updated");
}
