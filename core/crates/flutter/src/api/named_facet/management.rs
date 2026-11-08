use hentai_core::{
    add_author, add_named_facet_name, count_author_attachments, count_named_facet_attachments,
    count_named_facet_attachments_batch, delete_authors_by_names, delete_named_facet_by_names,
    fetch_management_facet_names_page, list_all_author_names, list_all_named_facet_names,
    merge_named_facet_name, reject_author_merge, rename_author, rename_named_facet_name,
    ManagementFacetKind,
};

use super::types::{JunctionNamedFacetFrb, NamedFacetFormEntryFrbDto, NamedFacetPagedNamesDto};
use crate::api::comic::PageRequestDto;
use crate::api::init::HentaiErrorDto;
use crate::named_facet_route::{route, NamedFacetRoute};

fn management_facet_kind(facet: JunctionNamedFacetFrb) -> ManagementFacetKind {
    match facet {
        JunctionNamedFacetFrb::Author => ManagementFacetKind::Author,
        JunctionNamedFacetFrb::Tag => ManagementFacetKind::Tag,
        JunctionNamedFacetFrb::Parody => ManagementFacetKind::Parody,
        JunctionNamedFacetFrb::Character => ManagementFacetKind::Character,
    }
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
    let page = fetch_management_facet_names_page(management_facet_kind(facet), request.into())
        .await
        .map_err(HentaiErrorDto::from)?;
    Ok(NamedFacetPagedNamesDto {
        items: page.items.into_iter().map(NamedFacetFormEntryFrbDto::from).collect(),
        total_count: page.total_count,
        page: page.page,
        page_size: page.page_size,
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
        NamedFacetRoute::Author => hentai_core::runtime::block_on(reject_author_merge()),
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

#[flutter_rust_bridge::frb]
pub async fn count_named_facet_attachments_batch_frb(
    facet: JunctionNamedFacetFrb,
    names: Vec<String>,
) -> Result<Vec<NamedFacetFormEntryFrbDto>, HentaiErrorDto> {
    match route(facet) {
        NamedFacetRoute::Dictionary(facet) => Ok(count_named_facet_attachments_batch(facet, &names)
            .await
            .map_err(HentaiErrorDto::from)?
            .into_iter()
            .map(NamedFacetFormEntryFrbDto::from)
            .collect()),
        NamedFacetRoute::Author => Ok(names
            .into_iter()
            .map(|name| NamedFacetFormEntryFrbDto {
                name,
                attachment_count: 0,
            })
            .collect()),
    }
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

        let guard = hentai_core::library_write::try_acquire_library_write_lock()
            .expect("hold library write lock");
        let err = merge_named_facet_name_frb(
            JunctionNamedFacetFrb::Author,
            "one".to_string(),
            "two".to_string(),
        )
        .expect_err("author merge refused while busy");
        assert!(err.message.contains("库写入操作进行中"), "{}", err.message);
        drop(guard);
    }
}
