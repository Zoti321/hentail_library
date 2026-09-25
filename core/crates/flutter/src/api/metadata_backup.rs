use hentai_core::{
    export_comic_metadata as core_export, import_comic_metadata as core_import,
    peek_metadata_backup_manifest as core_peek, ExportComicMetadataOptions,
    ImportComicMetadataResult, MetadataBackupManifest,
};

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

#[derive(Debug, Clone)]
pub struct MetadataBackupManifestDto {
    pub schema_version: i32,
    pub exported_at: String,
    pub app_version: String,
    pub comic_count: i32,
    pub include_orphan_facets: bool,
    pub library_id: Option<String>,
}

impl From<MetadataBackupManifest> for MetadataBackupManifestDto {
    fn from(value: MetadataBackupManifest) -> Self {
        Self {
            schema_version: value.schema_version as i32,
            exported_at: value.exported_at,
            app_version: value.app_version,
            comic_count: value.comic_count as i32,
            include_orphan_facets: value.include_orphan_facets,
            library_id: value.library_id,
        }
    }
}

#[derive(Debug, Clone)]
pub struct ImportComicMetadataResultDto {
    pub applied: i32,
    pub skipped_not_found: i32,
    pub skipped_ambiguous: i32,
    pub errors: Vec<String>,
}

impl From<ImportComicMetadataResult> for ImportComicMetadataResultDto {
    fn from(value: ImportComicMetadataResult) -> Self {
        Self {
            applied: value.applied as i32,
            skipped_not_found: value.skipped_not_found as i32,
            skipped_ambiguous: value.skipped_ambiguous as i32,
            errors: value.errors,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn export_comic_metadata_frb(
    options: ExportComicMetadataOptionsDto,
) -> Result<Vec<u8>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_export(options.into())).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn peek_metadata_backup_manifest_frb(
    bytes: Vec<u8>,
) -> Result<MetadataBackupManifestDto, HentaiErrorDto> {
    core_peek(&bytes)
        .map(MetadataBackupManifestDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_comic_metadata_frb(
    bytes: Vec<u8>,
) -> Result<ImportComicMetadataResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_import(&bytes))
        .map(ImportComicMetadataResultDto::from)
        .map_err(HentaiErrorDto::from)
}
