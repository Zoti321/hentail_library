use hentai_core::{clear_reader_sessions, shutdown_db};

#[flutter_rust_bridge::frb(sync)]
pub fn shutdown_app_data_frb() {
    clear_reader_sessions();
    shutdown_db();
    crate::log_file::close_log_file();
}
