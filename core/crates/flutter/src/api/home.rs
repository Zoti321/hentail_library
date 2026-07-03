use hentai_core::{
    get_home_page_counts as core_get_counts, watch_home_page_counts as core_watch_counts,
    HomePageCountsDto as CoreCounts,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct HomePageCountsDto {
    pub comic_count: i32,
    pub tag_count: i32,
    pub series_count: i32,
    pub reading_record_count: i32,
}

impl From<CoreCounts> for HomePageCountsDto {
    fn from(v: CoreCounts) -> Self {
        Self {
            comic_count: v.comic_count,
            tag_count: v.tag_count,
            series_count: v.series_count,
            reading_record_count: v.reading_record_count,
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_home_page_counts_frb(exclude_r18: bool) -> Result<HomePageCountsDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_get_counts(exclude_r18))
        .map(HomePageCountsDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn watch_home_page_counts_frb(
    exclude_r18: bool,
    sink: crate::frb_generated::StreamSink<HomePageCountsDto>,
) -> Result<(), HentaiErrorDto> {
    core_watch_counts(exclude_r18, |counts| {
        sink.add(HomePageCountsDto::from(counts))
            .map_err(|_| hentai_core::HentaiError::validation("stream closed"))
    })
    .await
    .map_err(HentaiErrorDto::from)
}
