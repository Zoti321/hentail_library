pub mod app_prefs;
pub mod authors;
pub mod comic_authors;
pub mod comic_meta;
pub mod comic_parodies;
pub mod comic_reading_histories;
pub mod comic_tags;
pub mod comic_thumbnails;
pub mod comics;
pub mod libraries;
pub mod parodies;
pub mod saved_paths;
pub mod series;
pub mod series_items;
pub mod series_thumbnails;
pub mod tags;

pub mod prelude {
    pub use super::app_prefs::Entity as AppPrefs;
    pub use super::authors::Entity as Authors;
    pub use super::comic_authors::Entity as ComicAuthors;
    pub use super::comic_meta::Entity as ComicMeta;
    pub use super::comic_parodies::Entity as ComicParodies;
    pub use super::comic_reading_histories::Entity as ComicReadingHistories;
    pub use super::comic_tags::Entity as ComicTags;
    pub use super::comic_thumbnails::Entity as ComicThumbnails;
    pub use super::comics::Entity as Comics;
    pub use super::libraries::Entity as Libraries;
    pub use super::parodies::Entity as Parodies;
    pub use super::saved_paths::Entity as SavedPaths;
    pub use super::series::Entity as Series;
    pub use super::series_items::Entity as SeriesItems;
    pub use super::series_thumbnails::Entity as SeriesThumbnails;
    pub use super::tags::Entity as Tags;
}
