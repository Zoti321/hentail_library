use std::fs;
use std::path::{Path, PathBuf};

use hentai_core::{
    fetch_comics_page, find_comic_by_id, init_db_at_path, ComicFilterDto, ComicSortOptionDto,
    PageRequestDto,
};
use sea_orm::{ConnectionTrait, Database, Statement};
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

#[test]
fn drift_v2_fixture_comic_rows_preserved() {
    let temp = TempDir::new().expect("tempdir");
    let db_path = create_fixture_db(temp.path());
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        let comic = find_comic_by_id("86408880d30b0de95ca959feb60a3b72dcb1889b")
            .await
            .expect("find")
            .expect("row");
        assert_eq!(comic.comic_id, "86408880d30b0de95ca959feb60a3b72dcb1889b");
        assert_eq!(comic.title, "测试漫画");
        assert_eq!(comic.authors, vec!["作者A".to_string()]);
        assert_eq!(comic.tags, vec!["冒险".to_string()]);
    });
}

#[test]
fn fetch_comics_page_hides_r18_by_default() {
    let temp = TempDir::new().expect("tempdir");
    let db_path = create_fixture_db(temp.path());
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        let page = fetch_comics_page(
            PageRequestDto {
                page: 1,
                page_size: 50,
            },
            ComicFilterDto {
                show_r18: false,
                exclude_comics_in_any_series: false,
                ..Default::default()
            },
            ComicSortOptionDto { descending: false },
        )
        .await
        .expect("page");
        assert_eq!(page.total_count, 2);
        assert!(page.items.iter().all(|c| c.content_rating != "r18"));
    });
}

#[test]
fn fetch_comics_page_excludes_series_members() {
    let temp = TempDir::new().expect("tempdir");
    let db_path = create_fixture_db(temp.path());
    let runtime = tokio::runtime::Runtime::new().expect("runtime");
    runtime.block_on(async {
        init_db_at_path(&db_path).await.expect("init_db");
        let page = fetch_comics_page(
            PageRequestDto {
                page: 1,
                page_size: 50,
            },
            ComicFilterDto {
                show_r18: true,
                exclude_comics_in_any_series: true,
                ..Default::default()
            },
            ComicSortOptionDto { descending: false },
        )
        .await
        .expect("page");
        assert_eq!(page.total_count, 2);
        assert!(
            page.items
                .iter()
                .all(|c| c.comic_id != "af738b6b1b3bbfab9a0fd591459572509d7ef4d5")
        );
    });
}
