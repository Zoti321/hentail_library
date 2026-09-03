use hentai_core::{list_all_characters, list_distinct_characters};

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_characters_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_characters()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_distinct_characters_frb(
    library_id: Option<String>,
) -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_distinct_characters(library_id))
        .map_err(HentaiErrorDto::from)
}
