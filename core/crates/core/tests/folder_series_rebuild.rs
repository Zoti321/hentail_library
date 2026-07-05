use std::fs;
use std::path::{Path, PathBuf};

use hentai_core::sync::series_rebuild::rebuild_series_from_comics;
use hentai_core::{
    connection, init_db_at_path, update_series_user_meta, UpdateSeriesUserMetaDto,
};
use sea_orm::{ConnectionTrait, Database, DatabaseConnection, Statement};
use tempfile::TempDir;

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

async fn seed_minimal_comics(db: &DatabaseConnection) {
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series_items".to_string(),
    ))
    .await
    .expect("clear items");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM series".to_string(),
    ))
    .await
    .expect("clear series");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comic_meta".to_string(),
    ))
    .await
    .expect("clear meta");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "DELETE FROM comics".to_string(),
    ))
    .await
    .expect("clear comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1), \
                ('c2', 'E:/lib/Series/b.cbz', 'cbz', 1, 1, 1)"
            .to_string(),
    ))
    .await
    .expect("seed comics");
    db.execute(Statement::from_string(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
         VALUES ('c1', 'A', 'unknown', 1), ('c2', 'B', 'unknown', 1)"
            .to_string(),
    ))
    .await
    .expect("seed meta");
}

#[test]
fn rebuild_series_groups_comics_by_parent_folder() {
    let temp = TempDir::new().expect("tempdir");
    let db_path = create_fixture_db(temp.path());
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        let db = connection().expect("connection");
        seed_minimal_comics(&db).await;
        rebuild_series_from_comics(&db).await.expect("rebuild");

        let row = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT COUNT(*) FROM series".to_string(),
            ))
            .await
            .expect("count series")
            .expect("row");
        let series_count: i64 = row.try_get_by_index(0).expect("count");
        assert_eq!(series_count, 1);

        let items = db
            .query_all(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT sort_order FROM series_items ORDER BY sort_order".to_string(),
            ))
            .await
            .expect("items");
        assert_eq!(items.len(), 2);
    });
}

#[test]
fn update_series_user_meta_preserves_fields_on_rebuild() {
    let temp = TempDir::new().expect("tempdir");
    let db_path = create_fixture_db(temp.path());
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        let db = connection().expect("connection");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "DELETE FROM series_items; DELETE FROM series; DELETE FROM comic_meta; DELETE FROM comics"
                .to_string(),
        ))
        .await
        .expect("clear");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "INSERT INTO comics (comic_id, path, resource_type, resource_size, created_at, last_updated_at) \
             VALUES ('c1', 'E:/lib/Series/a.cbz', 'cbz', 1, 1, 1)"
                .to_string(),
        ))
        .await
        .expect("seed comic");
        db.execute(Statement::from_string(
            sea_orm::DatabaseBackend::Sqlite,
            "INSERT INTO comic_meta (comic_id, title, content_rating, page_count) \
             VALUES ('c1', 'A', 'unknown', 1)"
                .to_string(),
        ))
        .await
        .expect("seed meta");
        rebuild_series_from_comics(&db).await.expect("rebuild");

        let series_id: String = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT series_id FROM series LIMIT 1".to_string(),
            ))
            .await
            .expect("query")
            .expect("row")
            .try_get_by_index(0)
            .expect("id");

        update_series_user_meta(
            &series_id,
            UpdateSeriesUserMetaDto {
                name: Some("自定义系列名".to_string()),
                serialization_status: Some("ongoing".to_string()),
                total_count: Some(12),
                clear_total_count: false,
            },
        )
        .await
        .expect("update meta");

        rebuild_series_from_comics(&db).await.expect("rebuild again");

        let row = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                format!(
                    "SELECT name, serialization_status, total_count FROM series WHERE series_id = '{series_id}'"
                ),
            ))
            .await
            .expect("query")
            .expect("row");
        let name: String = row.try_get_by_index(0).expect("name");
        let status: String = row.try_get_by_index(1).expect("status");
        let total: Option<i32> = row.try_get_by_index(2).expect("total");
        assert_eq!(name, "自定义系列名");
        assert_eq!(status, "ongoing");
        assert_eq!(total, Some(12));
    });
}
