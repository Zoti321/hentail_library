use hentai_core::{list_named_facet_for_form, JunctionNamedFacet, NamedFacetFormEntry};

use super::init::HentaiErrorDto;

/// Junction Named metadata facet kind for Comic metadata form listing.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum JunctionNamedFacetFrb {
    Tag,
    Author,
    Parody,
    Character,
}

impl From<JunctionNamedFacetFrb> for JunctionNamedFacet {
    fn from(value: JunctionNamedFacetFrb) -> Self {
        match value {
            JunctionNamedFacetFrb::Tag => Self::Tag,
            JunctionNamedFacetFrb::Author => Self::Author,
            JunctionNamedFacetFrb::Parody => Self::Parody,
            JunctionNamedFacetFrb::Character => Self::Character,
        }
    }
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

/// Comic metadata form candidates sorted by attachment count DESC, name ASC.
#[flutter_rust_bridge::frb(sync)]
pub fn list_named_facet_for_form_frb(
    facet: JunctionNamedFacetFrb,
) -> Result<Vec<NamedFacetFormEntryFrbDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_named_facet_for_form(facet.into()))
        .map(|rows| rows.into_iter().map(NamedFacetFormEntryFrbDto::from).collect())
        .map_err(HentaiErrorDto::from)
}
