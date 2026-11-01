use hentai_core::{
    add_author, add_named_facet_name, author_merge_unsupported_error, count_all_authors,
    count_all_named_facet_names, count_author_attachments, count_named_facet_attachments,
    delete_authors_by_names, delete_named_facet_by_names, fetch_author_name_page,
    fetch_named_facet_page, list_all_author_names, list_all_named_facet_names,
    list_author_names_for_form, list_named_facet_for_form, merge_named_facet_name, paginate,
    rename_author, rename_named_facet_name, NamedFacetFormEntry,
};

use super::comic::PageRequestDto;
use super::init::HentaiErrorDto;
use crate::named_facet_route::{route, NamedFacetRoute};

// Author is routed to the Author entry points in `named_facet_route`; the core
// named-facet module only sees dictionary facets (Tag / Parody / Character).
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
    pub items: Vec<String>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[flutter_rust_bridge::frb]
pub async fn list_all_named_facet_names_frb(
    facet: JunctionNamedFacetFrb,
) -> Result<Vec<String>, HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => list_all_named_facet_names(facet).await,
        NamedFacetRoute::Author => list_all_author_names().await,
    }
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn fetch_named_facet_page_frb(
    facet: JunctionNamedFacetFrb,
    request: PageRequestDto,
) -> Result<NamedFacetPagedNamesDto, HentaiErrorDto> {
    let target = route(facet);
    let total = match target {
        NamedFacetRoute::Dictionary(facet) => count_all_named_facet_names(facet).await,
        NamedFacetRoute::Author => count_all_authors().await,
    }
    .map_err(HentaiErrorDto::from)?;
    let window = paginate(request.into(), total).clamped();
    if total <= 0 {
        return Ok(NamedFacetPagedNamesDto {
            items: vec![],
            total_count: 0,
            page: 1,
            page_size: window.page_size,
        });
    }
    let offset = window.offset as i32;
    let items = match target {
        NamedFacetRoute::Dictionary(facet) => {
            fetch_named_facet_page(facet, window.page_size, offset).await
        }
        NamedFacetRoute::Author => fetch_author_name_page(window.page_size, offset).await,
    }
    .map_err(HentaiErrorDto::from)?;
    Ok(NamedFacetPagedNamesDto {
        items,
        total_count: total,
        page: window.page,
        page_size: window.page_size,
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_named_facet_name_frb(
    facet: JunctionNamedFacetFrb,
    name: String,
) -> Result<(), HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => {
            hentai_core::runtime::block_on(add_named_facet_name(facet, &name))
        }
        NamedFacetRoute::Author => hentai_core::runtime::block_on(add_author(&name)).map(|_| ()),
    }
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_named_facet_by_names_frb(
    facet: JunctionNamedFacetFrb,
    names: Vec<String>,
) -> Result<(), HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => {
            hentai_core::runtime::block_on(delete_named_facet_by_names(facet, names))
        }
        NamedFacetRoute::Author => hentai_core::runtime::block_on(delete_authors_by_names(names)),
    }
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn rename_named_facet_name_frb(
    facet: JunctionNamedFacetFrb,
    old_name: String,
    new_name: String,
) -> Result<(), HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => {
            hentai_core::runtime::block_on(rename_named_facet_name(facet, &old_name, &new_name))
        }
        NamedFacetRoute::Author => {
            hentai_core::runtime::block_on(rename_author(&old_name, &new_name))
        }
    }
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn merge_named_facet_name_frb(
    facet: JunctionNamedFacetFrb,
    source_name: String,
    target_name: String,
) -> Result<(), HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => hentai_core::runtime::block_on(
            merge_named_facet_name(facet, &source_name, &target_name),
        ),
        // Author has no merge entry point; the refusal text lives in the Author module.
        NamedFacetRoute::Author => Err(author_merge_unsupported_error()),
    }
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb]
pub async fn count_named_facet_attachments_frb(
    facet: JunctionNamedFacetFrb,
    name: String,
) -> Result<i64, HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => count_named_facet_attachments(facet, &name).await,
        NamedFacetRoute::Author => count_author_attachments(&name).await,
    }
    .map_err(HentaiErrorDto::from)
}

/// Comic metadata form candidates sorted by attachment count DESC, name ASC.
#[flutter_rust_bridge::frb]
pub async fn list_named_facet_for_form_frb(
    facet: JunctionNamedFacetFrb,
) -> Result<Vec<NamedFacetFormEntryFrbDto>, HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => list_named_facet_for_form(facet).await,
        NamedFacetRoute::Author => list_author_names_for_form().await,
    }
    .map(|rows| {
        rows.into_iter()
            .map(NamedFacetFormEntryFrbDto::from)
            .collect()
    })
    .map_err(HentaiErrorDto::from)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn author_merge_is_refused_with_stable_message() {
        let err = merge_named_facet_name_frb(
            JunctionNamedFacetFrb::Author,
            "one".to_string(),
            "two".to_string(),
        )
        .expect_err("author merge refused");
        assert!(err.message.contains("作者暂不支持合并"), "{}", err.message);
    }
}
