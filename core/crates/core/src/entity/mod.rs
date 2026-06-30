pub mod comic_authors;
pub mod comic_tags;
pub mod comics;

pub mod prelude {
    pub use super::comic_authors::Entity as ComicAuthors;
    pub use super::comic_tags::Entity as ComicTags;
    pub use super::comics::Entity as Comics;
}
