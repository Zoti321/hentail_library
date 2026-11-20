#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

//! Image set discovery, persistence and manual sync (#584).

mod common;

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use hentai_core::{
    cancel_sync, connection, create_image_set_local_library, create_sync_handle, delete_library,
    init_db_at_path, list_image_set_images, list_image_sets, set_image_set_meta_locks,
    sync_library, update_image_set_user_meta, HentaiError, ImageSetDto, SetImageSetMetaLocksDto,
    SyncHandle, SyncLibraryProgressDto, SyncScanMode, UpdateImageSetUserMetaDto,
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

    fn set(&self, relative_path: &str) -> ImageSetDto {
        self.runtime
            .block_on(list_image_sets(&self.library_id))
            .expect("sets")
            .into_iter()
            .find(|set| set.relative_path == relative_path)
            .expect("set present")
    }

    fn rename(&self, relative_path: &str, name: &str) -> Result<(), HentaiError> {
        let id = self.set(relative_path).image_set_id;
        self.runtime.block_on(update_image_set_user_meta(
            &id,
            UpdateImageSetUserMetaDto {
                name: Some(name.to_string()),
            },
        ))
    }

    fn set_name_lock(&self, relative_path: &str, locked: bool) {
        let id = self.set(relative_path).image_set_id;
        self.runtime
            .block_on(set_image_set_meta_locks(
                &id,
                SetImageSetMetaLocksDto { name: Some(locked) },
            ))
            .expect("set lock");
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

        assert_eq!(fixture.catalog().len(), 0);
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
fn new_image_sets_take_basename_unlocked() {
    common::with_global_db(|| {
        let fixture = Fixture::new("name_new.sqlite");
        layout_folder_and_root(&fixture.root);
        common::write_cbz(&fixture.root.join("root.zip"), 1);
        fixture.sync();

        let album = fixture.set("album1");
        assert_eq!(album.name, "album1");
        assert!(!album.name_locked);
        assert_eq!(fixture.set("root.zip").name, "root.zip");
    });
}

#[test]
fn user_name_write_auto_locks_and_survives_sync() {
    common::with_global_db(|| {
        let fixture = Fixture::new("name_locked.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();

        fixture.rename("album1", "  我的图集  ").expect("rename");
        let renamed = fixture.set("album1");
        assert_eq!(renamed.name, "我的图集");
        assert!(renamed.name_locked);

        fixture.sync();
        let after = fixture.set("album1");
        assert_eq!(after.name, "我的图集");
        assert!(after.name_locked);
    });
}

#[test]
fn unlock_alone_keeps_name_until_next_sync_overwrites_with_basename() {
    common::with_global_db(|| {
        let fixture = Fixture::new("name_unlock.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();
        fixture.rename("album1", "我的图集").expect("rename");

        fixture.set_name_lock("album1", false);
        let unlocked = fixture.set("album1");
        assert_eq!(unlocked.name, "我的图集");
        assert!(!unlocked.name_locked);

        fixture.sync();
        assert_eq!(fixture.set("album1").name, "album1");
    });
}

#[test]
fn blank_user_name_is_rejected() {
    common::with_global_db(|| {
        let fixture = Fixture::new("name_blank.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();

        assert!(fixture.rename("album1", "   ").is_err());
        let album = fixture.set("album1");
        assert_eq!(album.name, "album1");
        assert!(!album.name_locked);
    });
}

#[test]
fn deleting_library_cascades_image_set_catalog() {
    common::with_global_db(|| {
        let fixture = Fixture::new("delete_cascade.sqlite");
        layout_folder_and_root(&fixture.root);
        fixture.sync();
        assert_ne!(fixture.catalog().len(), 0);

        fixture
            .runtime
            .block_on(delete_library(&fixture.library_id))
            .expect("delete");

        assert_eq!(fixture.catalog().len(), 0);
    });
}

#[test]
fn workspace_list_honors_user_order_and_skips_excluded() {
    common::with_global_db(|| {
        let fixture = Fixture::new("workspace_order.sqlite");
        write_file(&fixture.root.join("album/a.jpg"), b"a");
        write_file(&fixture.root.join("album/b.jpg"), b"b");
        write_file(&fixture.root.join("album/c.jpg"), b"c");
        fixture.sync();
        let set = fixture.set("album");
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        assert_eq!(
            images
                .iter()
                .map(|i| i.name.as_str())
                .collect::<Vec<_>>(),
            vec!["a.jpg", "b.jpg", "c.jpg"]
        );

        fixture.runtime.block_on(async {
            let db = connection().expect("db");
            db.execute(Statement::from_string(
                DatabaseBackend::Sqlite,
                format!(
                    "UPDATE image_set_images SET sort_order = 2 WHERE image_set_image_id = '{}';
                     UPDATE image_set_images SET sort_order = 0 WHERE image_set_image_id = '{}';
                     UPDATE image_set_images SET sort_order = 1, excluded = 1 WHERE image_set_image_id = '{}';",
                    images[0].image_set_image_id,
                    images[2].image_set_image_id,
                    images[1].image_set_image_id,
                ),
            ))
            .await
            .expect("reorder+exclude");
        });

        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        assert_eq!(
            listed
                .iter()
                .map(|i| i.name.as_str())
                .collect::<Vec<_>>(),
            vec!["c.jpg", "a.jpg"]
        );
    });
}

#[test]
fn multi_carrier_default_order_groups_by_carrier_then_member_natural() {
    common::with_global_db(|| {
        let fixture = Fixture::new("multi_carrier_order.sqlite");
        // Basenames alone would order a.jpg before mid.jpg before z.jpg and shred carriers.
        write_zip(
            &fixture.root.join("album/early.zip"),
            &[("z.jpg", b"z"), ("a.jpg", b"a")],
        );
        write_zip(
            &fixture.root.join("album/late.zip"),
            &[("m.jpg", b"m")],
        );
        write_file(&fixture.root.join("album/mid.jpg"), b"mid");
        fixture.sync();
        let set = fixture.set("album");
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        let keys: Vec<(String, String, String)> = images
            .iter()
            .map(|i| {
                (
                    i.carrier_relative_path.clone(),
                    i.member_path.clone(),
                    i.name.clone(),
                )
            })
            .collect();
        assert_eq!(
            keys,
            vec![
                (
                    "album/early.zip".into(),
                    "a.jpg".into(),
                    "a.jpg".into(),
                ),
                (
                    "album/early.zip".into(),
                    "z.jpg".into(),
                    "z.jpg".into(),
                ),
                (
                    "album/late.zip".into(),
                    "m.jpg".into(),
                    "m.jpg".into(),
                ),
                ("album/mid.jpg".into(), String::new(), "mid.jpg".into()),
            ]
        );

        // Resync must not rewrite existing workspace order.
        fixture.runtime.block_on(async {
            let db = connection().expect("db");
            db.execute(Statement::from_string(
                DatabaseBackend::Sqlite,
                format!(
                    "UPDATE image_set_images SET sort_order = 90 WHERE image_set_image_id = '{}';
                     UPDATE image_set_images SET sort_order = 10 WHERE image_set_image_id = '{}';",
                    images[0].image_set_image_id,
                    images[3].image_set_image_id,
                ),
            ))
            .await
            .expect("bump orders");
        });
        fixture.sync();
        let after = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        assert_eq!(
            after
                .iter()
                .map(|i| i.name.as_str())
                .collect::<Vec<_>>(),
            vec!["z.jpg", "m.jpg", "mid.jpg", "a.jpg"]
        );
    });
}

#[test]
fn sync_preserves_exclude_and_appends_new_images_after_user_order() {
    common::with_global_db(|| {
        let fixture = Fixture::new("workspace_sync.sqlite");
        write_file(&fixture.root.join("album/a.jpg"), b"a");
        write_file(&fixture.root.join("album/b.jpg"), b"b");
        fixture.sync();
        let set = fixture.set("album");
        let before = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        assert_eq!(before.len(), 2);

        fixture.runtime.block_on(async {
            let db = connection().expect("db");
            db.execute(Statement::from_string(
                DatabaseBackend::Sqlite,
                format!(
                    "UPDATE image_set_images SET excluded = 1 WHERE image_set_image_id = '{}';
                     UPDATE image_set_images SET sort_order = 5 WHERE image_set_image_id = '{}';
                     UPDATE image_set_images SET sort_order = 1 WHERE image_set_image_id = '{}';",
                    before[0].image_set_image_id,
                    before[1].image_set_image_id,
                    before[0].image_set_image_id,
                ),
            ))
            .await
            .expect("mutate workspace");
        });

        write_file(&fixture.root.join("album/c.jpg"), b"c");
        fixture.sync();

        let listed = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        assert_eq!(
            listed
                .iter()
                .map(|i| i.name.as_str())
                .collect::<Vec<_>>(),
            vec!["b.jpg", "c.jpg"]
        );

        fixture.runtime.block_on(async {
            let db = connection().expect("db");
            let rows = db
                .query_all(Statement::from_string(
                    DatabaseBackend::Sqlite,
                    format!(
                        "SELECT name, sort_order, excluded FROM image_set_images \
                         WHERE image_set_id = '{}' ORDER BY sort_order, name",
                        set.image_set_id
                    ),
                ))
                .await
                .expect("query");
            let snapshot: Vec<(String, i64, i64)> = rows
                .iter()
                .map(|row| {
                    (
                        row.try_get::<String>("", "name").expect("name"),
                        row.try_get::<i64>("", "sort_order").expect("order"),
                        row.try_get::<i64>("", "excluded").expect("excluded"),
                    )
                })
                .collect();
            assert_eq!(
                snapshot,
                vec![
                    ("a.jpg".into(), 1, 1),
                    ("b.jpg".into(), 5, 0),
                    ("c.jpg".into(), 6, 0),
                ]
            );
        });
    });
}

#[test]
fn workspace_schema_has_submissions_and_library_gates() {
    common::with_global_db(|| {
        let fixture = Fixture::new("workspace_schema.sqlite");
        fixture.runtime.block_on(async {
            let db = connection().expect("db");
            for table in [
                "image_set_submissions",
                "image_set_submission_members",
            ] {
                let rows = db
                    .query_all(Statement::from_string(
                        DatabaseBackend::Sqlite,
                        format!(
                            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}'"
                        ),
                    ))
                    .await
                    .expect("master");
                assert!(!rows.is_empty(), "missing {table}");
            }
            let row = db
                .query_one(Statement::from_string(
                    DatabaseBackend::Sqlite,
                    format!(
                        "SELECT image_set_resource_mutation, image_set_managed_layout \
                         FROM libraries WHERE library_id = '{}'",
                        fixture.library_id
                    ),
                ))
                .await
                .expect("query")
                .expect("library row");
            assert_eq!(
                row.try_get::<i64>("", "image_set_resource_mutation")
                    .expect("mutation"),
                0
            );
            assert_eq!(
                row.try_get::<i64>("", "image_set_managed_layout")
                    .expect("layout"),
                0
            );
        });
    });
}

fn png_bytes(width: u32, height: u32) -> Vec<u8> {
    use image::{ImageBuffer, Rgb};
    use std::io::Cursor;
    let img: ImageBuffer<Rgb<u8>, Vec<u8>> =
        ImageBuffer::from_pixel(width, height, Rgb([0, 0, 0]));
    let mut out = Vec::new();
    img.write_to(&mut Cursor::new(&mut out), image::ImageFormat::Png)
        .expect("encode png");
    out
}

#[test]
fn sync_persists_image_dimensions_for_valid_png_and_leaves_junk_null() {
    common::with_global_db(|| {
        let fixture = Fixture::new("image_dims.sqlite");
        write_file(&fixture.root.join("album/wide.png"), &png_bytes(200, 100));
        write_file(&fixture.root.join("album/junk.jpg"), b"not-an-image");
        fixture.sync();
        let set = fixture.set("album");
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set.image_set_id))
            .expect("images");
        assert_eq!(images.len(), 2);
        let wide = images
            .iter()
            .find(|image| image.name == "wide.png")
            .expect("wide");
        assert_eq!(wide.width, Some(200));
        assert_eq!(wide.height, Some(100));
        let junk = images
            .iter()
            .find(|image| image.name == "junk.jpg")
            .expect("junk");
        assert_eq!(junk.width, None);
        assert_eq!(junk.height, None);
    });
}
