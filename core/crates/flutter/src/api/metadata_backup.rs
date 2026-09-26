use hentai_core::{
    export_comic_metadata as core_export, import_comic_metadata as core_import,
    peek_metadata_backup_manifest as core_peek, preview_import_comic_metadata as core_preview,
    AmbiguousSample, ExportComicMetadataOptions, ImportComicMetadataResult, ImportPlan, MatchTier,
    MetadataBackupManifest, NotFoundSample, WouldApplySample,
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

#[derive(Debug, Clone)]
pub enum MatchTierDto {
    Path,
    LibraryRelative,
}

impl From<MatchTier> for MatchTierDto {
    fn from(value: MatchTier) -> Self {
        match value {
            MatchTier::Path => Self::Path,
            MatchTier::LibraryRelative => Self::LibraryRelative,
        }
    }
}

#[derive(Debug, Clone)]
pub struct WouldApplySampleDto {
    pub comic_id: String,
    pub path: String,
    pub title: String,
    pub matched_comic_id: String,
    pub match_tier: Option<MatchTierDto>,
}

impl From<WouldApplySample> for WouldApplySampleDto {
    fn from(value: WouldApplySample) -> Self {
        Self {
            comic_id: value.comic_id,
            path: value.path,
            title: value.title,
            matched_comic_id: value.matched_comic_id,
            match_tier: value.match_tier.map(MatchTierDto::from),
        }
    }
}

#[derive(Debug, Clone)]
pub struct NotFoundSampleDto {
    pub comic_id: String,
    pub path: String,
    pub title: String,
}

impl From<NotFoundSample> for NotFoundSampleDto {
    fn from(value: NotFoundSample) -> Self {
        Self {
            comic_id: value.comic_id,
            path: value.path,
            title: value.title,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AmbiguousSampleDto {
    pub comic_id: String,
    pub path: String,
    pub title: String,
    pub candidate_comic_ids: Vec<String>,
}

impl From<AmbiguousSample> for AmbiguousSampleDto {
    fn from(value: AmbiguousSample) -> Self {
        Self {
            comic_id: value.comic_id,
            path: value.path,
            title: value.title,
            candidate_comic_ids: value.candidate_comic_ids,
        }
    }
}

#[derive(Debug, Clone)]
pub struct PreviewImportComicMetadataResultDto {
    pub would_apply: i32,
    pub skipped_not_found: i32,
    pub skipped_ambiguous: i32,
    pub would_upsert_orphan_facet_count: i32,
    pub samples_would_apply: Vec<WouldApplySampleDto>,
    pub samples_not_found: Vec<NotFoundSampleDto>,
    pub samples_ambiguous: Vec<AmbiguousSampleDto>,
}

impl From<ImportPlan> for PreviewImportComicMetadataResultDto {
    fn from(value: ImportPlan) -> Self {
        Self {
            would_apply: value.would_apply as i32,
            skipped_not_found: value.skipped_not_found as i32,
            skipped_ambiguous: value.skipped_ambiguous as i32,
            would_upsert_orphan_facet_count: value.would_upsert_orphan_facet_count as i32,
            samples_would_apply: value
                .samples_would_apply
                .into_iter()
                .map(WouldApplySampleDto::from)
                .collect(),
            samples_not_found: value
                .samples_not_found
                .into_iter()
                .map(NotFoundSampleDto::from)
                .collect(),
            samples_ambiguous: value
                .samples_ambiguous
                .into_iter()
                .map(AmbiguousSampleDto::from)
                .collect(),
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
pub fn preview_import_comic_metadata_frb(
    bytes: Vec<u8>,
) -> Result<PreviewImportComicMetadataResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_preview(&bytes))
        .map(PreviewImportComicMetadataResultDto::from)
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
