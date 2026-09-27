use hentai_core::{
    probe_library as core_probe_library, LibraryProbeResultDto as CoreLibraryProbeResultDto,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct LibraryProbeResultDto {
    pub library_id: String,
    pub added_count: i32,
    pub changed_count: i32,
    pub removed_count: i32,
    pub unreachable: bool,
    pub error_message: Option<String>,
    pub probed_at_ms: i64,
    pub baseline_missing: bool,
}

impl From<CoreLibraryProbeResultDto> for LibraryProbeResultDto {
    fn from(v: CoreLibraryProbeResultDto) -> Self {
        Self {
            library_id: v.library_id,
            added_count: v.added_count,
            changed_count: v.changed_count,
            removed_count: v.removed_count,
            unreachable: v.unreachable,
            error_message: v.error_message,
            probed_at_ms: v.probed_at_ms,
            baseline_missing: v.baseline_missing,
        }
    }
}

#[flutter_rust_bridge::frb]
pub async fn probe_library_frb(
    library_id: String,
    password: Option<String>,
) -> Result<LibraryProbeResultDto, HentaiErrorDto> {
    core_probe_library(&library_id, password.as_deref())
        .await
        .map(LibraryProbeResultDto::from)
        .map_err(Into::into)
}
