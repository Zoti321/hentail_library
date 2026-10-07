//! Author 稳定身份：迁移附着、rename 保 links、delete 级联、详情聚合、链接 CRUD、筛选按 id。

mod common;

use hentai_core::image_cache::{ImageCache, PlatformImageKey};
use hentai_core::{
    add_author, add_author_link, connection, create_local_library, delete_author_link,
    delete_authors_by_names, fetch_comics_page, get_author_detail, init_db_at_path,
    list_author_links, rename_author, replace_comic_authors, resolve_author_image, trash_comics,
    update_author_link, AuthorImageSource, AuthorLinkPlatform, ComicFilterDto, ComicSortOptionDto,
    PageRequestDto,
};
use sea_orm::{ConnectionTrait, Statement};
use tempfile::TempDir;

async fn seed_comic(
    db: &impl ConnectionTrait,
    comic_id: &str,
    library_id: &str,
    path: &str,
    title: &str,
    content_rating: &str,
) {
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comics (comic_id, library_id, path, resource_type, resource_size, created_at, last_updated_at) \
         VALUES (?, ?, ?, 'cbz', 1, 1, 1)",
        [comic_id.into(), library_id.into(), path.into()],
    ))
    .await
    .expect("seed comic");
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        "INSERT INTO comic_meta (comic_id, title, title_sort_key, content_rating, page_count) \
         VALUES (?, ?, ?, ?, 1)",
        [
            comic_id.into(),
            title.into(),
            title.into(),
            content_rating.into(),
        ],
    ))
    .await
    .expect("seed meta");
}

async fn author_id_named(db: &impl ConnectionTrait, name: &str) -> i64 {
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT id FROM authors WHERE name = ?",
            [name.into()],
        ))
        .await
        .expect("query")
        .expect("row");
    row.try_get_by_index::<i64>(0).expect("id")
}

#[test]
fn fixture_migration_keeps_author_attachments() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let db = connection().expect("connection");
            let row = db
                .query_one(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT a.name FROM comic_authors ca \
                     INNER JOIN authors a ON a.id = ca.author_id \
                     WHERE ca.comic_id = '86408880d30b0de95ca959feb60a3b72dcb1889b'"
                        .to_string(),
                ))
                .await
                .expect("query")
                .expect("attached");
            let name = row.try_get_by_index::<String>(0).expect("name");
            assert_eq!(name, "作者A");
        });
    });
}

#[test]
fn rename_keeps_links_delete_cascades_and_filter_uses_id() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root = temp.path().join("lib");
        std::fs::create_dir_all(&root).expect("mkdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib = create_local_library(&root.to_string_lossy(), None)
                .await
                .expect("library");
            let db = connection().expect("connection");
            seed_comic(&db, "c1", &lib.library_id, "E:/lib/a.cbz", "Alpha", "safe").await;
            replace_comic_authors(&db, "c1", &["Alice".to_string()])
                .await
                .expect("attach");
            let id = author_id_named(&db, "Alice").await;
            add_author_link(id, AuthorLinkPlatform::Pixiv, "https://pixiv.net/u/1", None)
                .await
                .expect("link");

            rename_author("Alice", "Alicia").await.expect("rename");
            let links = list_author_links(id).await.expect("links");
            assert_eq!(links.len(), 1);
            assert_eq!(links[0].url, "https://pixiv.net/u/1");
            assert_eq!(author_id_named(&db, "Alicia").await, id);

            add_author("Bob").await.expect("bob");
            let dup = rename_author("Alicia", "Bob").await;
            assert!(dup.is_err(), "case-sensitive collision");

            let page = fetch_comics_page(
                PageRequestDto {
                    page: 1,
                    page_size: 20,
                },
                ComicFilterDto {
                    authors_all: vec![id.to_string()],
                    library_id: Some(lib.library_id.clone()),
                    ..Default::default()
                },
                false,
                ComicSortOptionDto::default(),
            )
            .await
            .expect("filter");
            assert_eq!(page.total_count, 1);
            assert_eq!(page.items[0].comic_id, "c1");

            delete_authors_by_names(vec!["Alicia".to_string()])
                .await
                .expect("delete");
            let remaining = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM comic_authors WHERE author_id = ?",
                    [id.into()],
                ))
                .await
                .expect("count")
                .expect("row");
            assert_eq!(remaining.try_get_by_index::<i64>(0).expect("n"), 0);
            assert!(list_author_links(id).await.expect("gone").is_empty());
        });
    });
}

#[test]
fn detail_aggregation_excludes_trash_and_healthy_hidden() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let root_a = temp.path().join("lib-a");
        let root_b = temp.path().join("lib-b");
        std::fs::create_dir_all(&root_a).expect("mkdir");
        std::fs::create_dir_all(&root_b).expect("mkdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let lib_a = create_local_library(&root_a.to_string_lossy(), None)
                .await
                .expect("lib a");
            let lib_b = create_local_library(&root_b.to_string_lossy(), None)
                .await
                .expect("lib b");
            let db = connection().expect("connection");
            seed_comic(
                &db,
                "vis",
                &lib_a.library_id,
                "E:/a/a.cbz",
                "Banana",
                "safe",
            )
            .await;
            seed_comic(&db, "r18", &lib_b.library_id, "E:/b/b.cbz", "Apple", "r18").await;
            seed_comic(
                &db,
                "gone",
                &lib_a.library_id,
                "E:/a/c.cbz",
                "Cherry",
                "safe",
            )
            .await;
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_tags (comic_id, tag_name) SELECT 'vis', 'tag-a' \
                 WHERE NOT EXISTS (SELECT 1 FROM tags WHERE name = 'tag-a'); \
                 INSERT OR IGNORE INTO tags (name) VALUES ('tag-a'), ('tag-r18'), ('tag-gone'); \
                 INSERT INTO comic_tags (comic_id, tag_name) VALUES ('vis', 'tag-a'), \
                 ('r18', 'tag-r18'), ('gone', 'tag-gone')"
                    .to_string(),
            ))
            .await
            .ok();
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT OR IGNORE INTO tags (name) VALUES ('tag-a'), ('tag-r18'), ('tag-gone')"
                    .to_string(),
            ))
            .await
            .expect("tags");
            db.execute(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO comic_tags (comic_id, tag_name) VALUES ('vis', 'tag-a'), \
                 ('r18', 'tag-r18'), ('gone', 'tag-gone')"
                    .to_string(),
            ))
            .await
            .expect("attach tags");

            replace_comic_authors(&db, "vis", &["Shared".to_string()])
                .await
                .expect("vis");
            replace_comic_authors(&db, "r18", &["Shared".to_string()])
                .await
                .expect("r18");
            replace_comic_authors(&db, "gone", &["Shared".to_string()])
                .await
                .expect("gone");
            trash_comics(vec!["gone".to_string()]).await.expect("trash");

            let id = author_id_named(&db, "Shared").await;
            let healthy = get_author_detail(id, false)
                .await
                .expect("detail")
                .expect("found");
            assert!(!healthy.identity.verified);
            assert_eq!(
                healthy
                    .tags
                    .iter()
                    .map(|t| t.name.as_str())
                    .collect::<Vec<_>>(),
                vec!["tag-a"]
            );
            assert_eq!(healthy.top_comics.len(), 1);
            assert_eq!(healthy.top_comics[0].comic_id, "vis");
            assert_eq!(healthy.comic_count, 1);

            let all = get_author_detail(id, true)
                .await
                .expect("all")
                .expect("found");
            let tag_names: Vec<&str> = all.tags.iter().map(|t| t.name.as_str()).collect();
            assert!(tag_names.contains(&"tag-a"));
            assert!(tag_names.contains(&"tag-r18"));
            assert!(!tag_names.contains(&"tag-gone"));
            assert_eq!(all.top_comics.len(), 2);
            assert_eq!(all.top_comics[0].comic_id, "r18");
            assert_eq!(all.top_comics[1].comic_id, "vis");
            assert_eq!(all.comic_count, 2);

            add_author_link(id, AuthorLinkPlatform::Other, "https://example.com", None)
                .await
                .expect("other");
            let still = get_author_detail(id, true).await.expect("d").expect("f");
            assert!(!still.identity.verified);
            add_author_link(
                id,
                AuthorLinkPlatform::X,
                "https://x.com/a/status/unsupported",
                None,
            )
            .await
            .expect("x");
            let verified = get_author_detail(id, true).await.expect("d").expect("f");
            assert!(verified.identity.verified);

            let image = resolve_author_image(id, false).await.expect("image");
            assert_eq!(image.avatar_source, AuthorImageSource::ComicCover);
            assert_eq!(image.avatar_comic_id.as_deref(), Some("vis"));
        });
    });
}

#[test]
fn author_link_crud_validates_url() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let created = add_author("LinkMe").await.expect("add");
            let bad =
                add_author_link(created.id, AuthorLinkPlatform::Pixiv, "ftp://nope", None).await;
            assert!(bad.is_err());
            let link = add_author_link(
                created.id,
                AuthorLinkPlatform::Patreon,
                "https://patreon.com",
                Some(" display ".to_string()),
            )
            .await
            .expect("ok");
            assert_eq!(link.platform_display_name.as_deref(), Some("display"));
            update_author_link(
                link.id,
                AuthorLinkPlatform::Fanbox,
                "https://fanbox.cc/x",
                None,
            )
            .await
            .expect("update");
            delete_author_link(created.id, link.id)
                .await
                .expect("delete");
            assert!(list_author_links(created.id)
                .await
                .expect("list")
                .is_empty());
            let missing = delete_author_link(created.id, link.id).await;
            assert!(missing.is_err());
            let other = add_author("OtherOwner").await.expect("other");
            let owned = add_author_link(created.id, AuthorLinkPlatform::X, "https://x.com/a", None)
                .await
                .expect("owned");
            let cross = delete_author_link(other.id, owned.id).await;
            assert!(cross.is_err());
            assert_eq!(
                list_author_links(created.id)
                    .await
                    .expect("still there")
                    .len(),
                1
            );
        });
    });
}

#[test]
fn expired_platform_image_remains_available_until_refresh_succeeds() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let author = add_author("Cached").await.expect("author");
            let db = connection().expect("connection");
            let link_id = db
                .execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO author_links (author_id, platform, url, sort_key, version) \
                     VALUES (?, 'pixiv', 'https://www.pixiv.net/users/42', 0, 1)",
                    [author.id.into()],
                ))
                .await
                .expect("link")
                .last_insert_id() as i64;
            db.execute(Statement::from_sql_and_values(
                sea_orm::DatabaseBackend::Sqlite,
                "INSERT INTO author_image_cache \
                 (author_link_id, slot, profile_url, image_url, checked_at, fetched_at, cache_key, link_version) \
                 VALUES (?, 'avatar', 'https://www.pixiv.net/users/42', 'https://img.example/avatar.png', 1, 1, 'cached', 1)",
                [link_id.into()],
            ))
            .await
            .expect("cache row");
            ImageCache::app()
                .expect("cache")
                .write_platform_image(
                    &PlatformImageKey {
                        author_link_id: link_id,
                        slot: "avatar",
                    },
                    b"previous image",
                )
                .expect("cache file");

            let image = resolve_author_image(author.id, false).await.expect("image");
            assert_eq!(image.avatar_source, AuthorImageSource::PlatformCached);
            assert_eq!(image.avatar_link_id, Some(link_id));
        });
    });
}

#[test]
fn deleting_author_link_removes_cache_rows_and_files() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let author = add_author("DeleteCached").await.expect("author");
            let db = connection().expect("connection");
            let link_id = db
                .execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO author_links (author_id, platform, url, sort_key, version) \
                     VALUES (?, 'pixiv', 'https://www.pixiv.net/users/42', 0, 1)",
                    [author.id.into()],
                ))
                .await
                .expect("link")
                .last_insert_id() as i64;
            let cache = ImageCache::app().expect("cache");
            for slot in ["avatar", "background"] {
                db.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO author_image_cache \
                     (author_link_id, slot, profile_url, image_url, checked_at, fetched_at, cache_key, link_version) \
                     VALUES (?, ?, 'https://www.pixiv.net/users/42', 'https://img.example/image.png', 1, 1, 'cached', 1)",
                    [link_id.into(), slot.into()],
                ))
                .await
                .expect("cache row");
                cache
                    .write_platform_image(
                        &PlatformImageKey {
                            author_link_id: link_id,
                            slot,
                        },
                        b"cached image",
                    )
                    .expect("cache file");
            }

            delete_author_link(author.id, link_id).await.expect("delete");

            let row_count = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM author_image_cache WHERE author_link_id = ?",
                    [link_id.into()],
                ))
                .await
                .expect("count")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("value");
            assert_eq!(row_count, 0);
            for slot in ["avatar", "background"] {
                assert!(cache
                    .read_platform_image(&PlatformImageKey {
                        author_link_id: link_id,
                        slot,
                    })
                    .is_none());
            }
        });
    });
}

#[test]
fn link_update_invalidates_both_slots_while_author_rename_keeps_cache() {
    common::with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = common::create_fixture_db(temp.path());
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime.block_on(async {
            init_db_at_path(&db_path).await.expect("init_db");
            let author = add_author("RenameCached").await.expect("author");
            let db = connection().expect("connection");
            let link_id = db
                .execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO author_links (author_id, platform, url, sort_key, version) \
                     VALUES (?, 'pixiv', 'https://www.pixiv.net/users/42', 0, 1)",
                    [author.id.into()],
                ))
                .await
                .expect("link")
                .last_insert_id() as i64;
            let cache = ImageCache::app().expect("cache");
            for slot in ["avatar", "background"] {
                db.execute(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "INSERT INTO author_image_cache \
                     (author_link_id, slot, profile_url, image_url, checked_at, fetched_at, cache_key, link_version) \
                     VALUES (?, ?, 'https://www.pixiv.net/users/42', 'https://img.example/image.png', 1, 1, 'cached', 1)",
                    [link_id.into(), slot.into()],
                ))
                .await
                .expect("cache row");
                cache
                    .write_platform_image(
                        &PlatformImageKey {
                            author_link_id: link_id,
                            slot,
                        },
                        b"cached image",
                    )
                    .expect("cache file");
            }

            rename_author("RenameCached", "Renamed").await.expect("rename");
            let rows_after_rename = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM author_image_cache WHERE author_link_id = ?",
                    [link_id.into()],
                ))
                .await
                .expect("count")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("value");
            assert_eq!(rows_after_rename, 2);
            assert!(cache
                .read_platform_image(&PlatformImageKey {
                    author_link_id: link_id,
                    slot: "avatar",
                })
                .is_some());

            update_author_link(
                link_id,
                AuthorLinkPlatform::Other,
                "https://example.com/changed",
                None,
            )
            .await
            .expect("update");

            let row = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT version, url FROM author_links WHERE id = ?",
                    [link_id.into()],
                ))
                .await
                .expect("link query")
                .expect("link row");
            assert_eq!(row.try_get_by_index::<i64>(0).expect("version"), 2);
            assert_eq!(
                row.try_get_by_index::<String>(1).expect("url"),
                "https://example.com/changed"
            );
            let rows_after_update = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT COUNT(*) FROM author_image_cache WHERE author_link_id = ?",
                    [link_id.into()],
                ))
                .await
                .expect("count")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("value");
            assert_eq!(rows_after_update, 0);
            for slot in ["avatar", "background"] {
                assert!(cache
                    .read_platform_image(&PlatformImageKey {
                        author_link_id: link_id,
                        slot,
                    })
                    .is_none());
            }
        });
    });
}
