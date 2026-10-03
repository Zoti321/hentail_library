mod common;

use std::path::{Path, PathBuf};

use hentai_core::{
    close_reader, comic_id_from_path, count_all, count_all_series, count_named_facet_attachments,
    count_trashed_comics, create_local_library, create_remote_library, create_sync_handle,
    delete_library, export_comic_metadata, fetch_comics_page, fetch_reading_page,
    fetch_series_comics_page, fetch_series_page, fetch_trashed_comics_page, find_comic_by_id,
    find_series_by_id, import_comic_metadata, init_db_at_path, list_distinct_named_facet_names,
    open_reader, peek_metadata_backup_manifest, purge_comics, record_reading, restore_comics,
    search_by_keyword_page, search_by_tag_expression, series_id_from_folder_path,
    set_current_library_id, sync_library, trash_comics, try_acquire_library_write_lock,
    update_comic_user_meta, update_series_user_meta, watch_continue_reading_top5,
    watch_home_page_counts, watch_recently_added_on_home, ComicFilterDto, ComicSortOptionDto,
    ExportComicMetadataOptions, HentaiError, HentaiErrorCode, JunctionNamedFacet, LibraryDto,
    PageRequestDto, ReadingHistoryDto, SeriesFilterDto, SeriesSortOptionDto, SyncScanMode,
    UpdateComicUserMetaDto, UpdateSeriesUserMetaDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

fn write_cbz(path: &Path, pages: usize) {
    std::fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let file = std::fs::File::create(path).expect("create cbz");
    let mut zip = zip::ZipWriter::new(file);
    let options =
        zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
    use std::io::Write as _;
    for page in 0..pages {
        zip.start_file(format!("{page:03}.jpg"), options)
            .expect("start");
        zip.write_all(b"page").expect("write");
    }
    zip.finish().expect("finish");
}

/// `root/Series/a.cbz`, `root/Series/b.cbz`, `root/solo.cbz`（页数各不相同，避免 Path migration 误配）。
struct Fixture {
    _temp: TempDir,
    root: PathBuf,
    series_a: PathBuf,
    series_b: PathBuf,
    solo: PathBuf,
}

impl Fixture {
    fn new() -> Self {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib");
        let series_a = root.join("Series").join("a.cbz");
        let series_b = root.join("Series").join("b.cbz");
        let solo = root.join("solo.cbz");
        write_cbz(&series_a, 1);
        write_cbz(&series_b, 2);
        write_cbz(&solo, 3);
        Self {
            _temp: temp,
            root,
            series_a,
            series_b,
            solo,
        }
    }

    fn db_path(&self) -> PathBuf {
        self._temp.path().join("trash.sqlite")
    }
}

fn id_of(path: &Path) -> String {
    comic_id_from_path(&path.to_string_lossy())
}

fn series_id_of(fixture: &Fixture) -> String {
    series_id_from_folder_path(&fixture.root.join("Series").to_string_lossy())
}

fn run(test: impl FnOnce(Fixture, &tokio::runtime::Runtime)) {
    common::with_global_db(|| {
        let fixture = Fixture::new();
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        test(fixture, &runtime);
    });
}

async fn setup_local(fixture: &Fixture) -> LibraryDto {
    init_db_at_path(&fixture.db_path()).await.expect("init");
    let library = create_local_library(&fixture.root.to_string_lossy(), Some("Lib"))
        .await
        .expect("create lib");
    set_current_library_id(Some(&library.library_id))
        .await
        .expect("current");
    sync(&library).await;
    library
}

async fn sync(library: &LibraryDto) {
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
}

async fn catalog_ids(library: &LibraryDto) -> Vec<String> {
    fetch_comics_page(
        PageRequestDto {
            page: 1,
            page_size: 100,
        },
        ComicFilterDto {
            library_id: Some(library.library_id.clone()),
            ..Default::default()
        },
        false,
        ComicSortOptionDto::default(),
    )
    .await
    .expect("catalog")
    .items
    .into_iter()
    .map(|c| c.comic_id)
    .collect()
}

async fn series_page_ids(library: &LibraryDto) -> Vec<String> {
    fetch_series_page(
        PageRequestDto {
            page: 1,
            page_size: 100,
        },
        SeriesFilterDto {
            library_id: Some(library.library_id.clone()),
            ..Default::default()
        },
        SeriesSortOptionDto::default(),
    )
    .await
    .expect("series page")
    .items
    .into_iter()
    .map(|s| s.series_id)
    .collect()
}

async fn history_ids() -> Vec<String> {
    fetch_reading_page(1, 100, None)
        .await
        .expect("history")
        .items
        .into_iter()
        .map(|h| h.comic_id)
        .collect()
}

async fn trashed_ids() -> Vec<String> {
    fetch_trashed_comics_page(1, 100)
        .await
        .expect("trashed page")
        .items
        .into_iter()
        .map(|t| t.comic.comic_id)
        .collect()
}

/// Home 的 watch 接口先推一次快照；回调返回 Err 让其立即退出。
fn capture<T>(slot: &mut Option<T>) -> impl FnMut(T) -> Result<(), HentaiError> + '_ {
    move |value| {
        *slot = Some(value);
        Err(HentaiError::validation("stop"))
    }
}

async fn read(comic_id: &str) {
    record_reading(&ReadingHistoryDto {
        comic_id: comic_id.to_string(),
        title: "read".to_string(),
        last_read_time_ms: 1_000,
        page_index: Some(0),
    })
    .await
    .expect("record reading");
}

#[test]
fn trash_hides_comic_from_browse_surfaces_and_keeps_record() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            update_comic_user_meta(
                &solo,
                UpdateComicUserMetaDto {
                    tags: Some(vec!["trash-tag".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("tag");
            read(&solo).await;
            let count_before = count_all().await.expect("count");

            trash_comics(vec![solo.clone()]).await.expect("trash");

            assert!(!catalog_ids(&library).await.contains(&solo));
            assert_eq!(count_all().await.expect("count"), count_before - 1);
            let search = search_by_keyword_page("solo", 1, 50).await.expect("search");
            assert_eq!(search.total_count, 0);
            let by_tag = search_by_tag_expression(vec!["trash-tag".to_string()], vec![], vec![])
                .await
                .expect("tag search");
            assert!(by_tag.is_empty());
            assert!(!history_ids().await.contains(&solo));
            let tags =
                list_distinct_named_facet_names(JunctionNamedFacet::Tag, Some(library.library_id))
                    .await
                    .expect("tags");
            assert!(!tags.contains(&"trash-tag".to_string()));
            assert_eq!(
                count_named_facet_attachments(JunctionNamedFacet::Tag, "trash-tag")
                    .await
                    .expect("attachments"),
                0
            );

            let mut counts = None;
            let _ = watch_home_page_counts(false, capture(&mut counts)).await;
            assert_eq!(counts.expect("counts").comic_count as i64, count_before - 1);
            let mut continue_reading = None;
            let _ = watch_continue_reading_top5(false, capture(&mut continue_reading)).await;
            assert!(continue_reading
                .expect("continue reading")
                .iter()
                .all(|c| c.comic_id != solo));
            let mut recently_added = None;
            let _ = watch_recently_added_on_home(false, capture(&mut recently_added)).await;
            assert!(recently_added
                .expect("recently added")
                .iter()
                .all(|c| c.comic_id != solo));

            assert!(find_comic_by_id(&solo).await.expect("find").is_some());
            assert_eq!(trashed_ids().await, vec![solo.clone()]);
        });
        assert!(fixture.solo.exists(), "trash must not touch the Resource");
        let err = open_reader(&solo, &fixture.solo.to_string_lossy(), "cbz")
            .expect_err("trashed comic must not open");
        assert_eq!(err.code, HentaiErrorCode::ComicTrashed);
        close_reader(&solo);
    });
}

#[test]
fn restore_brings_back_metadata_locks_and_history() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            update_comic_user_meta(
                &solo,
                UpdateComicUserMetaDto {
                    title: Some("Custom".to_string()),
                    tags: Some(vec!["kept".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("meta");
            read(&solo).await;

            trash_comics(vec![solo.clone()]).await.expect("trash");
            restore_comics(vec![solo.clone()]).await.expect("restore");

            assert!(catalog_ids(&library).await.contains(&solo));
            assert!(history_ids().await.contains(&solo));
            let comic = find_comic_by_id(&solo).await.expect("find").expect("comic");
            assert_eq!(comic.title, "Custom");
            assert_eq!(comic.tags, vec!["kept".to_string()]);
            assert!(comic.locks.title && comic.locks.tags);
            assert!(trashed_ids().await.is_empty());
        });
        open_reader(&solo, &fixture.solo.to_string_lossy(), "cbz").expect("restored opens");
        close_reader(&solo);
    });
}

#[test]
fn series_members_count_only_visible_and_fully_trashed_series_hidden_but_kept() {
    run(|fixture, runtime| {
        let a = id_of(&fixture.series_a);
        let b = id_of(&fixture.series_b);
        let series_id = series_id_of(&fixture);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            update_series_user_meta(
                &series_id,
                UpdateSeriesUserMetaDto {
                    name: Some("My Series".to_string()),
                    serialization_status: Some("ended".to_string()),
                    total_count: Some(5),
                    clear_total_count: false,
                },
            )
            .await
            .expect("series meta");
            let series_count_before = count_all_series().await.expect("count series");

            trash_comics(vec![a.clone()]).await.expect("trash a");
            let members = fetch_series_comics_page(
                &series_id,
                PageRequestDto {
                    page: 1,
                    page_size: 50,
                },
            )
            .await
            .expect("members");
            assert_eq!(members.total_count, 1);
            assert_eq!(members.items[0].comic.comic_id, b);
            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series");
            assert_eq!(series.items.len(), 1);

            trash_comics(vec![b.clone()]).await.expect("trash b");
            assert!(!series_page_ids(&library).await.contains(&series_id));
            assert_eq!(
                count_all_series().await.expect("count series"),
                series_count_before - 1
            );

            // sync 后系列重建仍把 trash 成员计入成员，Series 记录与用户数据保留。
            sync(&library).await;
            restore_comics(vec![a.clone()]).await.expect("restore a");
            assert!(series_page_ids(&library).await.contains(&series_id));
            let series = find_series_by_id(&series_id)
                .await
                .expect("find")
                .expect("series kept");
            assert_eq!(series.name, "My Series");
            assert_eq!(series.serialization_status, "ended");
            assert_eq!(series.total_count, Some(5));
            assert!(series.locks.name);
            assert_eq!(series.items.len(), 1);
        });
    });
}

#[test]
fn sync_keeps_trashed_comic_and_orphan_cleanup_removes_it_when_resource_gone() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            trash_comics(vec![solo.clone()]).await.expect("trash");

            sync(&library).await;
            assert!(!catalog_ids(&library).await.contains(&solo));
            assert_eq!(trashed_ids().await, vec![solo.clone()]);

            std::fs::remove_file(&fixture.solo).expect("manual delete");
            sync(&library).await;
            assert!(find_comic_by_id(&solo).await.expect("find").is_none());
            assert!(trashed_ids().await.is_empty());
        });
    });
}

#[test]
fn path_migration_preserves_trash() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        let moved = fixture.root.join("moved.cbz");
        let moved_id = id_of(&moved);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            trash_comics(vec![solo.clone()]).await.expect("trash");

            std::fs::rename(&fixture.solo, &moved).expect("rename");
            sync(&library).await;

            assert!(find_comic_by_id(&solo).await.expect("find").is_none());
            assert!(find_comic_by_id(&moved_id).await.expect("find").is_some());
            assert_eq!(trashed_ids().await, vec![moved_id.clone()]);
            assert!(!catalog_ids(&library).await.contains(&moved_id));
        });
    });
}

#[test]
fn purge_local_deletes_resource_and_record() {
    run(|fixture, runtime| {
        let a = id_of(&fixture.series_a);
        let series_dir = fixture.root.join("Series");
        runtime.block_on(async {
            setup_local(&fixture).await;
            trash_comics(vec![a.clone()]).await.expect("trash");

            let result = purge_comics(vec![a.clone()]).await.expect("purge");

            assert_eq!(result.succeeded, 1);
            assert_eq!(result.failed, 0);
            assert!(find_comic_by_id(&a).await.expect("find").is_none());
            assert!(trashed_ids().await.is_empty());
        });
        assert!(
            !fixture.series_a.exists(),
            "local Resource should be deleted"
        );
        assert!(fixture.series_b.exists(), "sibling Resource must stay");
        assert!(series_dir.exists(), "Folder series directory must stay");
    });
}

#[test]
fn purge_rejects_comics_not_in_trash() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            setup_local(&fixture).await;

            let result = purge_comics(vec![solo.clone()]).await.expect("purge");

            assert_eq!(result.succeeded, 0);
            assert_eq!(result.failed, 1);
            assert!(!result.error_samples.is_empty());
            assert!(find_comic_by_id(&solo).await.expect("find").is_some());
        });
        assert!(fixture.solo.exists());
    });
}

#[test]
fn purge_batch_continues_after_failure_and_keeps_failed_in_trash() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        let outside = fixture._temp.path().join("outside.cbz");
        write_cbz(&outside, 4);
        let outside_id = id_of(&outside);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            let db = hentai_core::connection().expect("connection");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                 VALUES (?, ?, 'cbz', 4, 1, 1, ?)",
                [
                    outside_id.clone().into(),
                    outside.to_string_lossy().to_string().into(),
                    library.library_id.clone().into(),
                ],
            ))
            .await
            .expect("insert outside comic");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count, \
                 title_locked, description_locked, published_at_locked, content_rating_locked, authors_locked, \
                 tags_locked, languages, languages_locked, parodies_locked, characters_locked) \
                 VALUES (?, 'Outside', 'outside', 'unknown', 4, 0, 0, 0, 0, 0, 0, '[]', 0, 0, 0)",
                [outside_id.clone().into()],
            ))
            .await
            .expect("insert outside meta");
            trash_comics(vec![outside_id.clone(), solo.clone()])
                .await
                .expect("trash");

            let result = purge_comics(vec![outside_id.clone(), solo.clone()])
                .await
                .expect("purge");

            assert_eq!(result.succeeded, 1);
            assert_eq!(result.failed, 1);
            assert_eq!(result.error_samples.len(), 1);
            assert!(find_comic_by_id(&solo).await.expect("find").is_none());
            assert_eq!(trashed_ids().await, vec![outside_id.clone()]);
        });
        assert!(
            outside.exists(),
            "outside-root Resource must never be deleted"
        );
        assert!(!fixture.solo.exists());
    });
}

#[test]
fn purge_remote_only_clears_record() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let remote_path = "https://example.com/library/vol1.cbz";
        let comic_id = comic_id_from_path(remote_path);
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&temp.path().join("remote.sqlite"))
                .await
                .expect("init");
            let library =
                create_remote_library("https://example.com/library", "user", false, Some("Remote"))
                    .await
                    .expect("create remote");
            let db = hentai_core::connection().expect("connection");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id) \
                 VALUES (?, ?, 'cbz', 4, 1, 1, ?)",
                [
                    comic_id.clone().into(),
                    remote_path.to_string().into(),
                    library.library_id.clone().into(),
                ],
            ))
            .await
            .expect("insert comic");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count, \
                 title_locked, description_locked, published_at_locked, content_rating_locked, authors_locked, \
                 tags_locked, languages, languages_locked, parodies_locked, characters_locked) \
                 VALUES (?, 'Remote', 'remote', 'unknown', 1, 0, 0, 0, 0, 0, 0, '[]', 0, 0, 0)",
                [comic_id.clone().into()],
            ))
            .await
            .expect("insert meta");

            trash_comics(vec![comic_id.clone()]).await.expect("trash");
            let page = fetch_trashed_comics_page(1, 10).await.expect("page");
            assert_eq!(page.items[0].library_kind, "remote");
            assert_eq!(page.items[0].library_name, "Remote");
            let counts = count_trashed_comics().await.expect("counts");
            assert_eq!((counts.total, counts.local, counts.remote), (1, 0, 1));

            let result = purge_comics(vec![comic_id.clone()]).await.expect("purge");
            assert_eq!(result.succeeded, 1);
            assert!(find_comic_by_id(&comic_id).await.expect("find").is_none());
        });
    });
}

#[test]
fn trashed_list_orders_by_deleted_at_desc_with_library_info() {
    run(|fixture, runtime| {
        let a = id_of(&fixture.series_a);
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            setup_local(&fixture).await;
            trash_comics(vec![a.clone()]).await.expect("trash a");
            tokio::time::sleep(std::time::Duration::from_millis(5)).await;
            trash_comics(vec![solo.clone()]).await.expect("trash solo");

            let page = fetch_trashed_comics_page(1, 10).await.expect("page");
            assert_eq!(page.total_count, 2);
            let ids: Vec<String> = page
                .items
                .iter()
                .map(|t| t.comic.comic_id.clone())
                .collect();
            assert_eq!(ids, vec![solo.clone(), a.clone()]);
            assert!(page.items[0].deleted_at >= page.items[1].deleted_at);
            assert_eq!(page.items[0].library_name, "Lib");
            assert_eq!(page.items[0].library_kind, "local");
            let counts = count_trashed_comics().await.expect("counts");
            assert_eq!((counts.total, counts.local, counts.remote), (2, 2, 0));

            let second = fetch_trashed_comics_page(2, 1).await.expect("page 2");
            assert_eq!(second.items[0].comic.comic_id, a);
        });
    });
}

#[test]
fn delete_library_clears_trashed_records_without_touching_disk() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            let library = setup_local(&fixture).await;
            trash_comics(vec![solo.clone()]).await.expect("trash");

            delete_library(&library.library_id)
                .await
                .expect("delete lib");

            assert!(find_comic_by_id(&solo).await.expect("find").is_none());
            assert!(trashed_ids().await.is_empty());
        });
        assert!(fixture.solo.exists());
    });
}

#[test]
fn metadata_backup_export_excludes_trash_and_import_keeps_trash() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            setup_local(&fixture).await;
            update_comic_user_meta(
                &solo,
                UpdateComicUserMetaDto {
                    title: Some("Backed Up".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("meta");
            let options = || ExportComicMetadataOptions {
                library_id: None,
                include_orphan_facets: false,
            };
            let full = export_comic_metadata(options()).await.expect("export");
            let full_count = peek_metadata_backup_manifest(&full)
                .expect("peek")
                .comic_count;

            trash_comics(vec![solo.clone()]).await.expect("trash");
            let without_trash = export_comic_metadata(options()).await.expect("export");
            assert_eq!(
                peek_metadata_backup_manifest(&without_trash)
                    .expect("peek")
                    .comic_count,
                full_count - 1
            );

            update_comic_user_meta(
                &solo,
                UpdateComicUserMetaDto {
                    title: Some("Changed".to_string()),
                    ..Default::default()
                },
            )
            .await
            .expect("meta");
            let result = import_comic_metadata(&full).await.expect("import");
            assert!(result.errors.is_empty());
            let comic = find_comic_by_id(&solo).await.expect("find").expect("comic");
            assert_eq!(comic.title, "Backed Up");
            assert_eq!(trashed_ids().await, vec![solo.clone()]);
        });
    });
}

#[test]
fn trash_restore_purge_fail_fast_while_library_write_lock_held() {
    run(|fixture, runtime| {
        let solo = id_of(&fixture.solo);
        runtime.block_on(async {
            setup_local(&fixture).await;
            {
                let _guard = try_acquire_library_write_lock().expect("hold lock");
                assert!(trash_comics(vec![solo.clone()]).await.is_err());
                assert!(restore_comics(vec![solo.clone()]).await.is_err());
                assert!(purge_comics(vec![solo.clone()]).await.is_err());
            }
            assert!(trashed_ids().await.is_empty());
            trash_comics(vec![solo.clone()])
                .await
                .expect("trash after release");
        });
    });
}
