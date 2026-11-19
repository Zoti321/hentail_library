#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

mod common;

use std::io::Read;

use hentai_core::resource_metadata::{process_next, set_enabled, status_for_comic};
use hentai_core::{connection, find_comic_by_id, update_comic_user_meta, UpdateComicUserMetaDto};
use sea_orm::{ConnectionTrait, Statement};

#[test]
fn sevenz_and_epub_native_containers_roundtrip_without_changing_original_members() {
    common::with_global_db(|| {
        let temp = tempfile::TempDir::new().unwrap().keep();
        let root = temp.join("library");
        std::fs::create_dir_all(&root).unwrap();
        let sevenz = root.join("book.cb7");
        let mut writer = sevenz_rust::SevenZWriter::create(&sevenz).unwrap();
        for name in ["001.jpg", "002.jpg"] {
            let mut entry = sevenz_rust::SevenZArchiveEntry::new();
            entry.name = name.into();
            writer
                .push_archive_entry(entry, Some(b"original image".as_slice()))
                .unwrap();
        }
        writer.finish().unwrap();
        for version in ["2.0", "3.0"] {
            let mut zip = zip::ZipWriter::new(
                std::fs::File::create(root.join(format!("book-{version}.epub"))).unwrap(),
            );
            let options = zip::write::SimpleFileOptions::default()
                .compression_method(zip::CompressionMethod::Stored);
            for (name, data) in [
                ("mimetype", "application/epub+zip".to_owned()),
                ("META-INF/container.xml", "<container><rootfiles><rootfile full-path='OEBPS/book.opf'/></rootfiles></container>".to_owned()),
                ("OEBPS/book.opf", format!("<package xmlns='http://www.idpf.org/2007/opf' version='{version}' unique-identifier='uid'><metadata xmlns:dc='http://purl.org/dc/elements/1.1/'><dc:identifier id='uid'>keep-id</dc:identifier><dc:title>Old</dc:title><dc:language>ja</dc:language></metadata><manifest><item id='page' href='page.jpg' media-type='image/jpeg'/></manifest><spine><itemref idref='page'/></spine></package>")),
                ("OEBPS/page.jpg", "original image".to_owned()),
            ] {
                zip.start_file(name, options).unwrap(); std::io::Write::write_all(&mut zip, data.as_bytes()).unwrap();
            }
            zip.finish().unwrap();
        }
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            hentai_core::init_db_at_path(&temp.join("containers.sqlite"))
                .await
                .unwrap();
            let library = hentai_core::create_local_library(&root.to_string_lossy(), None)
                .await
                .unwrap();
            hentai_core::sync_library(
                hentai_core::create_sync_handle(),
                hentai_core::SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .unwrap();
            let db = connection().unwrap();
            let ids = db
                .query_all(Statement::from_string(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT comic_id FROM comics".to_owned(),
                ))
                .await
                .unwrap();
            assert_eq!(ids.len(), 3);
            for row in &ids {
                let id: String = row.try_get("", "comic_id").unwrap();
                update_comic_user_meta(
                    &id,
                    UpdateComicUserMetaDto {
                        title: Some("New 标题 &".into()),
                        authors: Some(vec!["A,B".into()]),
                        tags: Some(vec!["T".into()]),
                        languages: Some(vec!["Esperanto".into()]),
                        parodies: Some(vec!["IP".into()]),
                        content_rating: Some("safe".into()),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();
            }
            set_enabled(&library.library_id, true).await.unwrap();
            for _ in 0..3 {
                assert!(process_next().await.unwrap());
            }
            assert!(!process_next().await.unwrap());
            for row in ids {
                let id: String = row.try_get("", "comic_id").unwrap();
                let status = status_for_comic(&id).await.unwrap().unwrap();
                assert_eq!(status.state, "completed", "{:?}", status.error);
                let comic = find_comic_by_id(&id).await.unwrap().unwrap();
                let parsed = hentai_core::resource::parsed_to_comic(
                    &hentai_core::resource::parse_file(std::path::Path::new(&comic.path))
                        .unwrap()
                        .unwrap(),
                );
                assert_eq!(parsed.title, comic.title);
                assert_eq!(parsed.author_names(), ["A,B"]);
                assert_eq!(parsed.languages, ["Esperanto"]);
                assert_eq!(parsed.parodies, ["IP"]);
                assert_eq!(parsed.content_rating, "safe");
                if comic.resource_type == "epub" {
                    let mut archive =
                        zip::ZipArchive::new(std::fs::File::open(&comic.path).unwrap()).unwrap();
                    assert_eq!(archive.by_index(0).unwrap().name(), "mimetype");
                    assert_eq!(
                        archive.by_index(0).unwrap().compression(),
                        zip::CompressionMethod::Stored
                    );
                    let mut bytes = String::new();
                    archive
                        .by_name("OEBPS/page.jpg")
                        .unwrap()
                        .read_to_string(&mut bytes)
                        .unwrap();
                    assert_eq!(bytes, "original image");
                    let mut opf = String::new();
                    archive
                        .by_name("OEBPS/book.opf")
                        .unwrap()
                        .read_to_string(&mut opf)
                        .unwrap();
                    assert!(opf.contains("keep-id"));
                    assert!(opf.contains("<spine><itemref idref='page'/></spine>"));
                }
            }
        });
    });
}

#[test]
fn directory_metadata_keeps_resource_discovery_and_page_fingerprint_intact() {
    common::with_global_db(|| {
        let temp = tempfile::TempDir::new().unwrap().keep();
        let root = temp.join("library");
        let source = root.join("book");
        std::fs::create_dir_all(&source).unwrap();
        std::fs::write(source.join("1.jpg"), b"original page one").unwrap();
        std::fs::write(source.join("2.jpg"), b"original page two").unwrap();
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            hentai_core::init_db_at_path(&temp.join("directory.sqlite"))
                .await
                .unwrap();
            let library = hentai_core::create_local_library(&root.to_string_lossy(), None)
                .await
                .unwrap();
            hentai_core::sync_library(
                hentai_core::create_sync_handle(),
                hentai_core::SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .unwrap();
            let comic = first_comic(&library.library_id).await;
            assert_eq!(comic.resource_type, "dir");
            let db = connection().unwrap();
            let old = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT digest FROM comic_content_fingerprints WHERE comic_id = ?",
                    [comic.comic_id.clone().into()],
                ))
                .await
                .unwrap()
                .unwrap()
                .try_get::<String>("", "digest")
                .unwrap();
            update_comic_user_meta(
                &comic.comic_id,
                UpdateComicUserMetaDto {
                    title: Some("Directory title".into()),
                    languages: Some(vec!["Japanese".into()]),
                    ..Default::default()
                },
            )
            .await
            .unwrap();
            set_enabled(&library.library_id, true).await.unwrap();
            assert!(process_next().await.unwrap());
            let status = status_for_comic(&comic.comic_id).await.unwrap().unwrap();
            assert_eq!(status.state, "completed", "{:?}", status.error);
            let parsed = hentai_core::resource::parse_directory(&source)
                .unwrap()
                .unwrap();
            assert_eq!(parsed.page_count, 2);
            assert_eq!(parsed.title, "Directory title");
            assert_eq!(
                hentai_core::resource::parsed_to_comic(&parsed).languages,
                ["Japanese"]
            );
            assert_eq!(
                std::fs::read(source.join("1.jpg")).unwrap(),
                b"original page one"
            );
            assert_eq!(
                std::fs::read(source.join("2.jpg")).unwrap(),
                b"original page two"
            );
            let new = db
                .query_one(Statement::from_sql_and_values(
                    sea_orm::DatabaseBackend::Sqlite,
                    "SELECT digest FROM comic_content_fingerprints WHERE comic_id = ?",
                    [comic.comic_id.clone().into()],
                ))
                .await
                .unwrap()
                .unwrap()
                .try_get::<String>("", "digest")
                .unwrap();
            assert_eq!(old, new, "directory fingerprint excludes metadata XML");
        });
    });
}

async fn first_comic(library_id: &str) -> hentai_core::ComicDto {
    let db = connection().unwrap();
    let row = db
        .query_one(Statement::from_sql_and_values(
            sea_orm::DatabaseBackend::Sqlite,
            "SELECT comic_id FROM comics WHERE library_id = ?",
            [library_id.into()],
        ))
        .await
        .unwrap()
        .unwrap();
    find_comic_by_id(&row.try_get::<String>("", "comic_id").unwrap())
        .await
        .unwrap()
        .unwrap()
}

#[test]
fn dictionary_changes_and_trash_restore_schedule_only_committed_current_metadata() {
    common::with_local_library(
        "writeback-dictionaries.sqlite",
        &[("book.cbz", 1)],
        |library, runtime| {
            runtime.block_on(async {
                let comic = first_comic(&library.library_id).await;
                let id = &comic.comic_id;
                update_comic_user_meta(
                    id,
                    UpdateComicUserMetaDto {
                        authors: Some(vec!["Old author".into()]),
                        tags: Some(vec!["Old tag".into()]),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();
                set_enabled(&library.library_id, true).await.unwrap();
                assert!(process_next().await.unwrap());
                hentai_core::rename_author("Old author", "New author")
                    .await
                    .unwrap();
                hentai_core::rename_named_facet_name(
                    hentai_core::JunctionNamedFacet::Tag,
                    "Old tag",
                    "New tag",
                )
                .await
                .unwrap();
                assert_eq!(
                    status_for_comic(id).await.unwrap().unwrap().state,
                    "pending"
                );
                assert!(process_next().await.unwrap());
                let imported = hentai_core::resource::parsed_to_comic(
                    &hentai_core::resource::parse_file(std::path::Path::new(&comic.path))
                        .unwrap()
                        .unwrap(),
                );
                assert_eq!(imported.author_names(), ["New author"]);
                assert_eq!(imported.tags, ["New tag"]);
                hentai_core::delete_authors_by_names(vec!["New author".into()])
                    .await
                    .unwrap();
                hentai_core::delete_named_facet_by_names(
                    hentai_core::JunctionNamedFacet::Tag,
                    vec!["New tag".into()],
                )
                .await
                .unwrap();
                hentai_core::trash_comics(vec![id.clone()]).await.unwrap();
                assert!(!process_next().await.unwrap());
                assert!(status_for_comic(id).await.unwrap().is_none());
                hentai_core::restore_comics(vec![id.clone()]).await.unwrap();
                assert!(process_next().await.unwrap());
                let imported = hentai_core::resource::parsed_to_comic(
                    &hentai_core::resource::parse_file(std::path::Path::new(&comic.path))
                        .unwrap()
                        .unwrap(),
                );
                assert_eq!(imported.authors.len(), 0);
                assert_eq!(imported.tags.len(), 0);
            });
        },
    );
}

#[test]
fn cbz_execution_roundtrips_all_metadata_and_updates_observations_without_page_changes() {
    common::with_local_library(
        "writeback-execute.sqlite",
        &[("book.cbz", 2)],
        |library, runtime| {
            runtime.block_on(async {
            let comic = first_comic(&library.library_id).await;
            update_comic_user_meta(&comic.comic_id, UpdateComicUserMetaDto {
                title: Some("标题 <&>".into()), description: Some("A\nB".into()), published_at: Some(1_700_000_000_123),
                authors: Some(vec!["A,B".into(), "C;D".into()]), tags: Some(vec!["tag,with,comma".into()]),
                languages: Some(vec!["Esperanto".into()]), parodies: Some(vec!["IP".into()]),
                characters: Some(vec!["Character".into()]), content_rating: Some("safe".into()),
            }).await.unwrap();
            set_enabled(&library.library_id, true).await.unwrap();
            assert!(process_next().await.unwrap());
            assert!(!process_next().await.unwrap());
            let status = status_for_comic(&comic.comic_id).await.unwrap().unwrap();
            assert_eq!(status.state, "completed", "{:?}", status.error);
            assert_eq!(status.revision, status.applied_revision);
            assert!(status.last_success_at.is_some());
            let parsed = hentai_core::resource::parse_file(std::path::Path::new(&comic.path)).unwrap().unwrap();
            let imported = hentai_core::resource::parsed_to_comic(&parsed);
            let current = find_comic_by_id(&comic.comic_id).await.unwrap().unwrap();
            assert_eq!(imported.title, current.title);
            assert_eq!(imported.author_names(), current.author_names());
            assert_eq!(imported.tags, current.tags);
            assert_eq!(imported.languages, current.languages);
            assert_eq!(imported.parodies, current.parodies);
            assert_eq!(imported.characters, current.characters);
            assert_eq!(imported.published_at, current.published_at);
            assert_eq!(imported.content_rating, "safe");
            let mut archive = zip::ZipArchive::new(std::fs::File::open(&comic.path).unwrap()).unwrap();
            for page in ["000.jpg", "001.jpg"] {
                let mut bytes = Vec::new();
                archive.by_name(page).unwrap().read_to_end(&mut bytes).unwrap();
                assert_eq!(bytes, b"page");
            }
            drop(archive);
            let db = connection().unwrap();
            let row = db.query_one(Statement::from_sql_and_values(sea_orm::DatabaseBackend::Sqlite,
                "SELECT f.size, s.size AS snapshot_size FROM comic_content_fingerprints f JOIN library_resource_snapshots s ON s.library_id = ? WHERE f.comic_id = ?",
                [library.library_id.clone().into(), comic.comic_id.clone().into()],
            )).await.unwrap().unwrap();
            assert_eq!(row.try_get::<i64>("", "size").unwrap(), current.resource_size);
            assert_eq!(row.try_get::<i64>("", "snapshot_size").unwrap(), current.resource_size);
            update_comic_user_meta(&comic.comic_id, UpdateComicUserMetaDto { description: Some(String::new()), tags: Some(vec![]), ..Default::default() }).await.unwrap();
            assert!(process_next().await.unwrap());
            let imported = hentai_core::resource::parsed_to_comic(&hentai_core::resource::parse_file(std::path::Path::new(&comic.path)).unwrap().unwrap());
            assert_eq!(imported.description, None);
            assert_eq!(imported.tags.len(), 0);
            assert_eq!(imported.author_names(), current.author_names());
        });
        },
    );
}

#[test]
fn replacement_success_followed_by_database_failure_is_recovered_without_rewriting() {
    common::with_local_library(
        "writeback-recovery.sqlite",
        &[("book.cbz", 1)],
        |library, runtime| {
            runtime.block_on(async {
            let comic = first_comic(&library.library_id).await;
            let db = connection().unwrap();
            set_enabled(&library.library_id, true).await.unwrap();
            db.execute_unprepared("CREATE TRIGGER fail_observation BEFORE UPDATE OF resource_size ON comics BEGIN SELECT RAISE(ABORT, 'observation blocked'); END").await.unwrap();
            assert!(process_next().await.unwrap());
            let status = status_for_comic(&comic.comic_id).await.unwrap().unwrap();
            assert_eq!(status.state, "failed");
            assert!(status.error.unwrap().contains("observation blocked"));
            let bytes = std::fs::read(&comic.path).unwrap();
            assert_ne!(hentai_core::util::usize_to_i64(bytes.len()), comic.resource_size);
            assert!(!process_next().await.unwrap(), "failed work must respect backoff");
            db.execute_unprepared("DROP TRIGGER fail_observation; UPDATE resource_metadata_jobs SET due_at = 0").await.unwrap();
            assert!(process_next().await.unwrap());
            let status = status_for_comic(&comic.comic_id).await.unwrap().unwrap();
            assert_eq!(status.state, "completed", "{:?}", status.error);
            assert_eq!(std::fs::read(&comic.path).unwrap(), bytes);
            assert_eq!(status.revision, status.applied_revision);
        });
        },
    );
}

#[test]
fn malformed_metadata_fails_safely_and_disabling_stops_execution() {
    common::with_local_library(
        "writeback-invalid.sqlite",
        &[("book.cbz", 1)],
        |library, runtime| {
            runtime.block_on(async {
                let comic = first_comic(&library.library_id).await;
                let file = std::fs::OpenOptions::new()
                    .read(true)
                    .write(true)
                    .open(&comic.path)
                    .unwrap();
                let mut writer = zip::ZipWriter::new_append(file).unwrap();
                writer
                    .start_file("ComicInfo.xml", zip::write::SimpleFileOptions::default())
                    .unwrap();
                std::io::Write::write_all(&mut writer, b"<ComicInfo>").unwrap();
                writer.finish().unwrap();
                let before = std::fs::read(&comic.path).unwrap();
                set_enabled(&library.library_id, true).await.unwrap();
                assert!(process_next().await.unwrap());
                assert_eq!(std::fs::read(&comic.path).unwrap(), before);
                assert_eq!(
                    status_for_comic(&comic.comic_id)
                        .await
                        .unwrap()
                        .unwrap()
                        .state,
                    "failed"
                );
                update_comic_user_meta(
                    &comic.comic_id,
                    UpdateComicUserMetaDto {
                        title: Some("Catalog save works".into()),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();
                set_enabled(&library.library_id, false).await.unwrap();
                assert!(!process_next().await.unwrap());
                assert_eq!(
                    find_comic_by_id(&comic.comic_id)
                        .await
                        .unwrap()
                        .unwrap()
                        .title,
                    "Catalog save works"
                );
            });
        },
    );
}
