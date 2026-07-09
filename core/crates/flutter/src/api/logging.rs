use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb(sync)]
pub fn configure_rust_log_frb(app_data_dir: String) -> Result<(), HentaiErrorDto> {
    crate::tracing_init::configure_log_directory(&app_data_dir).map_err(|message| {
        HentaiErrorDto {
            code: "Validation".to_string(),
            message,
            context: Some("configure_rust_log_frb".to_string()),
        }
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_diagnostic_logging_frb(verbose: bool) {
    crate::tracing_init::set_diagnostic_level(verbose);
}
