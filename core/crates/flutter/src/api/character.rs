use hentai_core::list_all_characters;

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_characters_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_characters()).map_err(HentaiErrorDto::from)
}
