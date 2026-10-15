//! Author image 统一取图：按来源解析到 Comic 封面，返回高清字节。

mod common;

use std::fs;
use std::path::Path;

use hentai_core::{
    add_author, connection, create_local_library, init_db_at_path, load_author_image,
    replace_comic_authors, AuthorImageSlot,
};
use image::{ImageBuffer, Rgb};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

fn write_jpeg(path: &Path, r: u8, g: u8, b: u8) {
    let img: ImageBuffer<Rgb<u8>, Vec<u8>> = ImageBuffer::from_pixel(64, 96, Rgb([r, g, b]));
    img.save(path).expect("write jpeg");
}

#[test]
fn author_image_resolves_to_hd_cover_of_first_visible_comic() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("library");
        let comic_dir = root.join("comic");
        fs::create_dir_all(&comic_dir).expect("mkdir");
        write_jpeg(&comic_dir.join("001.jpg"), 255, 0, 0);
        write_jpeg(&comic_dir.join("cover.jpg"), 0, 0, 255);
        let cover_bytes = fs::read(comic_dir.join("cover.jpg")).expect("read cover");

        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        let (author_id, lonely_id) = runtime.block_on(async {
            init_db_at_path(temp.path().join("author_image.sqlite"))
                .await
                .expect("init db");
            let library = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("library");
            let db = connection().expect("connection");
            let path = comic_dir.to_string_lossy().replace('\\', "/");
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comics (comic_id, library_id, path, resource_type, resource_size, created_at, last_updated_at) \
                 VALUES ('hd-comic', ?, ?, 'dir', 1, 1, 1)",
                [library.library_id.into(), path.into()],
            ))
            .await
            .expect("seed comic");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
                 VALUES ('hd-comic', 'HD', 'HD', 'safe', 2)"
                    .to_string(),
            ))
            .await
            .expect("seed meta");
            replace_comic_authors(&db, "hd-comic", &["Painter".to_string()])
                .await
                .expect("attach author");
            let painter = add_author("Painter").await.expect("painter");
            let lonely = add_author("Lonely").await.expect("lonely");
            (painter.id, lonely.id)
        });

        let avatar = load_author_image(author_id, AuthorImageSlot::Avatar, false)
            .expect("avatar")
            .expect("avatar bytes");
        assert_eq!(avatar, cover_bytes);
        let background = load_author_image(author_id, AuthorImageSlot::Background, false)
            .expect("background")
            .expect("background bytes");
        assert_eq!(background, cover_bytes);

        assert_eq!(
            load_author_image(lonely_id, AuthorImageSlot::Avatar, false).expect("lonely"),
            None
        );
    });
}
