use std::sync::Mutex;

use hentai_core::{
    add_tag, import_ehtag_dictionary, init_db_at_path, list_all_tags, TagDictionaryImportResult,
};
use tempfile::TempDir;

static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

fn with_global_db(test: impl FnOnce()) {
    let _guard = DB_INIT_LOCK
        .lock()
        .expect("global db tests must run serially");
    test();
}

const FIXTURE_JSON: &str = r#"{
  "data": [
    {
      "namespace": "female",
      "data": {
        "big breasts": { "name": "巨乳" },
        "empty tag": { "name": "" },
        "no name": {}
      }
    },
    {
      "namespace": "male",
      "data": {
        "muscle": { "name": "肌肉" }
      }
    },
    {
      "namespace": "artist",
      "data": {
        "some artist": { "name": "某画师" }
      }
    },
    {
      "namespace": "female",
      "data": {
        "duplicate": { "name": "巨乳" }
      }
    }
  ]
}"#;

#[test]
fn import_ehtag_dictionary_adds_chinese_tags_from_allowed_namespaces() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let first = runtime
            .block_on(import_ehtag_dictionary(FIXTURE_JSON.as_bytes()))
            .expect("import");
        assert_eq!(
            first,
            TagDictionaryImportResult {
                added: 2,
                skipped_existing: 0,
                skipped_filtered_or_empty_or_dedupe: 4,
            }
        );

        let tags = runtime.block_on(list_all_tags()).expect("list");
        assert!(tags.contains(&"巨乳".to_string()));
        assert!(tags.contains(&"肌肉".to_string()));
        assert!(!tags.contains(&"某画师".to_string()));

        let second = runtime
            .block_on(import_ehtag_dictionary(FIXTURE_JSON.as_bytes()))
            .expect("reimport");
        assert_eq!(
            second,
            TagDictionaryImportResult {
                added: 0,
                skipped_existing: 2,
                skipped_filtered_or_empty_or_dedupe: 4,
            }
        );
    });
}

#[test]
fn import_ehtag_dictionary_respects_existing_tags() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import_existing.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");
        runtime.block_on(add_tag("巨乳")).expect("seed tag");

        let result = runtime
            .block_on(import_ehtag_dictionary(FIXTURE_JSON.as_bytes()))
            .expect("import");
        assert_eq!(
            result,
            TagDictionaryImportResult {
                added: 1,
                skipped_existing: 1,
                skipped_filtered_or_empty_or_dedupe: 4,
            }
        );
    });
}

#[test]
fn import_ehtag_dictionary_rejects_invalid_json() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import_invalid.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let err = runtime
            .block_on(import_ehtag_dictionary(b"not json"))
            .expect_err("invalid json");
        assert!(err.message.contains("无效的 db.text.json"));
    });
}
