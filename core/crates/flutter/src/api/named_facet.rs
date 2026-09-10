use hentai_core::{
    add_named_facet_name, count_all_named_facet_names, count_named_facet_attachments,
    delete_named_facet_by_names, fetch_named_facet_page, list_all_named_facet_names,
    list_named_facet_for_form, rename_named_facet_name, JunctionNamedFacet, NamedFacetFormEntry,
};

use super::comic::PageRequestDto;
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

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NamedFacetPagedNamesDto {
    pub items: Vec<String>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_all_named_facet_names_frb(
    facet: JunctionNamedFacetFrb,
) -> Result<Vec<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_all_named_facet_names(facet.into()))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn fetch_named_facet_page_frb(
    facet: JunctionNamedFacetFrb,
    request: PageRequestDto,
) -> Result<NamedFacetPagedNamesDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(async {
        let total = count_all_named_facet_names(facet.into()).await?;
        let page_size = request.page_size.max(1);
        if total <= 0 {
            return Ok::<NamedFacetPagedNamesDto, hentai_core::HentaiError>(
                NamedFacetPagedNamesDto {
                    items: vec![],
                    total_count: 0,
                    page: 1,
                    page_size,
                },
            );
        }
        let total_pages = (total + page_size as i64 - 1) / page_size as i64;
        let mut page = request.page.max(1);
        if page as i64 > total_pages {
            page = total_pages as i32;
        }
        let offset = (page - 1) * page_size;
        let items = fetch_named_facet_page(facet.into(), page_size, offset).await?;
        Ok(NamedFacetPagedNamesDto {
            items,
            total_count: total,
            page,
            page_size,
        })
    })
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_named_facet_name_frb(
    facet: JunctionNamedFacetFrb,
    name: String,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(add_named_facet_name(facet.into(), &name))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_named_facet_by_names_frb(
    facet: JunctionNamedFacetFrb,
    names: Vec<String>,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(delete_named_facet_by_names(facet.into(), names))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn rename_named_facet_name_frb(
    facet: JunctionNamedFacetFrb,
    old_name: String,
    new_name: String,
) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(rename_named_facet_name(facet.into(), &old_name, &new_name))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn count_named_facet_attachments_frb(
    facet: JunctionNamedFacetFrb,
    name: String,
) -> Result<i64, HentaiErrorDto> {
    hentai_core::runtime::block_on(count_named_facet_attachments(facet.into(), &name))
        .map_err(HentaiErrorDto::from)
}

/// Comic metadata form candidates sorted by attachment count DESC, name ASC.
#[flutter_rust_bridge::frb(sync)]
pub fn list_named_facet_for_form_frb(
    facet: JunctionNamedFacetFrb,
) -> Result<Vec<NamedFacetFormEntryFrbDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(list_named_facet_for_form(facet.into()))
        .map(|rows| {
            rows.into_iter()
                .map(NamedFacetFormEntryFrbDto::from)
                .collect()
        })
        .map_err(HentaiErrorDto::from)
}
