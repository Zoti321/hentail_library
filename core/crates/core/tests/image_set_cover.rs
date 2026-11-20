#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::fs;
use std::path::{Path, PathBuf};

use hentai_core::{
    create_image_set_local_library, create_sync_handle, find_image_set_cover, init_db_at_path,
    invalidate_image_set_cover, list_image_set_images, list_image_sets, reorder_image_set_images,
    store_image_set_cover, sync_library, SyncScanMode,
};
use image::{ImageBuffer, Rgb};
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
}

fn write_solid_jpeg(path: &Path, r: u8, g: u8, b: u8) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    let img: ImageBuffer<Rgb<u8>, Vec<u8>> = ImageBuffer::from_pixel(64, 64, Rgb([r, g, b]));
    img.save(path).expect("write jpeg");
}

#[test]
fn store_cover_from_first_workspace_image() {
    common::with_global_db(|| {
        let fixture = Fixture::new("image_set_cover_store.sqlite");
        write_solid_jpeg(&fixture.root.join("album/a.jpg"), 10, 20, 30);
        write_solid_jpeg(&fixture.root.join("album/b.jpg"), 200, 100, 50);
        fixture.sync();
        let set_id = fixture.set_id("album");

        let jpeg = fixture
            .runtime
            .block_on(store_image_set_cover(&fixture.library_id, &set_id))
            .expect("store")
            .expect("jpeg");
        assert!(!jpeg.is_empty());
        assert_eq!(jpeg[0..2], [0xFF, 0xD8], "JPEG SOI");

        let found = fixture
            .runtime
            .block_on(find_image_set_cover(&set_id))
            .expect("find")
            .expect("row");
        assert_eq!(found.thumbnail, jpeg);

        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("images");
        assert_eq!(found.source_image_set_image_id, images[0].image_set_image_id);
    });
}

#[test]
fn reorder_invalidates_cover_so_new_first_image_is_used() {
    common::with_global_db(|| {
        let fixture = Fixture::new("image_set_cover_reorder.sqlite");
        write_solid_jpeg(&fixture.root.join("album/a.jpg"), 10, 20, 30);
        write_solid_jpeg(&fixture.root.join("album/b.jpg"), 200, 100, 50);
        fixture.sync();
        let set_id = fixture.set_id("album");

        let first = fixture
            .runtime
            .block_on(store_image_set_cover(&fixture.library_id, &set_id))
            .expect("store")
            .expect("jpeg");
        let first_row = fixture
            .runtime
            .block_on(find_image_set_cover(&set_id))
            .expect("find")
            .expect("row");
        let images = fixture
            .runtime
            .block_on(list_image_set_images(&fixture.library_id, &set_id))
            .expect("images");
        assert_eq!(images.len(), 2);
        let reordered = vec![
            images[1].image_set_image_id.clone(),
            images[0].image_set_image_id.clone(),
        ];
        fixture
            .runtime
            .block_on(reorder_image_set_images(
                &fixture.library_id,
                &set_id,
                &reordered,
            ))
            .expect("reorder");
        assert!(fixture
            .runtime
            .block_on(find_image_set_cover(&set_id))
            .expect("find after invalidate")
            .is_none());

        let second_jpeg = fixture
            .runtime
            .block_on(store_image_set_cover(&fixture.library_id, &set_id))
            .expect("store again")
            .expect("jpeg");
        let second_row = fixture
            .runtime
            .block_on(find_image_set_cover(&set_id))
            .expect("find")
            .expect("row");
        assert_eq!(second_row.source_image_set_image_id, reordered[0]);
        assert_ne!(
            second_row.source_image_set_image_id,
            first_row.source_image_set_image_id
        );
        assert_ne!(second_jpeg, first);
    });
}

#[test]
fn invalidate_drops_cached_row() {
    common::with_global_db(|| {
        let fixture = Fixture::new("image_set_cover_invalidate.sqlite");
        write_solid_jpeg(&fixture.root.join("album/a.jpg"), 1, 2, 3);
        fixture.sync();
        let set_id = fixture.set_id("album");
        fixture
            .runtime
            .block_on(store_image_set_cover(&fixture.library_id, &set_id))
            .expect("store")
            .expect("jpeg");
        fixture
            .runtime
            .block_on(invalidate_image_set_cover(&set_id))
            .expect("invalidate");
        assert!(fixture
            .runtime
            .block_on(find_image_set_cover(&set_id))
            .expect("find")
            .is_none());
    });
}
