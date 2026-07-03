pub mod authors;
pub mod comic_authors;
pub mod comic_tags;
pub mod comic_thumbnails;
pub mod comics;
pub mod saved_paths;
pub mod tags;

pub mod prelude {
    pub use super::authors::Entity as Authors;
    pub use super::comic_authors::Entity as ComicAuthors;
    pub use super::comic_tags::Entity as ComicTags;
    pub use super::comic_thumbnails::Entity as ComicThumbnails;
    pub use super::comics::Entity as Comics;
    pub use super::saved_paths::Entity as SavedPaths;
    pub use super::tags::Entity as Tags;
}
