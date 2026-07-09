use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::sync::Mutex;

use hentai_core::comic::ComicDto;
use hentai_core::sync::parser::{parse_epub, parsed_to_comic};
use hentai_core::sync::plan::build_scan_replace_plan;
use hentai_core::sync::scanner::ScanItem;
use hentai_core::sync::writer::apply_scan_replace_plan;
use hentai_core::{connection, init_db_at_path};
use sea_orm::{ConnectionTrait, Database, Statement};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .expect("global db tests must run serially");
    test();
}

fn fixture_sql() -> String {
    fs::read_to_string(std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(
        "../../tests/fixtures/drift_v2.sql",
    ))
    .expect("read drift_v2.sql")
}

fn create_fixture_db(dir: &Path) -> std::path::PathBuf {
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

fn create_epub(path: &Path, author: &str) {
    let file = File::create(path).expect("create epub");
    let mut zip = ZipWriter::new(file);
    let options = SimpleFileOptions::default();

    zip.start_file("META-INF/container.xml", options)
        .expect("container");
    zip.write_all(
        br#"<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>"#,
    )
    .expect("write container");

    zip.start_file("OEBPS/content.opf", options).expect("opf");
    let opf = format!(
        r#"<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>测试漫画</dc:title>
    <dc:creator>{author}</dc:creator>
  </metadata>
</package>"#
    );
    zip.write_all(opf.as_bytes()).expect("write opf");

    zip.start_file("OEBPS/page01.jpg", options).expect("page");
    zip.write_all(b"fake-jpeg").expect("write page");
    zip.finish().expect("finish");
}

#[test]
fn parse_epub_reads_author_metadata() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("comic.epub");
    create_epub(&path, "测试作者");

    let parsed = parse_epub(&path).expect("parse").expect("resource");
    assert_eq!(parsed.resource_type, "epub");
    assert_eq!(parsed.authors, vec!["测试作者".to_string()]);
    assert_eq!(parsed.page_count, 1);
}

#[test]
fn upsert_epub_author_twice_does_not_fail_when_author_exists() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");

            let epub_path = temp.path().join("comic.epub");
            create_epub(&epub_path, "作者A");
            let parsed = parse_epub(&epub_path).expect("parse").expect("resource");
            let comic: ComicDto = parsed_to_comic(&parsed);
            let make_item = || ScanItem {
                path: parsed.path.clone(),
                resource_type: parsed.resource_type.clone(),
                comic: comic.clone(),
            };

            let plan = build_scan_replace_plan(&db, vec![make_item()])
                .await
                .expect("build plan");
            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("first sync");
            let plan = build_scan_replace_plan(&db, vec![make_item()])
                .await
                .expect("build plan again");
            apply_scan_replace_plan(&db, &plan)
                .await
                .expect("rescan epub with existing author should not fail");
        });
    });
}
