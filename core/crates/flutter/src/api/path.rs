use hentai_core::{add_path as core_add, list_all_paths, remove_path as core_remove, watch_paths};

use super::init::HentaiErrorDto;

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_paths_frb() -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_paths()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_path_frb(raw_path: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_add(&raw_path)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn remove_path_frb(raw_path: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_remove(&raw_path)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_paths_frb(sink: crate::frb_generated::StreamSink<Vec<String>>) -> Result<(), HentaiErrorDto> {
    watch_paths(|items| {
        sink.add(items)
            .map_err(|_| hentai_core::HentaiError::validation("stream closed"))
    })
    .await
    .map_err(HentaiErrorDto::from)
}
