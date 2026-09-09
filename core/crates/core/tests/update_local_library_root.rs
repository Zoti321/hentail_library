use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    comic_id_from_path, connection, create_local_library, find_comic_by_id,
    find_series_by_id, find_series_thumbnail_by_series_id, get_reading_by_comic_id,
    init_db_at_path, list_libraries, record_reading, series_id_from_folder_path,
    try_acquire_library_write_lock, update_comic_user_meta, update_local_library_root,
    update_series_item_sort_order, update_series_user_meta, ReadingHistoryDto,
    UpdateComicUserMetaDto, UpdateSeriesUserMetaDto,
};
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, Statement};
use tempfile::TempDir;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .expect("global db tests must run serially");
    test();
}

fn fixture_sql() -> String {
    std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/drift_v2.sql"),
    )
    .expect("read drift_v2.sql")
}

fn create_fixture_db(dir: &Path) -> PathBuf {
    let db_path = dir.join("fixture.sqlite");
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        let conn = Database::connect(format!(
            "sqlite://{}?mode=rwc",
            db_path.to_string_lossy().replace('\\', "/")
        ))
        .await
        .expect("connect");
        for stmt in fixture_sql().split(';') {
            let sql = stmt.trim();
            if sql.is_empty() || sql.starts_with("--") {
                continue;
            }
            conn.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                sql.to_string(),
            ))
            .await
            .expect("execute sql");
        }
    });
    db_path
}

fn write_cbz(path: &Path) {
    let file = std::fs::File::create(path).expect("create cbz");
    let mut zip = zip::ZipWriter::new(file);
    zip.start_file("01.jpg", zip::write::SimpleFileOptions::default())
        .expect("start page");
    use std::io::Write;
    zip.write_all(b"fake-page").expect("write page");
    zip.finish().expect("finish cbz");
}

async fn seed_comic(
    db: &DatabaseConnection,
    library_id: &str,
    comic_id: &str,
    path: &str,
    title: &str,
    title_locked: bool,
) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "INSERT INTO comics (comic_id, library_id, path, resource_type, resource_size, created_at, last_updated_at) \
             VALUES ('{comic_id}', '{library_id}', '{path}', 'cbz', 1, 1, 1)"
        ),
    ))
    .await
    .expect("insert comic");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        format!(
            "INSERT INTO comic_meta (comic_id, title, content_rating, page_count, title_locked, tags_locked) \
             VALUES ('{comic_id}', '{title}', 'unknown', 1, {}, 1)",
            if title_locked { 1 } else { 0 }
        ),
    ))
    .await
    .expect("insert meta");
}

#[test]
fn update_local_library_root_keeps_library_id_and_rejects_nesting() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        let root_a_child = root_a.join("nested");
        let root_b_child = root_b.join("child");
        let root_a_moved = temp.path().join("lib_a_moved");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        std::fs::create_dir_all(&root_a_child).expect("mkdir nested");
        std::fs::create_dir_all(&root_b_child).expect("mkdir b/child");
        std::fs::create_dir_all(&root_a_moved).expect("mkdir moved");

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");

            let lib_a = create_local_library(&root_a.to_string_lossy(), Some("Alpha"))
                .await
                .expect("create a");
            let _lib_b = create_local_library(&root_b.to_string_lossy(), Some("Beta"))
                .await
                .expect("create b");

            let nested_other = update_local_library_root(
                &lib_a.library_id,
                &root_b_child.to_string_lossy(),
            )
            .await
            .expect_err("nested under other library should fail");
            assert!(
                nested_other.to_string().contains("嵌套"),
                "unexpected: {nested_other}"
            );

            // Moving into a child of the current root is allowed (Komga warns; sync may orphan).
            let into_child = update_local_library_root(
                &lib_a.library_id,
                &root_a_child.to_string_lossy(),
            )
            .await
            .expect("move into own child");
            assert_eq!(into_child.library_id, lib_a.library_id);

            let updated = update_local_library_root(
                &lib_a.library_id,
                &root_a_moved.to_string_lossy(),
            )
            .await
            .expect("move root");
            assert_eq!(updated.library_id, lib_a.library_id);
            assert_eq!(updated.name, "Alpha");
            assert_eq!(
                updated.root_path.replace('\\', "/"),
                root_a_moved.to_string_lossy().replace('\\', "/")
            );

            let listed = list_libraries().await.expect("list");
            let again = listed
                .iter()
                .find(|l| l.library_id == lib_a.library_id)
                .expect("still present");
            assert_eq!(
                again.root_path.replace('\\', "/"),
                updated.root_path.replace('\\', "/")
            );
        });
    });
}

#[test]
fn update_local_library_root_remaps_comics_series_and_user_state_when_readable() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let old_root = temp.path().join("lib_old");
        let series_old = old_root.join("SeriesA");
        std::fs::create_dir_all(&series_old).expect("mkdir old series");
        let old_comic_path = series_old.join("a.cbz");
        write_cbz(&old_comic_path);

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let db = connection().expect("connection");

            let library = create_local_library(&old_root.to_string_lossy(), Some("Alpha"))
                .await
                .expect("create library");
            let old_comic_id = comic_id_from_path(&old_comic_path.to_string_lossy());
            seed_comic(
                &db,
                &library.library_id,
                &old_comic_id,
                &old_comic_path.to_string_lossy().replace('\\', "/"),
                "用户标题",
                true,
            )
            .await;
            update_comic_user_meta(
                &old_comic_id,
                UpdateComicUserMetaDto {
                    title: Some("用户标题".to_string()),
                    tags: Some(vec!["标签A".to_string()]),
                    ..Default::default()
                },
            )
            .await
            .expect("update meta");
            record_reading(&ReadingHistoryDto {
                comic_id: old_comic_id.clone(),
                title: "用户标题".to_string(),
                last_read_time_ms: 42,
                page_index: Some(3),
            })
            .await
            .expect("record reading");

            let old_series_path = series_old.to_string_lossy().replace('\\', "/");
            let old_series_id = series_id_from_folder_path(&old_series_path);
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO series (series_id, folder_path, name, name_sort_key, serialization_status, total_count, library_id) \
                     VALUES ('{old_series_id}', '{old_series_path}', 'SeriesA', 'seriesa', 'unknown', NULL, '{}')",
                    library.library_id
                ),
            ))
            .await
            .expect("insert series");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO series_items (series_id, comic_id, sort_order, sort_order_locked) \
                     VALUES ('{old_series_id}', '{old_comic_id}', 1.0, 0)"
                ),
            ))
            .await
            .expect("insert series item");
            update_series_user_meta(
                &old_series_id,
                UpdateSeriesUserMetaDto {
                    name: Some("自定义系列名".to_string()),
                    serialization_status: Some("ongoing".to_string()),
                    total_count: Some(12),
                    clear_total_count: false,
                },
            )
            .await
            .expect("update series meta");
            update_series_item_sort_order(&old_series_id, &old_comic_id, 9.5)
                .await
                .expect("lock sort order");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "INSERT INTO series_thumbnails (series_id, thumbnail, updated_at, source_comic_id, source_page_index) \
                     VALUES ('{old_series_id}', X'0102', 7, '{old_comic_id}', 0)"
                ),
            ))
            .await
            .expect("insert series thumbnail");

            let new_root = temp.path().join("lib_new");
            std::fs::rename(&old_root, &new_root).expect("rename root");
            let new_comic_path = new_root.join("SeriesA").join("a.cbz");
            let new_comic_id = comic_id_from_path(&new_comic_path.to_string_lossy());
            let new_series_path = new_root.join("SeriesA").to_string_lossy().replace('\\', "/");
            let new_series_id = series_id_from_folder_path(&new_series_path);

            let updated = update_local_library_root(&library.library_id, &new_root.to_string_lossy())
                .await
                .expect("update root");
            assert_eq!(updated.library_id, library.library_id);
            assert_eq!(updated.name, "Alpha");
            assert_eq!(
                updated.root_path.replace('\\', "/"),
                new_root.to_string_lossy().replace('\\', "/")
            );

            assert!(find_comic_by_id(&old_comic_id).await.expect("find old").is_none());
            let comic = find_comic_by_id(&new_comic_id)
                .await
                .expect("find new")
                .expect("new comic");
            assert_eq!(comic.title, "用户标题");
            assert_eq!(comic.tags, vec!["标签A".to_string()]);
            assert!(comic.locks.title);
            assert_eq!(comic.path.replace('\\', "/"), new_comic_path.to_string_lossy().replace('\\', "/"));

            let reading = get_reading_by_comic_id(&new_comic_id)
                .await
                .expect("reading")
                .expect("migrated reading");
            assert_eq!(reading.last_read_time_ms, 42);
            assert_eq!(reading.page_index, Some(3));

            assert!(find_series_by_id(&old_series_id).await.expect("old series").is_none());
            let series = find_series_by_id(&new_series_id)
                .await
                .expect("new series")
                .expect("series exists");
            assert_eq!(series.name, "自定义系列名");
            assert_eq!(series.serialization_status, "ongoing");
            assert_eq!(series.total_count, Some(12));
            assert!(series.locks.name);
            assert!(series.locks.serialization_status);
            assert!(series.locks.total_count);
            assert_eq!(series.items.len(), 1);
            assert_eq!(series.items[0].comic_id, new_comic_id);
            assert!(series.items[0].sort_order_locked);
            assert!((series.items[0].sort_order - 9.5).abs() < f64::EPSILON);

            let thumb = find_series_thumbnail_by_series_id(&new_series_id)
                .await
                .expect("thumb")
                .expect("thumb exists");
            assert_eq!(thumb.source_comic_id, new_comic_id);
            assert!(
                find_series_thumbnail_by_series_id(&old_series_id)
                    .await
                    .expect("old thumb")
                    .is_none()
            );
        });
    });
}

#[test]
fn update_local_library_root_skips_missing_relative_paths_but_commits_root_change() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let old_root = temp.path().join("lib_old");
        let new_root = temp.path().join("lib_new");
        std::fs::create_dir_all(&old_root).expect("mkdir old");
        std::fs::create_dir_all(&new_root).expect("mkdir new");
        let keep_old = old_root.join("keep.cbz");
        let miss_old = old_root.join("miss.cbz");
        write_cbz(&keep_old);
        write_cbz(&miss_old);
        write_cbz(&new_root.join("keep.cbz"));

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let db = connection().expect("connection");
            let library = create_local_library(&old_root.to_string_lossy(), Some("Alpha"))
                .await
                .expect("create library");

            let keep_old_id = comic_id_from_path(&keep_old.to_string_lossy());
            let miss_old_id = comic_id_from_path(&miss_old.to_string_lossy());
            seed_comic(
                &db,
                &library.library_id,
                &keep_old_id,
                &keep_old.to_string_lossy().replace('\\', "/"),
                "Keep",
                false,
            )
            .await;
            seed_comic(
                &db,
                &library.library_id,
                &miss_old_id,
                &miss_old.to_string_lossy().replace('\\', "/"),
                "Miss",
                false,
            )
            .await;

            let updated = update_local_library_root(&library.library_id, &new_root.to_string_lossy())
                .await
                .expect("update root");
            assert_eq!(
                updated.root_path.replace('\\', "/"),
                new_root.to_string_lossy().replace('\\', "/")
            );

            let keep_new_id = comic_id_from_path(&new_root.join("keep.cbz").to_string_lossy());
            assert!(find_comic_by_id(&keep_old_id).await.expect("old keep").is_none());
            assert!(find_comic_by_id(&keep_new_id).await.expect("new keep").is_some());
            assert!(find_comic_by_id(&miss_old_id).await.expect("miss old").is_some());
        });
    });
}

#[test]
fn update_local_library_root_saves_unreadable_root_without_migration() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let old_root = temp.path().join("lib_old");
        std::fs::create_dir_all(&old_root).expect("mkdir old");
        let old_comic_path = old_root.join("a.cbz");
        write_cbz(&old_comic_path);
        let unreadable_root = temp.path().join("missing_root");

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let db = connection().expect("connection");
            let library = create_local_library(&old_root.to_string_lossy(), Some("Alpha"))
                .await
                .expect("create library");
            let old_comic_id = comic_id_from_path(&old_comic_path.to_string_lossy());
            seed_comic(
                &db,
                &library.library_id,
                &old_comic_id,
                &old_comic_path.to_string_lossy().replace('\\', "/"),
                "Keep",
                false,
            )
            .await;

            let updated =
                update_local_library_root(&library.library_id, &unreadable_root.to_string_lossy())
                    .await
                    .expect("save unreadable root");
            assert_eq!(
                updated.root_path.replace('\\', "/"),
                unreadable_root.to_string_lossy().replace('\\', "/")
            );
            assert!(find_comic_by_id(&old_comic_id).await.expect("old comic").is_some());
        });
    });
}

#[test]
fn update_local_library_root_fails_immediately_when_library_write_lock_is_busy() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let old_root = temp.path().join("lib_old");
        let new_root = temp.path().join("lib_new");
        std::fs::create_dir_all(&old_root).expect("mkdir old");
        std::fs::create_dir_all(&new_root).expect("mkdir new");

        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init");
            let library = create_local_library(&old_root.to_string_lossy(), Some("Alpha"))
                .await
                .expect("create library");

            let guard = try_acquire_library_write_lock().expect("acquire busy guard");
            let err = update_local_library_root(&library.library_id, &new_root.to_string_lossy())
                .await
                .expect_err("busy should fail");
            drop(guard);
            assert!(err.to_string().contains("库写入操作进行中"));

            let listed = list_libraries().await.expect("list");
            let current = listed
                .iter()
                .find(|row| row.library_id == library.library_id)
                .expect("library");
            assert_eq!(
                current.root_path.replace('\\', "/"),
                old_root.to_string_lossy().replace('\\', "/")
            );
        });
    });
}
