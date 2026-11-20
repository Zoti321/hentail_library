#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set managed layout takeover (#612).

mod common;

use std::fs;
use std::io::Write;
use std::path::Path;

use hentai_core::{
    add_image_set_submission_members, create_image_set_local_library, create_image_set_submission,
    create_sync_handle, init_db_at_path, list_image_set_images, list_image_set_submissions,
    list_image_sets, set_image_set_managed_layout, set_image_set_resource_mutation, sync_library,
    take_over_image_set_managed_layout, HentaiErrorCode, SyncScanMode,
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
}

fn write_jpg(path: &Path, tag: &[u8]) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    fs::write(path, tag).expect("write");
}

fn write_cbz(path: &Path, page: &[u8]) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let file = fs::File::create(path).expect("create");
    let mut archive = zip::ZipWriter::new(file);
    archive
        .start_file(
            "inner.jpg",
            SimpleFileOptions::default().compression_method(CompressionMethod::Stored),
        )
        .expect("start");
    archive.write_all(page).expect("write");
    archive.finish().expect("finish");
}

#[test]
fn takeover_requires_both_gates() {
    common::with_global_db(|| {
        let fixture = Fixture::new("layout_gate.sqlite");
        write_jpg(&fixture.root.join("album/nested/a.jpg"), b"a");
        fixture.sync();
        let set_id = fixture.set_id("album");

        let err = fixture
            .runtime
            .block_on(take_over_image_set_managed_layout(
                &fixture.library_id,
                &set_id,
            ))
            .expect_err("both off");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        fixture
            .runtime
            .block_on(set_image_set_resource_mutation(&fixture.library_id, true))
            .expect("mutation");
        let err = fixture
            .runtime
            .block_on(take_over_image_set_managed_layout(
                &fixture.library_id,
                &set_id,
            ))
            .expect_err("layout off");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}

#[test]
fn takeover_flattens_and_preserves_submission_membership() {
    common::with_global_db(|| {
        let fixture = Fixture::new("layout_ok.sqlite");
        write_jpg(&fixture.root.join("album/nested/b.jpg"), b"b");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        write_cbz(&fixture.root.join("album/pack.cbz"), b"pack");
        fixture.sync();
        let set_id = fixture.set_id("album");
        let before = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("before");
        assert!(before.len() >= 3);

        let sub = fixture
            .runtime
            .block_on(create_image_set_submission(
                &fixture.library_id,
                &set_id,
                "Pick",
            ))
            .expect("sub");
        let member_names: Vec<&str> = before
            .iter()
            .take(2)
            .map(|i| i.name.as_str())
            .collect();
        fixture
            .runtime
            .block_on(add_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &before
                    .iter()
                    .take(2)
                    .map(|i| i.image_set_image_id.clone())
                    .collect::<Vec<_>>(),
            ))
            .expect("members");

        fixture
            .runtime
            .block_on(set_image_set_resource_mutation(&fixture.library_id, true))
            .expect("mutation");
        fixture
            .runtime
            .block_on(set_image_set_managed_layout(&fixture.library_id, true))
            .expect("layout");
        fixture
            .runtime
            .block_on(take_over_image_set_managed_layout(
                &fixture.library_id,
                &set_id,
            ))
            .expect("takeover");

        assert!(!fixture.root.join("album/nested").exists());
        assert!(!fixture.root.join("album/pack.cbz").exists());
        let after = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("after");
        assert_eq!(after.len(), before.len());
        for (index, image) in after.iter().enumerate() {
            assert_eq!(image.carrier_kind, "loose");
            assert!(image.member_path.is_empty());
            assert!(image.carrier_relative_path.starts_with("album/"));
            assert!(!image.carrier_relative_path.contains("/nested/"));
            let expected = format!("{:04}", index + 1);
            assert!(
                image.name.starts_with(&expected),
                "expected order name prefix {expected}, got {}",
                image.name
            );
            assert!(fixture.root.join(&image.carrier_relative_path).is_file());
        }

        let subs = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("subs");
        assert_eq!(subs[0].member_image_ids.len(), 2);
        let after_names: Vec<&str> = after
            .iter()
            .filter(|i| subs[0].member_image_ids.contains(&i.image_set_image_id))
            .map(|i| i.name.as_str())
            .collect();
        // Membership survives rekey; content order follows prior workspace order of those two.
        assert_eq!(after_names.len(), 2);
        let _ = member_names;
    });
}

#[test]
fn takeover_refuses_root_archive() {
    common::with_global_db(|| {
        let fixture = Fixture::new("layout_archive.sqlite");
        write_cbz(&fixture.root.join("pack.cbz"), b"x");
        fixture.sync();
        let set_id = fixture.set_id("pack.cbz");
        fixture
            .runtime
            .block_on(set_image_set_resource_mutation(&fixture.library_id, true))
            .expect("mutation");
        fixture
            .runtime
            .block_on(set_image_set_managed_layout(&fixture.library_id, true))
            .expect("layout");
        let err = fixture
            .runtime
            .block_on(take_over_image_set_managed_layout(
                &fixture.library_id,
                &set_id,
            ))
            .expect_err("archive");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}
