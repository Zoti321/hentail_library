//! Image set discovery, persistence and manual sync (#584).

mod common;

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use hentai_core::{
    cancel_sync, connection, create_image_set_local_library, create_sync_handle, delete_library,
    init_db_at_path, list_image_set_images, list_image_sets, sync_library, HentaiError, SyncHandle,
    SyncLibraryProgressDto, SyncScanMode,
};
use sea_orm::{ConnectionTrait, DatabaseBackend, Statement};
use tempfile::TempDir;

struct Fixture {
    temp: TempDir,
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
            temp,
            runtime,
            root,
            library_id,
        }
    }

    fn outside(&self) -> PathBuf {
        self.temp.path().join("outside")
    }

    fn sync_with(&self, handle: SyncHandle) -> Result<Vec<SyncLibraryProgressDto>, HentaiError> {
        let mut events = Vec::new();
        self.runtime.block_on(sync_library(
            handle,
            SyncScanMode::Full,
            false,
            Some(self.library_id.as_str()),
            vec![],
            |progress| events.push(progress),
        ))?;
        Ok(events)
    }

    fn sync(&self) -> Vec<SyncLibraryProgressDto> {
        self.sync_with(create_sync_handle()).expect("sync")
    }

    fn catalog(&self) -> Vec<String> {
        self.runtime.block_on(async {
            let mut lines = Vec::new();
            for set in list_image_sets(&self.library_id).await.expect("sets") {
                lines.push(format!("set {:?}", set.relative_path));
                let images = list_image_set_images(&self.library_id, &set.image_set_id)
                    .await
                    .expect("images");
                for image in images {
                    lines.push(format!(
                        "img {} # {} {}",
                        image.carrier_relative_path, image.member_path, image.carrier_kind
                    ));
                }
            }
            lines
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

fn last_warning(events: &[SyncLibraryProgressDto]) -> Option<String> {
    events.last().and_then(|event| event.error_message.clone())
}

fn layout_folder_and_root(root: &Path) {
    write_file(&root.join("rootonly.jpg"), b"img");
    write_file(&root.join("doc.pdf"), b"pdf");
    write_file(&root.join("album1/01.jpg"), b"img");
    write_file(&root.join("album1/nested/02.png"), b"img");
    write_file(&root.join("album2/x.webp"), b"img");
    write_file(&root.join("empty/readme.txt"), b"text");
}

#[test]
fn folder_and_root_discover_sets_with_nested_flattened() {
    common::with_global_db(|| {
        let fixture = Fixture::new("folder_root.sqlite");
        layout_folder_and_root(&fixture.root);

        fixture.sync();

        // Library-root loose images are ignored; empty first-level dirs are not sets.
        assert_eq!(
            fixture.catalog(),
            vec![
                "set \"album1\"",
                "img album1/01.jpg #  loose",
                "img album1/nested/02.png #  loose",
                "set \"album2\"",
                "img album2/x.webp #  loose",
            ]
        );
    });
}

#[test]
fn zip_and_root_archives_discover_members_by_entry_path() {
    common::with_global_db(|| {
        let fixture = Fixture::new("zip.sqlite");
        common::write_cbz(&fixture.root.join("album3/pack.cbz"), 2);
        write_zip(
            &fixture.root.join("album3/nested/deep.zip"),
            &[("a/001.png", b"img"), ("readme.txt", b"text")],
        );
        common::write_cbz(&fixture.root.join("root.zip"), 1);

        fixture.sync();

        assert_eq!(
            fixture.catalog(),
            vec![
                "set \"album3\"",
                "img album3/nested/deep.zip # a/001.png zip",
                "img album3/pack.cbz # 000.jpg zip",
                "img album3/pack.cbz # 001.jpg zip",
                "set \"root.zip\"",
                "img root.zip # 000.jpg zip",
            ]
        );
    });
}

#[test]
fn empty_root_archive_and_empty_folder_are_not_image_sets() {
    common::with_global_db(|| {
        let fixture = Fixture::new("empty_carriers.sqlite");
        write_zip(&fixture.root.join("empty.zip"), &[("readme.txt", b"text")]);
        write_file(&fixture.root.join("empty_dir/readme.txt"), b"text");
        write_file(&fixture.root.join("ignored.jpg"), b"img");

        fixture.sync();

        assert!(fixture.catalog().is_empty());
    });
}

#[test]
fn unchanged_archive_keeps_members_across_resync() {
    common::with_global_db(|| {
        let fixture = Fixture::new("unchanged_zip.sqlite");
        common::write_cbz(&fixture.root.join("album3/pack.cbz"), 2);
        fixture.sync();
        let before = fixture.catalog();

        let events = fixture.sync();

        assert_eq!(fixture.catalog(), before);
        assert_eq!(last_warning(&events), None);
    });
}

#[test]
fn removed_loose_image_disappears_on_next_sync() {
    common::with_global_db(|| {
        let fixture = Fixture::new("remove_loose.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();

        fs::remove_file(fixture.root.join("album1/01.jpg")).expect("remove loose");
        fixture.sync();

        assert_eq!(
            fixture.catalog(),
            vec![
                "set \"album1\"",
                "img album1/nested/02.png #  loose",
                "set \"album2\"",
                "img album2/x.webp #  loose",
            ]
        );
    });
}

#[test]
fn unlistable_archive_keeps_prior_images_and_warns() {
    common::with_global_db(|| {
        let fixture = Fixture::new("bad_zip.sqlite");
        let archive = fixture.root.join("album3/pack.cbz");
        common::write_cbz(&archive, 2);
        fixture.sync();
        let before = fixture.catalog();

        write_file(&archive, b"not a zip archive, size differs");
        let events = fixture.sync();

        assert_eq!(fixture.catalog(), before);
        assert!(
            last_warning(&events)
                .expect("warning on success")
                .contains("无法列出"),
            "warning should name the unlistable archive"
        );
    });
}

#[test]
fn missing_first_level_folder_removes_its_set() {
    common::with_global_db(|| {
        let fixture = Fixture::new("missing_folder.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();

        fs::rename(fixture.root.join("album2"), fixture.outside()).expect("move album2 out");
        fixture.sync();

        assert_eq!(
            fixture.catalog(),
            vec![
                "set \"album1\"",
                "img album1/01.jpg #  loose",
                "img album1/nested/02.png #  loose",
            ]
        );
    });
}

#[test]
fn inaccessible_root_preserves_catalog_and_warns() {
    common::with_global_db(|| {
        let fixture = Fixture::new("inaccessible_root.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();
        let before = fixture.catalog();

        let away = fixture.temp.path().join("pics_away");
        fs::rename(&fixture.root, &away).expect("hide root");
        let events = fixture.sync();
        fs::rename(&away, &fixture.root).expect("restore root");

        assert_eq!(fixture.catalog(), before);
        assert!(last_warning(&events)
            .expect("warning")
            .contains("已跳过不可读的图集库"),);
    });
}

#[test]
fn cancelled_sync_writes_nothing_and_next_sync_converges() {
    common::with_global_db(|| {
        let fixture = Fixture::new("cancelled.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();
        let before = fixture.catalog();

        write_file(&fixture.root.join("album4/new.jpg"), b"img");
        let handle = create_sync_handle();
        cancel_sync(&handle);
        fixture
            .sync_with(handle)
            .expect("cancelled sync is not an error");
        assert_eq!(fixture.catalog(), before);

        fixture.sync();
        assert!(fixture
            .catalog()
            .contains(&"img album4/new.jpg #  loose".to_string()));
    });
}

#[test]
fn failed_catalog_write_rolls_back_and_retry_converges() {
    common::with_global_db(|| {
        let fixture = Fixture::new("rollback.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();
        let before = fixture.catalog();

        write_file(&fixture.root.join("album5/new.jpg"), b"img");
        let db = connection().expect("db");
        fixture.runtime.block_on(async {
            db.execute(Statement::from_string(
                DatabaseBackend::Sqlite,
                "CREATE TRIGGER fail_image_set_images BEFORE INSERT ON image_set_images \
                 BEGIN SELECT RAISE(ABORT, 'injected image set failure'); END"
                    .to_string(),
            ))
            .await
            .expect("trigger");
        });
        assert!(fixture.sync_with(create_sync_handle()).is_err());
        assert_eq!(fixture.catalog(), before);

        fixture.runtime.block_on(async {
            db.execute(Statement::from_string(
                DatabaseBackend::Sqlite,
                "DROP TRIGGER fail_image_set_images".to_string(),
            ))
            .await
            .expect("drop trigger");
        });
        fixture.sync();
        assert!(fixture
            .catalog()
            .contains(&"img album5/new.jpg #  loose".to_string()));
    });
}

#[test]
fn deleting_library_cascades_image_set_catalog() {
    common::with_global_db(|| {
        let fixture = Fixture::new("delete_cascade.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();
        assert!(!fixture.catalog().is_empty());

        fixture
            .runtime
            .block_on(delete_library(&fixture.library_id))
            .expect("delete");

        assert!(fixture.catalog().is_empty());
    });
}
