use hentai_core::{list_all_parodies, list_distinct_parodies};

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_parodies_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_parodies()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_distinct_parodies_frb(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_distinct_parodies(library_id))
        .map_err(HentaiErrorDto::from)
}
