use hentai_core::list_all_parodies;

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_parodies_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_parodies()).map_err(HentaiErrorDto::from)
}
