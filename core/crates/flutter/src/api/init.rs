use hentai_core::{comic_id_from_path, init_db, HentaiError};

#[derive(Debug, Clone)]
pub struct HentaiErrorDto {
    pub code: String,
    pub message: String,
    pub context: Option<String>,
}

impl From<HentaiError> for HentaiErrorDto {
    fn from(value: HentaiError) -> Self {
        let code = format!("{:?}", value.code);
        Self {
            code,
            message: value.message,
            context: value.context,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_db_frb(app_data_dir: String, db_file_name: String) -> Result<(), HentaiErrorDto> {
    init_db(&app_data_dir, &db_file_name).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn comic_id_from_path_frb(raw_path: String) -> String {
    comic_id_from_path(&raw_path)
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}
