use std::sync::Mutex;

use hentai_core::{
    add_tag, import_tag_dictionary, init_db_at_path, list_all_tags, TagDictionaryImportResult,
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
  "tags": ["巨乳", "", "   ", "肌肉", "巨乳"]
}"#;

#[test]
fn import_tag_dictionary_adds_names_from_wrapped_payload() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let first = runtime
            .block_on(import_tag_dictionary(FIXTURE_JSON.as_bytes()))
            .expect("import");
        assert_eq!(
            first,
            TagDictionaryImportResult {
                added: 2,
                skipped_existing: 0,
                skipped_filtered_or_empty_or_dedupe: 3,
            }
        );

        let tags = runtime.block_on(list_all_tags()).expect("list");
        assert!(tags.contains(&"巨乳".to_string()));
        assert!(tags.contains(&"肌肉".to_string()));

        let second = runtime
            .block_on(import_tag_dictionary(FIXTURE_JSON.as_bytes()))
            .expect("reimport");
        assert_eq!(
            second,
            TagDictionaryImportResult {
                added: 0,
                skipped_existing: 2,
                skipped_filtered_or_empty_or_dedupe: 3,
            }
        );
    });
}

#[test]
fn import_tag_dictionary_accepts_flat_array_payload() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import_flat.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let result = runtime
            .block_on(import_tag_dictionary(r#"["全彩", "无修正"]"#.as_bytes()))
            .expect("import");
        assert_eq!(
            result,
            TagDictionaryImportResult {
                added: 2,
                skipped_existing: 0,
                skipped_filtered_or_empty_or_dedupe: 0,
            }
        );
    });
}

#[test]
fn import_tag_dictionary_respects_existing_tags() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import_existing.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");
        runtime.block_on(add_tag("巨乳")).expect("seed tag");

        let result = runtime
            .block_on(import_tag_dictionary(FIXTURE_JSON.as_bytes()))
            .expect("import");
        assert_eq!(
            result,
            TagDictionaryImportResult {
                added: 1,
                skipped_existing: 1,
                skipped_filtered_or_empty_or_dedupe: 3,
            }
        );
    });
}

#[test]
fn import_tag_dictionary_rejects_invalid_json() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import_invalid.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let err = runtime
            .block_on(import_tag_dictionary(b"not json"))
            .expect_err("invalid json");
        assert!(err.message.contains("无效的标签字典 JSON"));
    });
}

#[test]
fn import_tag_dictionary_batch_inserts_more_than_one_chunk() {
    with_global_db(|| {
        let temp = TempDir::new().expect("tempdir");
        let db_path = temp.path().join("tag_import_batch.sqlite");
        let runtime = tokio::runtime::Runtime::new().expect("runtime");
        runtime
            .block_on(init_db_at_path(&db_path))
            .expect("init db");

        let mut tag_entries = Vec::new();
        for index in 0..600 {
            tag_entries.push(format!(r#""标签{index}""#));
        }
        let json = format!(r#"{{ "tags": [{}] }}"#, tag_entries.join(","));

        let result = runtime
            .block_on(import_tag_dictionary(json.as_bytes()))
            .expect("import");
        assert_eq!(result.added, 600);
        assert_eq!(result.skipped_existing, 0);
        assert_eq!(result.skipped_filtered_or_empty_or_dedupe, 0);

        let tags = runtime.block_on(list_all_tags()).expect("list");
        assert!(tags.contains(&"标签0".to_string()));
        assert!(tags.contains(&"标签599".to_string()));
    });
}
