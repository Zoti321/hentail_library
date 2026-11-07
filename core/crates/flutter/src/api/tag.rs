use hentai_core::{import_tag_dictionary as core_import_tag_dictionary, TagDictionaryImportResult};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct TagDictionaryImportResultDto {
    pub added: i32,
    pub skipped_existing: i32,
    pub skipped_filtered_or_empty_or_dedupe: i32,
}

impl From<TagDictionaryImportResult> for TagDictionaryImportResultDto {
    fn from(value: TagDictionaryImportResult) -> Self {
        Self {
            added: value.added as i32,
            skipped_existing: value.skipped_existing as i32,
            skipped_filtered_or_empty_or_dedupe: value.skipped_filtered_or_empty_or_dedupe as i32,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_tag_dictionary_frb(
    json_bytes: Vec<u8>,
) -> Result<TagDictionaryImportResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_import_tag_dictionary(&json_bytes))
        .map(TagDictionaryImportResultDto::from)
        .map_err(HentaiErrorDto::from)
}
