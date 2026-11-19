use std::future::Future;
use std::process;
use std::sync::OnceLock;

use tokio::runtime::Runtime;

static RUNTIME: OnceLock<Runtime> = OnceLock::new();

pub fn runtime() -> &'static Runtime {
    RUNTIME.get_or_init(|| {
        Runtime::new().unwrap_or_else(|error| {
            eprintln!("failed to create tokio runtime: {error}");
            process::exit(1);
        })
    })
}

pub fn block_on<F: Future>(future: F) -> F::Output {
    match tokio::runtime::Handle::try_current() {
        Ok(handle) => tokio::task::block_in_place(|| handle.block_on(future)),
        Err(_) => runtime().block_on(future),
    }
}
