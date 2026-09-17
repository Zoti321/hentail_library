use hentai_core::{list_all_characters, list_distinct_characters};

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb]
pub async fn list_all_characters_frb() -> Result<Vec<String>, HentaiErrorDto> {
    list_all_characters().await.map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn list_distinct_characters_frb(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiErrorDto> {
    list_distinct_characters(library_id)
        .await
        .map_err(HentaiErrorDto::from)
}
