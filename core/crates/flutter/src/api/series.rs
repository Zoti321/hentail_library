use hentai_core::{infer_series as core_infer_series, InferSeriesResultDto as CoreResult};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct InferSeriesResultDto {
    pub groups_applied: i32,
    pub comics_assigned: i32,
    pub new_series_created: i32,
}

impl From<CoreResult> for InferSeriesResultDto {
    fn from(value: CoreResult) -> Self {
        Self {
            groups_applied: value.groups_applied,
            comics_assigned: value.comics_assigned,
            new_series_created: value.new_series_created,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn infer_series_frb() -> Result<InferSeriesResultDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_infer_series())
        .map(InferSeriesResultDto::from)
        .map_err(HentaiErrorDto::from)
}
