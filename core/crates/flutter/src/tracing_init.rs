use std::sync::Once;

static TRACING_INIT: Once = Once::new();

pub fn init_tracing_subscriber() {
    TRACING_INIT.call_once(|| {
        let default_filter = if cfg!(debug_assertions) {
            "hentai_core=debug,hentai_flutter=debug"
        } else {
            "hentai_core=info,hentai_flutter=info"
        };
        let env_filter = tracing_subscriber::EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new(default_filter));

        tracing_subscriber::fmt()
            .with_env_filter(env_filter)
            .with_target(true)
            .with_writer(std::io::stderr)
            .init();

        tracing::info!("Rust tracing subscriber initialized");
    });
}
