use hentai_core::NamedFacetFormEntry;

/// Junction Named metadata facet kind for Comic metadata form listing.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JunctionNamedFacetFrb {
    Tag,
    Author,
    Parody,
    Character,
}

/// Form picker candidate: name + Named facet attachment count.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NamedFacetFormEntryFrbDto {
    pub name: String,
    pub attachment_count: i64,
}

impl From<NamedFacetFormEntry> for NamedFacetFormEntryFrbDto {
    fn from(value: NamedFacetFormEntry) -> Self {
        Self {
            name: value.name,
            attachment_count: value.attachment_count,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NamedFacetPagedNamesDto {
    /// Dictionary facets include real attachment counts; Author rows are 0.
    pub items: Vec<NamedFacetFormEntryFrbDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}
