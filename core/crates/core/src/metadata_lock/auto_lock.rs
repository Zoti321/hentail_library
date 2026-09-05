/// Which Comic Metadata field locks become `true` for a user-meta write (ADR-0007).
///
/// Callers pass whether each field is present in the patch (`true` = written → lock).
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct ComicAutoLocks {
    pub title: bool,
    pub description: bool,
    pub published_at: bool,
    pub content_rating: bool,
    pub authors: bool,
    pub tags: bool,
    pub languages: bool,
    pub parodies: bool,
    pub characters: bool,
}

impl ComicAutoLocks {
    pub fn any(self) -> bool {
        self.title
            || self.description
            || self.published_at
            || self.content_rating
            || self.authors
            || self.tags
            || self.languages
            || self.parodies
            || self.characters
    }

    /// Fields present in the patch auto-lock; absent fields leave locks unchanged.
    pub fn from_written_fields(
        title: bool,
        description: bool,
        published_at: bool,
        content_rating: bool,
        authors: bool,
        tags: bool,
        languages: bool,
        parodies: bool,
        characters: bool,
    ) -> Self {
        Self {
            title,
            description,
            published_at,
            content_rating,
            authors,
            tags,
            languages,
            parodies,
            characters,
        }
    }
}

/// Which Series Metadata field locks become `true` for a user-meta write (ADR-0007).
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct SeriesAutoLocks {
    pub name: bool,
    pub serialization_status: bool,
    pub total_count: bool,
}

impl SeriesAutoLocks {
    pub fn any(self) -> bool {
        self.name || self.serialization_status || self.total_count
    }

    pub fn from_written_fields(
        name: bool,
        serialization_status: bool,
        total_count: bool,
    ) -> Self {
        Self {
            name,
            serialization_status,
            total_count,
        }
    }
}

/// Convenience: build Comic auto-locks from patch presence flags.
pub fn comic_auto_locks(
    title: bool,
    description: bool,
    published_at: bool,
    content_rating: bool,
    authors: bool,
    tags: bool,
    languages: bool,
    parodies: bool,
    characters: bool,
) -> ComicAutoLocks {
    ComicAutoLocks::from_written_fields(
        title,
        description,
        published_at,
        content_rating,
        authors,
        tags,
        languages,
        parodies,
        characters,
    )
}

pub fn series_auto_locks(
    name: bool,
    serialization_status: bool,
    total_count: bool,
) -> SeriesAutoLocks {
    SeriesAutoLocks::from_written_fields(name, serialization_status, total_count)
}
