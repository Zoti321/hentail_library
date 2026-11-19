#![cfg_attr(
    test,
    allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)
)]

mod api;
// FRB codegen output — keep pedantic/restriction quiet without editing the generated file.
#[allow(
    clippy::pedantic,
    clippy::restriction,
    clippy::style,
    clippy::complexity,
    clippy::correctness,
    clippy::perf,
    clippy::suspicious,
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::panic,
    clippy::unimplemented,
    clippy::todo,
    clippy::dbg_macro,
    clippy::redundant_clone,
    dead_code,
    unused_imports,
    unused_qualifications
)]
mod frb_generated;
mod log_file;
mod named_facet_route;
mod tracing_init;

pub use api::*;
