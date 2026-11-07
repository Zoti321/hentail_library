//! Metadata-expression catalog search uses SQL COUNT/LIMIT/OFFSET (not in-memory slice).

mod common;

use hentai_core::{
    create_sync_handle, fetch_comics_page, search_by_tag_expression_page, sync_library,
    update_comic_user_meta, ComicFilterDto, ComicGrouping, ComicSortOptionDto, PageRequestDto,
    SyncScanMode, UpdateComicUserMetaDto,
};

#[test]
fn metadata_expression_page_uses_sql_window() {
    common::with_local_library(
        "metadata_expression_page.sqlite",
        &[("alpha.cbz", 1), ("beta.cbz", 1), ("gamma.cbz", 1)],
        |library, runtime| {
            runtime.block_on(async {
                sync_library(
                    create_sync_handle(),
                    SyncScanMode::Full,
                    false,
                    Some(library.library_id.as_str()),
                    vec![],
                    |_| {},
                )
                .await
                .expect("sync");

                let comics = fetch_comics_page(
                    PageRequestDto {
                        page: 1,
                        page_size: 10,
                    },
                    ComicFilterDto {
                        library_id: Some(library.library_id.clone()),
                        ..Default::default()
                    },
                    ComicGrouping::None,
                    ComicSortOptionDto::default(),
                )
                .await
                .expect("catalog")
                .items;
                assert_eq!(comics.len(), 3, "fixture comics");

                for (comic, tag) in comics.iter().zip(["shared", "shared", "shared"]) {
                    update_comic_user_meta(
                        &comic.comic_id,
                        UpdateComicUserMetaDto {
                            tags: Some(vec![tag.to_string()]),
                            ..Default::default()
                        },
                    )
                    .await
                    .expect("tag comic");
                }

                let library_id = Some(library.library_id.clone());
                let page1 = search_by_tag_expression_page(
                    vec!["shared".to_string()],
                    vec![],
                    vec![],
                    PageRequestDto {
                        page: 1,
                        page_size: 1,
                    },
                    library_id.clone(),
                )
                .await
                .expect("page 1");
                assert_eq!(page1.total_count, 3);
                assert_eq!(page1.items.len(), 1);
                assert_eq!(page1.page, 1);
                assert_eq!(page1.page_size, 1);

                let page3 = search_by_tag_expression_page(
                    vec!["shared".to_string()],
                    vec![],
                    vec![],
                    PageRequestDto {
                        page: 3,
                        page_size: 1,
                    },
                    library_id.clone(),
                )
                .await
                .expect("page 3");
                assert_eq!(page3.total_count, 3);
                assert_eq!(page3.items.len(), 1);
                assert_eq!(page3.page, 3);

                let page1_ids: Vec<String> =
                    page1.items.iter().map(|c| c.comic_id.clone()).collect();
                let page3_ids: Vec<String> =
                    page3.items.iter().map(|c| c.comic_id.clone()).collect();
                assert_ne!(page1_ids, page3_ids);

                let empty = search_by_tag_expression_page(
                    vec![],
                    vec![],
                    vec![],
                    PageRequestDto {
                        page: 1,
                        page_size: 10,
                    },
                    library_id,
                )
                .await
                .expect("empty expression");
                assert_eq!(empty.total_count, 0);
                assert!(empty.items.is_empty());
            });
        },
    );
}
