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
            added: hentai_core::util::u32_to_i32(value.added),
            skipped_existing: hentai_core::util::u32_to_i32(value.skipped_existing),
            skipped_filtered_or_empty_or_dedupe: hentai_core::util::u32_to_i32(
                value.skipped_filtered_or_empty_or_dedupe,
            ),
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
