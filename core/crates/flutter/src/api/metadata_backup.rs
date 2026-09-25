use hentai_core::{export_comic_metadata as core_export, ExportComicMetadataOptions};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ExportComicMetadataOptionsDto {
    pub library_id: Option<String>,
    pub include_orphan_facets: bool,
}

impl From<ExportComicMetadataOptionsDto> for ExportComicMetadataOptions {
    fn from(value: ExportComicMetadataOptionsDto) -> Self {
        Self {
            library_id: value.library_id,
            include_orphan_facets: value.include_orphan_facets,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn export_comic_metadata_frb(
    options: ExportComicMetadataOptionsDto,
) -> Result<Vec<u8>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_export(options.into())).map_err(HentaiErrorDto::from)
}
