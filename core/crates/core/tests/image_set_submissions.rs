#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set submission CRUD and membership order (#609).

mod common;

use std::fs;
use std::path::Path;

use hentai_core::{
    add_image_set_submission_members, create_image_set_local_library, create_image_set_submission,
    create_sync_handle, delete_image_set_submission, init_db_at_path, list_image_set_images,
    list_image_set_submissions, list_image_sets, remove_image_set_submission_members,
    rename_image_set_submission, reorder_image_set_submission_members, sync_library,
    HentaiErrorCode, SyncScanMode,
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
fn create_submission_empty_name_assigns_default() {
    common::with_global_db(|| {
        let fixture = Fixture::new("sub_default_name.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        fixture.sync();
        let set_id = fixture.set_id();

        let created = fixture
            .runtime
            .block_on(create_image_set_submission(
                &fixture.library_id,
                &set_id,
                "   ",
            ))
            .expect("create");
        assert!(!created.name.is_empty());
        assert!(
            created.name.starts_with("投稿-"),
            "expected default prefix, got {}",
            created.name
        );

        let err = fixture
            .runtime
            .block_on(rename_image_set_submission(
                &fixture.library_id,
                &created.submission_id,
                "",
            ))
            .expect_err("rename empty");
        assert_eq!(err.code, HentaiErrorCode::Validation);
    });
}

#[test]
fn create_rename_delete_and_list_submissions() {
    common::with_global_db(|| {
        let fixture = Fixture::new("sub_crud.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        fixture.sync();
        let set_id = fixture.set_id();

        let created = fixture
            .runtime
            .block_on(create_image_set_submission(
                &fixture.library_id,
                &set_id,
                "Favs",
            ))
            .expect("create");
        assert_eq!(created.name, "Favs");
        assert!(created.member_image_ids.is_empty());

        fixture
            .runtime
            .block_on(rename_image_set_submission(
                &fixture.library_id,
                &created.submission_id,
                "Favorites",
            ))
            .expect("rename");
        let listed = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(listed.len(), 1);
        assert_eq!(listed[0].name, "Favorites");
        assert_eq!(listed[0].submission_id, created.submission_id);

        fixture
            .runtime
            .block_on(delete_image_set_submission(
                &fixture.library_id,
                &created.submission_id,
            ))
            .expect("delete");
        let listed = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("list");
        assert!(listed.is_empty());
    });
}

#[test]
fn membership_add_remove_reorder_and_reject_foreign_or_duplicate() {
    common::with_global_db(|| {
        let fixture = Fixture::new("sub_members.sqlite");
        write_jpg(&fixture.root.join("album/a.jpg"), b"a");
        write_jpg(&fixture.root.join("album/b.jpg"), b"b");
        write_jpg(&fixture.root.join("album/c.jpg"), b"c");
        fixture.sync();
        let set_id = fixture.set_id();
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("images");
        let a = images[0].image_set_image_id.clone();
        let b = images[1].image_set_image_id.clone();
        let c = images[2].image_set_image_id.clone();

        let sub = fixture
            .runtime
            .block_on(create_image_set_submission(
                &fixture.library_id,
                &set_id,
                "Pick",
            ))
            .expect("create");

        fixture
            .runtime
            .block_on(add_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &[a.clone(), c.clone()],
            ))
            .expect("add");
        let listed = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(listed[0].member_image_ids, vec![a.clone(), c.clone()]);

        let err = fixture
            .runtime
            .block_on(add_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &[a.clone()],
            ))
            .expect_err("duplicate");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        let err = fixture
            .runtime
            .block_on(add_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &["ghost".into()],
            ))
            .expect_err("foreign");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        fixture
            .runtime
            .block_on(reorder_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &[c.clone(), a.clone()],
            ))
            .expect("reorder");
        let listed = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(listed[0].member_image_ids, vec![c.clone(), a.clone()]);

        let err = fixture
            .runtime
            .block_on(reorder_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &[c.clone(), a.clone(), b.clone()],
            ))
            .expect_err("extra");
        assert_eq!(err.code, HentaiErrorCode::Validation);

        fixture
            .runtime
            .block_on(remove_image_set_submission_members(
                &fixture.library_id,
                &sub.submission_id,
                &[c.clone()],
            ))
            .expect("remove");
        let listed = fixture
            .runtime
            .block_on(list_image_set_submissions(&fixture.library_id, &set_id))
            .expect("list");
        assert_eq!(listed[0].member_image_ids, vec![a]);
    });
}
