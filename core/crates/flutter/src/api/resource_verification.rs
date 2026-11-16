use super::init::HentaiErrorDto;
use hentai_core::resource_verification as core;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResourceVerificationModeDto {
    Quick,
    Strict,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResourceVerificationStatusDto {
    NotDetected,
    ObservationChanged,
    ContentMatches,
    ContentChanged,
    Missing,
    BaselineUnavailable,
    Indeterminate,
}

#[derive(Debug, Clone)]
pub struct ResourceVerificationResultDto {
    pub status: ResourceVerificationStatusDto,
    pub observed_modified_ms: Option<i64>,
    pub observed_size: Option<i64>,
}

pub async fn verify_comic_resource_frb(
    comic_id: String,
    mode: ResourceVerificationModeDto,
) -> Result<ResourceVerificationResultDto, HentaiErrorDto> {
    let mode = match mode {
        ResourceVerificationModeDto::Quick => core::ResourceVerificationMode::Quick,
        ResourceVerificationModeDto::Strict => core::ResourceVerificationMode::Strict,
    };
    let result = core::verify_comic_resource(&comic_id, mode).await?;
    let status = match result.status {
        core::ResourceVerificationStatus::NotDetected => ResourceVerificationStatusDto::NotDetected,
        core::ResourceVerificationStatus::ObservationChanged => {
            ResourceVerificationStatusDto::ObservationChanged
        }
        core::ResourceVerificationStatus::ContentMatches => {
            ResourceVerificationStatusDto::ContentMatches
        }
        core::ResourceVerificationStatus::ContentChanged => {
            ResourceVerificationStatusDto::ContentChanged
        }
        core::ResourceVerificationStatus::Missing => ResourceVerificationStatusDto::Missing,
        core::ResourceVerificationStatus::BaselineUnavailable => {
            ResourceVerificationStatusDto::BaselineUnavailable
        }
        core::ResourceVerificationStatus::Indeterminate => {
            ResourceVerificationStatusDto::Indeterminate
        }
    };
    Ok(ResourceVerificationResultDto {
        status,
        observed_modified_ms: result.observed_modified_ms,
        observed_size: result.observed_size,
    })
}
