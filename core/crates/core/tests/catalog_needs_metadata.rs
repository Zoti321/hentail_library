mod common;

use hentai_core::sync::writer::replace_comic_authors;
use hentai_core::util::compute_sort_key;
use hentai_core::{
    connection, create_local_library, fetch_comics_page, init_db_at_path, set_comic_meta_locks,
    set_current_library_id, update_comic_user_meta, ComicFilterDto, ComicSortFieldDto,
    ComicSortOptionDto, PageRequestDto, SetComicMetaLocksDto, UpdateComicUserMetaDto,
};
use sea_orm::{ConnectionTrait, DatabaseConnection, Statement, Value};
use tempfile::TempDir;

fn text(s: &str) -> Value {
    Value::String(Some(Box::new(s.to_string())))
}

async fn exec(db: &DatabaseConnection, sql: &str, values: Vec<Value>) {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        sql,
        values,
    ))
    .await
    .expect(sql);
}

async fn clear_library(db: &DatabaseConnection) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items; DELETE FROM series; DELETE FROM comic_tags; \
         DELETE FROM comic_authors; DELETE FROM comic_parodies; DELETE FROM comic_characters; \
         DELETE FROM comic_meta; DELETE FROM comics"
            .to_string(),
    ))
    .await
    .expect("clear");
}

async fn insert_comic(db: &DatabaseConnection, comic_id: &str, resource_type: &str) {
    exec(
        db,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES (?, ?, ?, 1, 1, 1)",
        vec![
            text(comic_id),
            text(&format!("E:/lib/{comic_id}.{resource_type}")),
            text(resource_type),
        ],
    )
    .await;
    exec(
        db,
        "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
         VALUES (?, ?, ?, 'unknown', 1)",
        vec![
            text(comic_id),
            text(comic_id),
            text(&compute_sort_key(comic_id)),
        ],
    )
    .await;
}

async fn stamp_all_to_current_library(db: &DatabaseConnection) {
    let lib = create_local_library("E:/lib", None)
        .await
        .expect("create library");
    set_current_library_id(Some(&lib.library_id))
        .await
        .expect("set current");
    exec(
        db,
        "UPDATE comics SET library_id = ?",
        vec![text(&lib.library_id)],
    )
    .await;
}

async fn fetch_ids(filter: ComicFilterDto, page_size: i32) -> (Vec<String>, i64) {
    let page = fetch_comics_page(
        PageRequestDto { page: 1, page_size },
        filter,
        false,
        ComicSortOptionDto {
            field: ComicSortFieldDto::Title,
            descending: false,
        },
    )
    .await
    .expect("page");
    (
        page.items.into_iter().map(|c| c.comic_id).collect(),
        page.total_count,
    )
}

fn needs_metadata_filter() -> ComicFilterDto {
    ComicFilterDto {
        needs_metadata_only: true,
        ..Default::default()
    }
}

fn run<F: std::future::Future<Output = ()>>(body: impl FnOnce(DatabaseConnection) -> F) {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            clear_library(&db).await;
            body(db).await;
        });
    });
}

async fn update(comic_id: &str, meta: UpdateComicUserMetaDto) {
    update_comic_user_meta(comic_id, meta)
        .await
        .expect("update meta");
}

#[test]
fn needs_metadata_keeps_title_only_comics_and_excludes_each_metadata_field() {
    run(|db| async move {
        for id in [
            "a-blank",
            "b-tag",
            "c-author",
            "d-parody",
            "e-character",
            "f-language",
            "g-description",
            "h-published",
            "i-safe",
            "j-r18",
        ] {
            insert_comic(&db, id, "cbz").await;
        }
        stamp_all_to_current_library(&db).await;

        update(
            "b-tag",
            UpdateComicUserMetaDto {
                tags: Some(vec!["yuri".to_string()]),
                ..Default::default()
            },
        )
        .await;
        update(
            "c-author",
            UpdateComicUserMetaDto {
                authors: Some(vec!["Alice".to_string()]),
                ..Default::default()
            },
        )
        .await;
        update(
            "d-parody",
            UpdateComicUserMetaDto {
                parodies: Some(vec!["Fate".to_string()]),
                ..Default::default()
            },
        )
        .await;
        update(
            "e-character",
            UpdateComicUserMetaDto {
                characters: Some(vec!["Saber".to_string()]),
                ..Default::default()
            },
        )
        .await;
        update(
            "f-language",
            UpdateComicUserMetaDto {
                languages: Some(vec!["Chinese".to_string()]),
                ..Default::default()
            },
        )
        .await;
        update(
            "g-description",
            UpdateComicUserMetaDto {
                description: Some("概要".to_string()),
                ..Default::default()
            },
        )
        .await;
        update(
            "h-published",
            UpdateComicUserMetaDto {
                published_at: Some(1_600_000_000_000),
                ..Default::default()
            },
        )
        .await;
        update(
            "i-safe",
            UpdateComicUserMetaDto {
                content_rating: Some("safe".to_string()),
                ..Default::default()
            },
        )
        .await;
        update(
            "j-r18",
            UpdateComicUserMetaDto {
                content_rating: Some("r18".to_string()),
                ..Default::default()
            },
        )
        .await;

        let (ids, total) = fetch_ids(needs_metadata_filter(), 50).await;
        assert_eq!(ids, vec!["a-blank"]);
        assert_eq!(total, 1);
    });
}

#[test]
fn needs_metadata_excludes_scan_written_metadata_and_treats_blank_description_as_empty() {
    run(|db| async move {
        insert_comic(&db, "a-blank-description", "cbz").await;
        insert_comic(&db, "b-scan-author", "cbz").await;
        insert_comic(&db, "c-scan-description", "cbz").await;
        insert_comic(&db, "d-empty-language-entry", "cbz").await;
        stamp_all_to_current_library(&db).await;

        exec(
            &db,
            "UPDATE comic_meta SET description = '  ' WHERE comic_id = 'a-blank-description'",
            vec![],
        )
        .await;
        replace_comic_authors(&db, "b-scan-author", &["Bob".to_string()])
            .await
            .expect("scan authors");
        exec(
            &db,
            "UPDATE comic_meta SET description = 'from ComicInfo.xml' \
             WHERE comic_id = 'c-scan-description'",
            vec![],
        )
        .await;
        exec(
            &db,
            "UPDATE comic_meta SET languages = '[\"\"]' WHERE comic_id = 'd-empty-language-entry'",
            vec![],
        )
        .await;

        let (ids, _) = fetch_ids(needs_metadata_filter(), 50).await;
        assert_eq!(ids, vec!["a-blank-description", "d-empty-language-entry"]);
    });
}

#[test]
fn needs_metadata_ignores_field_locks_with_empty_values() {
    run(|db| async move {
        insert_comic(&db, "a-locked-empty", "cbz").await;
        stamp_all_to_current_library(&db).await;
        set_comic_meta_locks(
            "a-locked-empty",
            SetComicMetaLocksDto {
                tags: Some(true),
                authors: Some(true),
                description: Some(true),
                content_rating: Some(true),
                ..Default::default()
            },
        )
        .await
        .expect("locks");

        let (ids, _) = fetch_ids(needs_metadata_filter(), 50).await;
        assert_eq!(ids, vec!["a-locked-empty"]);
    });
}

#[test]
fn needs_metadata_combines_with_other_filters_and_count_matches_pages() {
    run(|db| async move {
        insert_comic(&db, "a-pdf-blank", "pdf").await;
        insert_comic(&db, "b-pdf-blank", "pdf").await;
        insert_comic(&db, "c-pdf-blank", "pdf").await;
        insert_comic(&db, "d-pdf-tagged", "pdf").await;
        insert_comic(&db, "e-cbz-blank", "cbz").await;
        stamp_all_to_current_library(&db).await;
        update(
            "d-pdf-tagged",
            UpdateComicUserMetaDto {
                tags: Some(vec!["yuri".to_string()]),
                ..Default::default()
            },
        )
        .await;

        let pdf_needs_metadata = ComicFilterDto {
            needs_metadata_only: true,
            resource_types: vec!["pdf".to_string()],
            ..Default::default()
        };
        let (first_page, total) = fetch_ids(pdf_needs_metadata.clone(), 2).await;
        assert_eq!(first_page, vec!["a-pdf-blank", "b-pdf-blank"]);
        assert_eq!(total, 3);

        let (all, total_all) = fetch_ids(pdf_needs_metadata, 50).await;
        assert_eq!(all, vec!["a-pdf-blank", "b-pdf-blank", "c-pdf-blank"]);
        assert_eq!(total_all, all.len() as i64);

        let (unfiltered, unfiltered_total) = fetch_ids(ComicFilterDto::default(), 50).await;
        assert_eq!(unfiltered.len(), 5);
        assert_eq!(unfiltered_total, 5);
    });
}
