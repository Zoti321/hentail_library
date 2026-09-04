//! Named metadata facet seam: junction replace + dict list + library-scoped distinct.

use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use hentai_core::{
    connection, create_local_library, init_db_at_path, list_all_named_facet_names,
    list_distinct_named_facet_names, replace_comic_named_facet, JunctionNamedFacet,
};
use sea_orm::{ConnectionTrait, Database, Statement};
use tempfile::TempDir;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    test();
}

fn fixture_sql() -> String {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    fs::read_to_string(manifest_dir.join("../../tests/fixtures/drift_v2.sql"))
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

async fn clear_facet_tables(db: &impl ConnectionTrait) {
    for table in [
        "comic_parodies",
        "comic_characters",
        "comic_tags",
        "comic_authors",
        "comic_meta",
        "comics",
        "parodies",
        "characters",
        "tags",
        "authors",
    ] {
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            format!("DELETE FROM {table}"),
        ))
        .await
        .expect("clear table");
    }
}

async fn seed_comic(db: &impl ConnectionTrait, comic_id: &str, library_id: &str, path: &str) {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, library_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES (?, ?, ?, 'cbz', 1, 1, 1)",
        [
            comic_id.into(),
            library_id.into(),
            path.into(),
        ],
    ))
    .await
    .expect("seed comic");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) VALUES (?, ?, 'unknown', 1)",
        [comic_id.into(), comic_id.into()],
    ))
    .await
    .expect("seed meta");
}

async fn junction_names(
    db: &impl ConnectionTrait,
    table: &str,
    name_col: &str,
    comic_id: &str,
) -> Vec<String> {
    let rows = db
        .query_all(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            format!("SELECT {name_col} FROM {table} WHERE comic_id = ? ORDER BY {name_col}"),
            [comic_id.into()],
        ))
        .await
        .expect("query junction");
    rows.into_iter()
        .map(|row| row.try_get_by_index::<String>(0).expect("name"))
        .collect()
}

#[test]
fn replace_comic_named_facet_upserts_dict_and_replaces_junction() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create library");
            let db = connection().expect("connection");
            clear_facet_tables(&db).await;
            seed_comic(&db, "c-a", &lib.library_id, "E:/lib-a/a.cbz").await;

            replace_comic_named_facet(
                &db,
                JunctionNamedFacet::Parody,
                "c-a",
                &[
                    "Fate".to_string(),
                    "Fate".to_string(),
                    "Touhou".to_string(),
                ],
            )
            .await
            .expect("replace");

            assert_eq!(
                junction_names(&db, "comic_parodies", "parody_name", "c-a").await,
                vec!["Fate".to_string(), "Touhou".to_string()]
            );
            let dict = list_all_named_facet_names(JunctionNamedFacet::Parody)
                .await
                .expect("list all");
            assert_eq!(dict, vec!["Fate".to_string(), "Touhou".to_string()]);

            replace_comic_named_facet(
                &db,
                JunctionNamedFacet::Parody,
                "c-a",
                &["Genshin".to_string()],
            )
            .await
            .expect("replace again");

            assert_eq!(
                junction_names(&db, "comic_parodies", "parody_name", "c-a").await,
                vec!["Genshin".to_string()]
            );
            let dict = list_all_named_facet_names(JunctionNamedFacet::Parody)
                .await
                .expect("list all");
            assert_eq!(
                dict,
                vec![
                    "Fate".to_string(),
                    "Genshin".to_string(),
                    "Touhou".to_string()
                ]
            );
        });
    });
}

#[test]
fn list_distinct_named_facet_names_scopes_to_library() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root_a = temp.path().join("lib_a");
        let root_b = temp.path().join("lib_b");
        std::fs::create_dir_all(&root_a).expect("mkdir a");
        std::fs::create_dir_all(&root_b).expect("mkdir b");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib_a = create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("lib a");
            let lib_b = create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("lib b");
            let db = connection().expect("connection");
            clear_facet_tables(&db).await;
            seed_comic(&db, "c-a", &lib_a.library_id, "E:/lib-a/a.cbz").await;
            seed_comic(&db, "c-b", &lib_b.library_id, "E:/lib-b/b.cbz").await;

            replace_comic_named_facet(
                &db,
                JunctionNamedFacet::Character,
                "c-a",
                &["Reimu".to_string()],
            )
            .await
            .expect("attach a");
            replace_comic_named_facet(
                &db,
                JunctionNamedFacet::Character,
                "c-b",
                &["Marisa".to_string()],
            )
            .await
            .expect("attach b");

            let in_a = list_distinct_named_facet_names(
                JunctionNamedFacet::Character,
                Some(lib_a.library_id.clone()),
            )
            .await
            .expect("distinct a");
            assert_eq!(in_a, vec!["Reimu".to_string()]);

            let in_b = list_distinct_named_facet_names(
                JunctionNamedFacet::Character,
                Some(lib_b.library_id.clone()),
            )
            .await
            .expect("distinct b");
            assert_eq!(in_b, vec!["Marisa".to_string()]);
        });
    });
}

#[test]
fn replace_comic_named_facet_works_for_all_junction_facets() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("create library");
            let db = connection().expect("connection");
            clear_facet_tables(&db).await;
            seed_comic(&db, "c-a", &lib.library_id, "E:/lib-a/a.cbz").await;

            for (facet, table, col) in [
                (JunctionNamedFacet::Tag, "comic_tags", "tag_name"),
                (JunctionNamedFacet::Author, "comic_authors", "author_name"),
                (JunctionNamedFacet::Parody, "comic_parodies", "parody_name"),
                (
                    JunctionNamedFacet::Character,
                    "comic_characters",
                    "character_name",
                ),
            ] {
                replace_comic_named_facet(&db, facet, "c-a", &["Alpha".to_string()])
                    .await
                    .unwrap_or_else(|_| panic!("replace {facet:?}"));
                assert_eq!(
                    junction_names(&db, table, col, "c-a").await,
                    vec!["Alpha".to_string()],
                    "{facet:?}"
                );
            }
        });
    });
}
