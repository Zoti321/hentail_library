//! Image set Author / Tag / Parody / Character bindings on global dictionaries (#602).

mod common;

use std::fs;
use std::path::{Path, PathBuf};

use hentai_core::{
    connection, create_image_set_local_library, create_sync_handle, get_image_set_facets,
    init_db_at_path, list_all_author_names, list_all_named_facet_names, list_image_sets,
    merge_named_facet_name, rename_named_facet_name, sync_library, update_image_set_facets,
    HentaiError, ImageSetFacetsDto, JunctionNamedFacet, SyncScanMode, UpdateImageSetFacetsDto,
};
use sea_orm::{ConnectionTrait, DatabaseBackend, Statement};
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
        write_file(&root.join("album1/01.jpg"));
        write_file(&root.join("album2/01.jpg"));
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
        let fixture = Self {
            _temp: temp,
            runtime,
            root,
            library_id,
        };
        fixture.sync();
        fixture
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

    fn id(&self, relative_path: &str) -> String {
        self.runtime
            .block_on(list_image_sets(&self.library_id))
            .expect("sets")
            .into_iter()
            .find(|set| set.relative_path == relative_path)
            .expect("set present")
            .image_set_id
    }

    fn write(&self, id: &str, patch: UpdateImageSetFacetsDto) -> Result<(), HentaiError> {
        self.runtime.block_on(update_image_set_facets(id, patch))
    }

    fn facets(&self, id: &str) -> ImageSetFacetsDto {
        self.runtime
            .block_on(get_image_set_facets(id))
            .expect("facets")
    }

    fn junction_rows(&self, table: &str, id: &str) -> i64 {
        self.runtime.block_on(async {
            connection()
                .expect("db")
                .query_one(Statement::from_string(
                    DatabaseBackend::Sqlite,
                    format!("SELECT COUNT(*) FROM {table} WHERE image_set_id = '{id}'"),
                ))
                .await
                .expect("count")
                .expect("row")
                .try_get_by_index::<i64>(0)
                .expect("int")
        })
    }
}

fn write_file(path: &Path) {
    fs::create_dir_all(path.parent().expect("parent")).expect("mkdir");
    fs::write(path, b"img").expect("write file");
}

fn names(values: &[&str]) -> Vec<String> {
    values.iter().map(|v| v.to_string()).collect()
}

fn full_patch() -> UpdateImageSetFacetsDto {
    UpdateImageSetFacetsDto {
        authors: Some(names(&[" 作者B ", "作者A", "作者B", ""])),
        tags: Some(names(&["tag2", "tag1"])),
        parodies: Some(names(&["Fate"])),
        characters: Some(names(&["Saber", " Rin "])),
    }
}

#[test]
fn facets_write_normalized_and_read_back_from_global_dictionaries() {
    common::with_global_db(|| {
        let fixture = Fixture::new("facets_rw.sqlite");
        let id = fixture.id("album1");

        fixture.write(&id, full_patch()).expect("write");

        assert_eq!(
            fixture.facets(&id),
            ImageSetFacetsDto {
                authors: names(&["作者A", "作者B"]),
                tags: names(&["tag1", "tag2"]),
                parodies: names(&["Fate"]),
                characters: names(&["Rin", "Saber"]),
            }
        );
        assert!(fixture.facets(&fixture.id("album2")) == ImageSetFacetsDto::default());
        fixture.runtime.block_on(async {
            assert!(list_all_author_names()
                .await
                .expect("authors")
                .contains(&"作者A".to_string()));
            assert!(list_all_named_facet_names(JunctionNamedFacet::Tag)
                .await
                .expect("tags")
                .contains(&"tag1".to_string()));
        });
    });
}

#[test]
fn facet_write_replaces_given_fields_and_leaves_others() {
    common::with_global_db(|| {
        let fixture = Fixture::new("facets_replace.sqlite");
        let id = fixture.id("album1");
        fixture.write(&id, full_patch()).expect("write");

        fixture
            .write(
                &id,
                UpdateImageSetFacetsDto {
                    tags: Some(names(&["tag3"])),
                    characters: Some(vec![]),
                    ..Default::default()
                },
            )
            .expect("replace");

        let facets = fixture.facets(&id);
        assert_eq!(facets.tags, names(&["tag3"]));
        assert!(facets.characters.is_empty());
        assert_eq!(facets.authors, names(&["作者A", "作者B"]));
        assert_eq!(facets.parodies, names(&["Fate"]));
    });
}

#[test]
fn sync_does_not_rewrite_facet_bindings() {
    common::with_global_db(|| {
        let fixture = Fixture::new("facets_sync.sqlite");
        let id = fixture.id("album1");
        fixture.write(&id, full_patch()).expect("write");
        let before = fixture.facets(&id);

        write_file(&fixture.root.join("album1/02.jpg"));
        fixture.sync();
        fixture.sync();

        assert_eq!(fixture.id("album1"), id);
        assert_eq!(fixture.facets(&id), before);
    });
}

#[test]
fn removed_image_set_cascades_bindings_but_keeps_dictionaries() {
    common::with_global_db(|| {
        let fixture = Fixture::new("facets_cascade.sqlite");
        let id = fixture.id("album2");
        fixture.write(&id, full_patch()).expect("write");

        fs::remove_dir_all(fixture.root.join("album2")).expect("remove album2");
        fixture.sync();

        for table in [
            "image_set_authors",
            "image_set_tags",
            "image_set_parodies",
            "image_set_characters",
        ] {
            assert_eq!(fixture.junction_rows(table, &id), 0, "{table}");
        }
        fixture.runtime.block_on(async {
            assert!(list_all_named_facet_names(JunctionNamedFacet::Parody)
                .await
                .expect("parodies")
                .contains(&"Fate".to_string()));
        });
    });
}

#[test]
fn dictionary_rename_and_merge_carry_image_set_bindings() {
    common::with_global_db(|| {
        let fixture = Fixture::new("facets_rename.sqlite");
        let id = fixture.id("album1");
        fixture.write(&id, full_patch()).expect("write");

        fixture.runtime.block_on(async {
            rename_named_facet_name(JunctionNamedFacet::Tag, "tag1", "tagX")
                .await
                .expect("rename");
            merge_named_facet_name(JunctionNamedFacet::Character, "Rin", "Saber")
                .await
                .expect("merge");
        });

        let facets = fixture.facets(&id);
        assert_eq!(facets.tags, names(&["tag2", "tagX"]));
        assert_eq!(facets.characters, names(&["Saber"]));
    });
}

#[test]
fn unknown_image_set_is_rejected() {
    common::with_global_db(|| {
        let fixture = Fixture::new("facets_unknown.sqlite");
        assert!(fixture.write("missing", full_patch()).is_err());
        assert!(fixture
            .runtime
            .block_on(get_image_set_facets("missing"))
            .is_err());
    });
}
