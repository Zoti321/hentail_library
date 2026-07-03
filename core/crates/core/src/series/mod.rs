mod clustering;
mod infer;
mod orchestrator;
mod repository;
mod title_mapping;
mod volume_key;

pub use clustering::SeriesTitleClustering;
pub use infer::{
    AutoSeriesInferService, ComicTitleInput, InferredSeriesFromTitlesResult, InferredSeriesGroup,
    InferredVolumeEntry,
};
pub use orchestrator::{infer_series, InferSeriesResultDto};
pub use repository::{
    assign_comic_exclusive, count_all_series, create_series, delete_series, fetch_series_page,
    find_series_by_name, get_all_series, load_home_series_comic_order_map,
    remove_comic_from_series, remove_comics_from_series, remove_orphan_series_items_public,
    rename_series, search_series_by_keyword, search_series_by_tag_expression,
    set_series_items_order, watch_all_series, watch_home_series_comic_order_map, SeriesDto,
    SeriesItemDto,
};
pub use title_mapping::{ComicTitleToSeriesItemMapping, MappedSeriesVolume};
pub use volume_key::VolumeSortKey;