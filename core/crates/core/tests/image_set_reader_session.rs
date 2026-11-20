#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set Read session (#586): catalog order, start index, raw bytes, no Comic history.

mod common;

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use hentai_core::{
    connection, create_image_set_local_library, create_local_library, create_sync_handle,
    init_db_at_path, list_image_set_images, list_image_sets, load_image_set_page_bytes,
    open_image_set_reader, sync_library, HentaiError, HentaiErrorCode, SyncScanMode,
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
    fn new(db_name: &str) -> Self {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("pics");
        fs::create_dir_all(&root).expect("mkdir root");
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
        Self {
            _temp: temp,
            runtime,
            root,
            library_id,
        }
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

    fn set_id(&self, relative_path: &str) -> String {
        self.runtime.block_on(async {
            list_image_sets(&self.library_id)
                .await
                .expect("sets")
                .into_iter()
                .find(|set| set.relative_path == relative_path)
                .expect("set exists")
                .image_set_id
        })
    }

    fn open(
        &self,
        image_set_id: &str,
        start: usize,
    ) -> Result<hentai_core::ImageSetReaderSessionDto, HentaiError> {
        self.runtime
            .block_on(open_image_set_reader(&self.library_id, image_set_id, start))
    }

    fn load(&self, index: usize, image_set_id: &str) -> Result<Vec<u8>, HentaiError> {
        let images = self
            .runtime
            .block_on(list_image_set_images(&self.library_id, image_set_id))?;
        self.runtime
            .block_on(load_image_set_page_bytes(&self.library_id, &images[index]))
    }

    fn comic_history_rows(&self) -> i64 {
        self.runtime.block_on(async {
            let db = connection().expect("db");
            let row = db
                .query_one(Statement::from_string(
                    DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) AS c FROM comic_reading_histories".to_string(),
                ))
                .await
                .expect("query")
                .expect("row");
            row.try_get::<i64>("", "c").expect("count")
        })
    }
}

fn write_file(path: &Path, bytes: &[u8]) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    fs::write(path, bytes).expect("write file");
}

fn write_zip(path: &Path, entries: &[(&str, &[u8])]) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let file = fs::File::create(path).expect("create zip");
    let mut zip = zip::ZipWriter::new(file);
    let options =
        zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
    for (name, bytes) in entries {
        zip.start_file(*name, options).expect("start");
        zip.write_all(bytes).expect("write");
    }
    zip.finish().expect("finish");
}

#[test]
fn session_pages_follow_catalog_order_and_start_index() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reader_session_order.sqlite");
        // ADR-0062: first-level folder is the Image set; root loose files are ignored.
        write_file(&fixture.root.join("album/loose.jpg"), b"loose-bytes");
        write_zip(
            &fixture.root.join("album/pack.zip"),
            &[("002.png", b"zip-two"), ("001.png", b"zip-one")],
        );
        write_file(&fixture.root.join("ignored.jpg"), b"root-loose-ignored");
        fixture.sync();

        let set_id = fixture.set_id("album");
        let session = fixture.open(&set_id, 1).expect("open at index 1");
        let order: Vec<String> = session
            .pages
            .iter()
            .map(|p| format!("{}#{}", p.carrier_relative_path, p.member_path))
            .collect();
        assert_eq!(
            order,
            vec![
                "album/loose.jpg#",
                "album/pack.zip#001.png",
                "album/pack.zip#002.png"
            ]
        );
        assert_eq!(session.start_index, 1);
        assert!(fixture.open(&set_id, 3).is_err());
        assert!(fixture.open("missing-set", 0).is_err());
    });
}

#[test]
fn session_loads_raw_bytes_for_loose_and_archive_pages() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reader_session_bytes.sqlite");
        write_file(&fixture.root.join("album/loose.jpg"), b"loose-bytes");
        write_zip(
            &fixture.root.join("album/pack.zip"),
            &[("002.png", b"zip-two"), ("001.png", b"zip-one")],
        );
        fixture.sync();

        let set_id = fixture.set_id("album");
        assert_eq!(fixture.load(0, &set_id).unwrap(), b"loose-bytes");
        assert_eq!(fixture.load(1, &set_id).unwrap(), b"zip-one");
        assert_eq!(fixture.load(2, &set_id).unwrap(), b"zip-two");
    });
}

#[test]
fn session_never_writes_comic_reading_history() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reader_session_history.sqlite");
        write_file(&fixture.root.join("album/loose.jpg"), b"loose-bytes");
        fixture.sync();

        let set_id = fixture.set_id("album");
        let before = fixture.comic_history_rows();
        let session = fixture.open(&set_id, 0).expect("open");
        assert_eq!(session.pages.len(), 1);
        fixture.load(0, &set_id).expect("load");
        assert_eq!(fixture.comic_history_rows(), before);
    });
}

#[test]
fn session_rejects_carrier_paths_escaping_library_root() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reader_session_traversal.sqlite");
        write_file(&fixture.root.join("album/loose.jpg"), b"loose-bytes");
        fixture.sync();
        let forged = hentai_core::ImageSetImageDto {
            image_set_image_id: "forged".into(),
            image_set_id: fixture.set_id("album"),
            library_id: fixture.library_id.clone(),
            carrier_relative_path: "../outside.jpg".into(),
            member_path: String::new(),
            carrier_kind: "loose".into(),
            name: "outside.jpg".into(),
            excluded: false,
            width: None,
            height: None,
        };
        let result = fixture
            .runtime
            .block_on(load_image_set_page_bytes(&fixture.library_id, &forged));
        assert!(result.is_err());
    });
}

#[test]
fn page_read_rejects_an_image_from_another_library_before_reading_a_same_named_file() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reader_session_owner.sqlite");
        write_file(&fixture.root.join("album/loose.jpg"), b"selected-library");
        fixture.sync();
        let session = fixture.open(&fixture.set_id("album"), 0).expect("session");
        let other_root = fixture._temp.path().join("other-pics");
        write_file(&other_root.join("album/loose.jpg"), b"wrong-library");
        let other = fixture.runtime.block_on(async {
            create_image_set_local_library(&other_root.to_string_lossy(), Some("Other"))
                .await
                .expect("other library")
        });

        let result = fixture.runtime.block_on(load_image_set_page_bytes(
            &other.library_id,
            &session.pages[0],
        ));

        let error = result.expect_err("a page cannot be resolved against another library");
        assert_eq!(error.code, HentaiErrorCode::Validation);
        assert_eq!(
            fixture
                .load(0, &fixture.set_id("album"))
                .expect("original page"),
            b"selected-library"
        );
    });
}

#[test]
fn page_read_rejects_a_comic_library_even_when_the_carrier_exists() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reader_session_catalog_kind.sqlite");
        write_file(&fixture.root.join("album/loose.jpg"), b"selected-library");
        fixture.sync();
        let mut image = fixture
            .open(&fixture.set_id("album"), 0)
            .expect("session")
            .pages
            .remove(0);
        let comic_root = fixture._temp.path().join("comics");
        write_file(&comic_root.join("loose.jpg"), b"comic-library");
        let comic = fixture.runtime.block_on(async {
            create_local_library(&comic_root.to_string_lossy(), Some("Comics"))
                .await
                .expect("comic library")
        });
        image.library_id = comic.library_id.clone();

        let result = fixture
            .runtime
            .block_on(load_image_set_page_bytes(&comic.library_id, &image));

        let error = result.expect_err("Image set pages require an Image set library");
        assert_eq!(error.code, HentaiErrorCode::Validation);
    });
}
