#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set directory copy-in / delete-on-disk (#611).

mod common;

use std::fs;
use std::io::Write;
use std::path::Path;

use hentai_core::{
    add_image_set_submission_members, copy_images_into_image_set, create_image_set_local_library,
    create_image_set_submission, create_sync_handle, delete_image_set_images_on_disk,
    get_image_set_library_gates, init_db_at_path, list_image_set_images, list_image_set_submissions,
    list_image_sets, set_image_set_resource_mutation, sync_library, HentaiErrorCode, SyncScanMode,
};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::CompressionMethod;

struct Fixture {
    _temp: TempDir,
    runtime: tokio::runtime::Runtime,
    root: std::path::PathBuf,
    library_id: String,
}

impl Fixture {
    fn new(db_name: &str) -> Self {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("pics");
        fs::create_dir_all(&root).expect("mkdir");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        let library_id = runtime.block_on(async {
            init_db_at_path(&temp.path().join(db_name))
                .await
                .expect("init");
            create_image_set_local_library(&root.to_string_lossy(), Some("Pics"))
                .await
                .expect("create")
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
        self.runtime
            .block_on(list_image_sets(&self.library_id))
            .expect("sets")
            .into_iter()
            .find(|s| s.relative_path == relative_path)
            .unwrap_or_else(|| panic!("set {relative_path}"))
            .image_set_id
    }

    fn enable_mutation(&self) {
        self.runtime
            .block_on(set_image_set_resource_mutation(&self.library_id, true))
            .expect("mutation on");
    }
}

fn write_jpg(path: &Path, tag: &[u8]) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    fs::write(path, tag).expect("write");
}

fn write_cbz(path: &Path) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let file = fs::File::create(path).expect("create");
    let mut archive = zip::ZipWriter::new(file);
    archive
        .start_file(
            "001.jpg",
            SimpleFileOptions::default().compression_method(CompressionMethod::Stored),
        )
        .expect("start");
    archive.write_all(b"page").expect("write");
    archive.finish().expect("finish");
}

#[test]
fn copy_in_and_delete_require_mutation_gate() {
    common::with_global_db(|| {
        let fixture = Fixture::new("mut_gate.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        fixture.sync();
        let set_id = fixture.set_id("album");
        let gates = fixture
            .runtime
            .block_on(get_image_set_library_gates(&fixture.library_id))
            .expect("gates");
        assert!(!gates.resource_mutation);

        let source = fixture._temp.path().join("outside.jpg");
        write_jpg(&source, b"out");
        let err = fixture
            .runtime
            .block_on(copy_images_into_image_set(
                &fixture.library_id,
                &set_id,
                &[source.to_string_lossy().into_owned()],
            ))
            .expect_err("gate");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        let err = fixture
            .runtime
            .block_on(delete_image_set_images_on_disk(
                &fixture.library_id,
                &set_id,
                &[images[0].image_set_image_id.clone()],
            ))
            .expect_err("gate");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}

#[test]
fn copy_in_appends_catalog_and_delete_removes_file() {
    common::with_global_db(|| {
        let fixture = Fixture::new("mut_copy.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        fixture.sync();
        let set_id = fixture.set_id("album");
        fixture.enable_mutation();

        let source = fixture._temp.path().join("import.jpg");
        write_jpg(&source, b"import");
        let added = fixture
            .runtime
            .block_on(copy_images_into_image_set(
                &fixture.library_id,
                &set_id,
                &[source.to_string_lossy().into_owned()],
            ))
            .expect("copy");
        assert_eq!(added.len(), 1);
        assert_eq!(added[0].name, "import.jpg");
        assert!(fixture.root.join("album/import.jpg").is_file());

        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(
            listed.iter().map(|i| i.name.as_str()).collect::<Vec<_>>(),
            vec!["a.jpg", "import.jpg"]
        );

        let sub = fixture
            .runtime
            .block_on(create_image_set_submission(
                &fixture.library_id,
                &set_id,
                "Keep",
            ))
            .expect("sub");
        fixture
            .runtime
            .block_on(add_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &[added[0].image_set_image_id.clone()],
            ))
            .expect("member");

        fixture
            .runtime
            .block_on(delete_image_set_images_on_disk(
                &fixture.library_id,
                &set_id,
                &[added[0].image_set_image_id.clone()],
            ))
            .expect("delete");
        assert!(!fixture.root.join("album/import.jpg").exists());
        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(
            listed.iter().map(|i| i.name.as_str()).collect::<Vec<_>>(),
            vec!["a.jpg"]
        );
        let subs = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("subs");
        assert!(subs[0].member_image_ids.is_empty());
    });
}

#[test]
fn mutation_refuses_root_archive_sets() {
    common::with_global_db(|| {
        let fixture = Fixture::new("mut_archive.sqlite");
        write_cbz(&fixture.root.join("pack.cbz"));
        fixture.sync();
        let set_id = fixture.set_id("pack.cbz");
        fixture.enable_mutation();

        let source = fixture._temp.path().join("extra.jpg");
        write_jpg(&source, b"x");
        let err = fixture
            .runtime
            .block_on(copy_images_into_image_set(
                &fixture.library_id,
                &set_id,
                &[source.to_string_lossy().into_owned()],
            ))
            .expect_err("archive");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        let err = fixture
            .runtime
            .block_on(delete_image_set_images_on_disk(
                &fixture.library_id,
                &set_id,
                &[images[0].image_set_image_id.clone()],
            ))
            .expect_err("archive delete");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}
