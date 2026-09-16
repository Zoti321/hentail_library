use hentai_core::{list_all_parodies, list_distinct_parodies};

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb]
pub async fn list_all_parodies_frb() -> Result<Vec<String>, HentaiErrorDto> {
    list_all_parodies().await.map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn list_distinct_parodies_frb(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiErrorDto> {
    list_distinct_parodies(library_id)
        .await
        .map_err(HentaiErrorDto::from)
}
