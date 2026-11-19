#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set catalog query: filter / sort / group / page (#603).

mod common;

use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

use hentai_core::{
    connection, create_image_set_local_library, create_sync_handle, fetch_image_sets_page,
    init_db_at_path, list_image_sets, sync_library, update_image_set_facets,
    update_image_set_user_meta, ImageSetCarrierShapeDto, ImageSetCatalogItemDto,
    ImageSetFacetFilterDto, ImageSetFilterDto, ImageSetGroupingDto, ImageSetSortFieldDto,
    ImageSetSortOptionDto, PageRequestDto, PagedImageSetCatalogDto, SyncScanMode,
    UpdateImageSetFacetsDto, UpdateImageSetUserMetaDto,
};
use sea_orm::{ConnectionTrait, DatabaseBackend, Statement};
use tempfile::TempDir;

struct Fixture {
    _temp: TempDir,
    runtime: tokio::runtime::Runtime,
    root: PathBuf,
    library_id: String,
}

impl Fixture {
    /// `a2` (2 images), `a10` (1) are synced first; `b` (3) and root archive `pack.cbz` (4) later.
    fn new(db_name: &str) -> Self {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("pics");
        write_file(&root.join("a2/01.jpg"));
        write_file(&root.join("a2/02.jpg"));
        write_file(&root.join("a10/01.jpg"));
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        let library_id = runtime.block_on(async {
            init_db_at_path(&temp.path().join(db_name))
                .await
                .expect("init db");
            create_image_set_local_library(&root.to_string_lossy(), Some("Pics"))
                .await
                .expect("create image set library")
                .library_id
        });
        let fixture = Self {
            _temp: temp,
            runtime,
            root,
            library_id,
        };
        fixture.sync();
        std::thread::sleep(Duration::from_millis(20));
        for name in ["01.jpg", "02.jpg", "03.jpg"] {
            write_file(&fixture.root.join("b").join(name));
        }
        common::write_cbz(&fixture.root.join("pack.cbz"), 4);
        fixture.sync();
        fixture
    }

    fn sync(&self) {
        self.runtime
            .block_on(sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(self.library_id.as_str()),
                vec![],
                |_| {},
            ))
            .expect("sync");
    }

    fn id(&self, relative_path: &str) -> String {
        self.runtime
            .block_on(list_image_sets(&self.library_id))
            .expect("sets")
            .into_iter()
            .find(|set| set.relative_path == relative_path)
            .expect("set present")
            .image_set_id
    }

    fn facets(&self, relative_path: &str, patch: UpdateImageSetFacetsDto) {
        let id = self.id(relative_path);
        self.runtime
            .block_on(update_image_set_facets(&id, patch))
            .expect("facets");
    }

    fn filter(&self) -> ImageSetFilterDto {
        ImageSetFilterDto {
            library_id: self.library_id.clone(),
            ..Default::default()
        }
    }

    fn page(
        &self,
        filter: ImageSetFilterDto,
        sort: ImageSetSortOptionDto,
        grouping: ImageSetGroupingDto,
        page: i32,
        page_size: i32,
    ) -> PagedImageSetCatalogDto {
        self.runtime
            .block_on(fetch_image_sets_page(
                PageRequestDto { page, page_size },
                filter,
                sort,
                grouping,
            ))
            .expect("page")
    }

    fn paths(&self, filter: ImageSetFilterDto, sort: ImageSetSortOptionDto) -> Vec<String> {
        relative_paths(
            &self
                .page(filter, sort, ImageSetGroupingDto::None, 1, 100)
                .items,
        )
    }
}

fn write_file(path: &Path) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    fs::write(path, b"img").expect("write file");
}

fn names(values: &[&str]) -> Vec<String> {
    values.iter().map(|v| v.to_string()).collect()
}

fn relative_paths(items: &[ImageSetCatalogItemDto]) -> Vec<String> {
    items
        .iter()
        .map(|item| item.image_set.relative_path.clone())
        .collect()
}

fn sort(field: ImageSetSortFieldDto, descending: bool) -> ImageSetSortOptionDto {
    ImageSetSortOptionDto { field, descending }
}

fn facet(any: &[&str], unassigned: bool) -> ImageSetFacetFilterDto {
    ImageSetFacetFilterDto {
        any: names(any),
        unassigned,
    }
}

#[test]
fn sorts_by_name_naturally_and_reports_counts_and_shape() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_name.sqlite");
        let page = fixture.page(
            fixture.filter(),
            ImageSetSortOptionDto::default(),
            ImageSetGroupingDto::None,
            1,
            100,
        );

        assert_eq!(relative_paths(&page.items), ["a2", "a10", "b", "pack.cbz"]);
        assert_eq!(page.total_count, 4);
        let counts: Vec<i64> = page.items.iter().map(|item| item.image_count).collect();
        assert_eq!(counts, [2, 1, 3, 4]);
        let shapes: Vec<ImageSetCarrierShapeDto> =
            page.items.iter().map(|item| item.carrier_shape).collect();
        assert_eq!(
            shapes,
            [
                ImageSetCarrierShapeDto::Directory,
                ImageSetCarrierShapeDto::Directory,
                ImageSetCarrierShapeDto::Directory,
                ImageSetCarrierShapeDto::RootArchive,
            ]
        );
        assert!(page.items.iter().all(|item| item.group_author.is_none()));
        assert_eq!(
            fixture.paths(fixture.filter(), sort(ImageSetSortFieldDto::Name, true)),
            ["pack.cbz", "b", "a10", "a2"]
        );
    });
}

#[test]
fn display_name_and_relative_path_sorts_diverge_after_rename() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_rename.sqlite");
        let id = fixture.id("b");
        fixture
            .runtime
            .block_on(update_image_set_user_meta(
                &id,
                UpdateImageSetUserMetaDto {
                    name: Some("zzz".to_string()),
                },
            ))
            .expect("rename");

        assert_eq!(
            fixture.paths(fixture.filter(), sort(ImageSetSortFieldDto::Name, false)),
            ["a2", "a10", "pack.cbz", "b"]
        );
        assert_eq!(
            fixture.paths(
                fixture.filter(),
                sort(ImageSetSortFieldDto::RelativePath, false)
            ),
            ["a2", "a10", "b", "pack.cbz"]
        );
    });
}

#[test]
fn sorts_by_image_count_and_catalog_insertion_time() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_count_time.sqlite");
        assert_eq!(
            fixture.paths(
                fixture.filter(),
                sort(ImageSetSortFieldDto::ImageCount, true)
            ),
            ["pack.cbz", "b", "a2", "a10"]
        );
        assert_eq!(
            fixture.paths(
                fixture.filter(),
                sort(ImageSetSortFieldDto::ImageCount, false)
            ),
            ["a10", "a2", "b", "pack.cbz"]
        );
        // Ties within one sync fall back to display name ASC.
        assert_eq!(
            fixture.paths(
                fixture.filter(),
                sort(ImageSetSortFieldDto::CreatedAt, true)
            ),
            ["b", "pack.cbz", "a2", "a10"]
        );
        let page = fixture.page(
            fixture.filter(),
            sort(ImageSetSortFieldDto::CreatedAt, false),
            ImageSetGroupingDto::None,
            1,
            100,
        );
        assert_eq!(relative_paths(&page.items), ["a2", "a10", "b", "pack.cbz"]);
        assert!(page.items[0].created_at > 0);
        assert!(page.items[0].created_at < page.items[2].created_at);
    });
}

#[test]
fn resync_keeps_catalog_insertion_time() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_time_stable.sqlite");
        let created = |fixture: &Fixture| {
            fixture
                .page(
                    fixture.filter(),
                    sort(ImageSetSortFieldDto::RelativePath, false),
                    ImageSetGroupingDto::None,
                    1,
                    100,
                )
                .items
                .iter()
                .map(|item| item.created_at)
                .collect::<Vec<_>>()
        };
        let before = created(&fixture);
        write_file(&fixture.root.join("a2/03.jpg"));
        fixture.sync();
        assert_eq!(created(&fixture), before);
    });
}

#[test]
fn filters_by_carrier_shape() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_shape.sqlite");
        let shaped = |shape| ImageSetFilterDto {
            carrier_shape: Some(shape),
            ..fixture.filter()
        };
        assert_eq!(
            fixture.paths(
                shaped(ImageSetCarrierShapeDto::RootArchive),
                Default::default()
            ),
            ["pack.cbz"]
        );
        assert_eq!(
            fixture.paths(
                shaped(ImageSetCarrierShapeDto::Directory),
                Default::default()
            ),
            ["a2", "a10", "b"]
        );
    });
}

#[test]
fn facet_filters_match_any_name_or_unassigned_and_combine_with_and() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_facets.sqlite");
        fixture.facets(
            "a2",
            UpdateImageSetFacetsDto {
                tags: Some(names(&["Color"])),
                parodies: Some(names(&["Fate"])),
                characters: Some(names(&["Saber"])),
                ..Default::default()
            },
        );
        fixture.facets(
            "b",
            UpdateImageSetFacetsDto {
                tags: Some(names(&["mono"])),
                parodies: Some(names(&["Fate"])),
                ..Default::default()
            },
        );

        let tags = |any: &[&str], unassigned| ImageSetFilterDto {
            tags: facet(any, unassigned),
            ..fixture.filter()
        };
        assert_eq!(
            fixture.paths(tags(&[" color "], false), Default::default()),
            ["a2"]
        );
        assert_eq!(
            fixture.paths(tags(&["color", "MONO"], false), Default::default()),
            ["a2", "b"]
        );
        assert_eq!(
            fixture.paths(tags(&[], true), Default::default()),
            ["a10", "pack.cbz"]
        );
        assert_eq!(
            fixture.paths(tags(&["mono"], true), Default::default()),
            ["a10", "b", "pack.cbz"]
        );

        let combined = ImageSetFilterDto {
            parodies: facet(&["fate"], false),
            characters: facet(&[], true),
            ..fixture.filter()
        };
        assert_eq!(fixture.paths(combined, Default::default()), ["b"]);
    });
}

#[test]
fn author_filter_matches_any_bound_author_or_unassigned() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_authors.sqlite");
        fixture.facets(
            "a2",
            UpdateImageSetFacetsDto {
                authors: Some(names(&["Alice", "Bob"])),
                ..Default::default()
            },
        );
        fixture.facets(
            "b",
            UpdateImageSetFacetsDto {
                authors: Some(names(&["Bob"])),
                ..Default::default()
            },
        );
        let authors = |any: &[&str], unassigned| ImageSetFilterDto {
            authors: facet(any, unassigned),
            ..fixture.filter()
        };
        assert_eq!(
            fixture.paths(authors(&["bob"], false), Default::default()),
            ["a2", "b"]
        );
        assert_eq!(
            fixture.paths(authors(&["alice"], true), Default::default()),
            ["a2", "a10", "pack.cbz"]
        );
    });
}

#[test]
fn group_by_author_repeats_multi_author_sets_once_per_group_and_puts_unassigned_last() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_group.sqlite");
        fixture.facets(
            "a2",
            UpdateImageSetFacetsDto {
                authors: Some(names(&["Bob", "Alice"])),
                ..Default::default()
            },
        );
        fixture.facets(
            "b",
            UpdateImageSetFacetsDto {
                authors: Some(names(&["Bob"])),
                ..Default::default()
            },
        );

        let page = fixture.page(
            fixture.filter(),
            sort(ImageSetSortFieldDto::ImageCount, true),
            ImageSetGroupingDto::ByAuthor,
            1,
            100,
        );
        let rows: Vec<(Option<String>, String)> = page
            .items
            .iter()
            .map(|item| {
                (
                    item.group_author.as_ref().map(|a| a.name.clone()),
                    item.image_set.relative_path.clone(),
                )
            })
            .collect();
        let group = |name: &str| Some(name.to_string());
        assert_eq!(
            rows,
            [
                (group("Alice"), "a2".to_string()),
                (group("Bob"), "b".to_string()),
                (group("Bob"), "a2".to_string()),
                (None, "pack.cbz".to_string()),
                (None, "a10".to_string()),
            ]
        );
        assert_eq!(page.total_count, 5);
        assert!(page.items[0].group_author.as_ref().unwrap().author_id > 0);

        let bob_only = fixture.page(
            ImageSetFilterDto {
                authors: facet(&["bob"], false),
                ..fixture.filter()
            },
            Default::default(),
            ImageSetGroupingDto::ByAuthor,
            1,
            100,
        );
        let groups: Vec<Option<String>> = bob_only
            .items
            .iter()
            .map(|item| item.group_author.as_ref().map(|a| a.name.clone()))
            .collect();
        assert_eq!(groups, [group("Bob"), group("Bob")]);
        assert_eq!(relative_paths(&bob_only.items), ["a2", "b"]);
    });
}

#[test]
fn pages_are_windowed_and_clamped_to_the_last_page() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_pages.sqlite");
        let second = fixture.page(
            fixture.filter(),
            Default::default(),
            ImageSetGroupingDto::None,
            2,
            3,
        );
        assert_eq!(relative_paths(&second.items), ["pack.cbz"]);
        assert_eq!(
            (second.page, second.page_size, second.total_count),
            (2, 3, 4)
        );

        let beyond = fixture.page(
            fixture.filter(),
            Default::default(),
            ImageSetGroupingDto::None,
            9,
            3,
        );
        assert_eq!(beyond.page, 2);
        assert_eq!(relative_paths(&beyond.items), ["pack.cbz"]);
    });
}

#[test]
fn require_images_drops_empty_sets_and_library_scope_isolates_catalogs() {
    common::with_global_db(|| {
        let fixture = Fixture::new("query_empty.sqlite");
        fixture.runtime.block_on(async {
            connection()
                .expect("db")
                .execute(Statement::from_sql_and_values(
                    DatabaseBackend::Sqlite,
                    "INSERT INTO image_sets (image_set_id, library_id, relative_path, name, is_root, name_locked, created_at) \
                     VALUES ('empty-set', ?, 'empty', 'empty', 0, 0, 1)",
                    [fixture.library_id.clone().into()],
                ))
                .await
                .expect("insert empty set");
        });

        assert!(fixture
            .paths(fixture.filter(), Default::default())
            .contains(&"empty".to_string()));
        assert_eq!(
            fixture.paths(
                ImageSetFilterDto {
                    require_images: true,
                    ..fixture.filter()
                },
                Default::default()
            ),
            ["a2", "a10", "b", "pack.cbz"]
        );
        assert_eq!(
            fixture.paths(
                ImageSetFilterDto {
                    library_id: "other-library".to_string(),
                    ..Default::default()
                },
                Default::default()
            ),
            Vec::<String>::new()
        );
    });
}
