#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set workspace commands and library gates (#608 / #610).

mod common;

use std::fs;
use std::path::Path;

use hentai_core::{
    create_image_set_local_library, create_local_library, create_sync_handle,
    get_image_set_library_gates, init_db_at_path, list_image_set_images, list_image_sets,
    reorder_image_set_images, set_image_set_images_excluded, set_image_set_managed_layout,
    set_image_set_resource_mutation, sync_library, HentaiErrorCode, SyncScanMode,
};
use tempfile::TempDir;

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

    fn set_id(&self) -> String {
        self.runtime
            .block_on(list_image_sets(&self.library_id))
            .expect("sets")
            .into_iter()
            .find(|s| s.relative_path == "album")
            .expect("album")
            .image_set_id
    }
}

fn write_jpg(path: &Path, tag: &[u8]) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    fs::write(path, tag).expect("write");
}

#[test]
fn gates_default_off_and_toggle_on_local_image_set_library() {
    common::with_global_db(|| {
        let fixture = Fixture::new("gates.sqlite");
        let gates = fixture
            .runtime
            .block_on(get_image_set_library_gates(&fixture.library_id))
            .expect("get");
        assert!(!gates.resource_mutation);
        assert!(!gates.managed_layout);

        fixture
            .runtime
            .block_on(set_image_set_resource_mutation(&fixture.library_id, true))
            .expect("mutation on");
        fixture
            .runtime
            .block_on(set_image_set_managed_layout(&fixture.library_id, true))
            .expect("layout on");
        let gates = fixture
            .runtime
            .block_on(get_image_set_library_gates(&fixture.library_id))
            .expect("get");
        assert!(gates.resource_mutation);
        assert!(gates.managed_layout);

        fixture
            .runtime
            .block_on(set_image_set_resource_mutation(&fixture.library_id, false))
            .expect("mutation off");
        let gates = fixture
            .runtime
            .block_on(get_image_set_library_gates(&fixture.library_id))
            .expect("get");
        assert!(!gates.resource_mutation);
        assert!(gates.managed_layout);
    });
}

#[test]
fn gates_reject_comic_library() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("temp");
        let root = temp.path().join("comics");
        fs::create_dir_all(&root).expect("mkdir");
        let runtime = tokio::runtime::Runtime::new().expect("rt");
        let library_id = runtime.block_on(async {
            init_db_at_path(&temp.path().join("comic_gates.sqlite"))
                .await
                .expect("init");
            create_local_library(&root.to_string_lossy(), Some("Comics"))
                .await
                .expect("create")
                .library_id
        });
        let err = runtime
            .block_on(get_image_set_library_gates(&library_id))
            .expect_err("comic");
        assert_eq!(err.code, HentaiErrorCode::Validation);
        let err = runtime
            .block_on(set_image_set_resource_mutation(&library_id, true))
            .expect_err("comic set");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}

#[test]
fn exclude_and_include_update_default_list() {
    common::with_global_db(|| {
        let fixture = Fixture::new("exclude.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        write_jpg(&fixture.root.join("album/b.jpg"), b"b");
        write_jpg(&fixture.root.join("album/c.jpg"), b"c");
        fixture.sync();
        let set_id = fixture.set_id();
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(images.len(), 3);

        fixture
            .runtime
            .block_on(set_image_set_images_excluded(
                &fixture.library_id,
                &set_id,
                &[images[1].image_set_image_id.clone()],
                true,
            ))
            .expect("exclude");
        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(
            listed.iter().map(|i| i.name.as_str()).collect::<Vec<_>>(),
            vec!["a.jpg", "c.jpg"]
        );

        fixture
            .runtime
            .block_on(set_image_set_images_excluded(
                &fixture.library_id,
                &set_id,
                &[images[1].image_set_image_id.clone()],
                false,
            ))
            .expect("include");
        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(listed.len(), 3);
    });
}

#[test]
fn reorder_applies_authoritative_full_list() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reorder.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        write_jpg(&fixture.root.join("album/b.jpg"), b"b");
        write_jpg(&fixture.root.join("album/c.jpg"), b"c");
        fixture.sync();
        let set_id = fixture.set_id();
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        let reversed: Vec<String> = images
            .iter()
            .rev()
            .map(|i| i.image_set_image_id.clone())
            .collect();
        fixture
            .runtime
            .block_on(reorder_image_set_images(
                &fixture.library_id,
                &set_id,
                &reversed,
            ))
            .expect("reorder");
        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(
            listed.iter().map(|i| i.name.as_str()).collect::<Vec<_>>(),
            vec!["c.jpg", "b.jpg", "a.jpg"]
        );
    });
}

#[test]
fn reorder_rejects_partial_or_foreign_ids() {
    common::with_global_db(|| {
        let fixture = Fixture::new("reorder_bad.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        write_jpg(&fixture.root.join("album/b.jpg"), b"b");
        fixture.sync();
        let set_id = fixture.set_id();
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("list");

        let err = fixture
            .runtime
            .block_on(reorder_image_set_images(
                &fixture.library_id,
                &set_id,
                &[images[0].image_set_image_id.clone()],
            ))
            .expect_err("partial");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        let err = fixture
            .runtime
            .block_on(reorder_image_set_images(
                &fixture.library_id,
                &set_id,
                &[
                    images[0].image_set_image_id.clone(),
                    "not-an-image".into(),
                ],
            ))
            .expect_err("foreign");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        let err = fixture
            .runtime
            .block_on(set_image_set_images_excluded(
                &fixture.library_id,
                &set_id,
                &["ghost".into()],
                true,
            ))
            .expect_err("ghost");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}
