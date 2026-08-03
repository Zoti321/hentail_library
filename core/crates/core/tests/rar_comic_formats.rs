use std::path::PathBuf;

use hentai_core::{load_page_bytes, load_page_list, open_reader};
use hentai_core::formats::read_rar_cover_bytes;
use hentai_core::resource::parse_file;

fn fixtures_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../tests/fixtures/comics")
}

fn fixture(name: &str) -> PathBuf {
    fixtures_dir().join(name)
}

#[test]
fn rar4_reader_lists_and_reads_image_pages() {
    let path = fixture("sample-rar4.rar");
    assert!(path.is_file(), "missing fixture {}", path.display());
    let path_str = path.to_string_lossy().to_string();

    open_reader("rar4-comic", &path_str, "rar").expect("open");
    let list = load_page_list("rar4-comic", &path_str, "rar").expect("list");
    assert_eq!(list.page_count, 2);
    let page0 = load_page_bytes("rar4-comic", &path_str, "rar", 0).expect("page0");
    let page1 = load_page_bytes("rar4-comic", &path_str, "rar", 1).expect("page1");
    assert_eq!(page0, b"page-one");
    assert_eq!(page1, b"page-two");
}

#[test]
fn rar5_reader_lists_and_reads_image_pages() {
    let path = fixture("sample-rar5.rar");
    assert!(path.is_file(), "missing fixture {}", path.display());
    let path_str = path.to_string_lossy().to_string();

    open_reader("rar5-comic", &path_str, "rar").expect("open");
    let list = load_page_list("rar5-comic", &path_str, "rar").expect("list");
    // Natural sort: 001.jpg, 002.jpg, cover.jpg
    assert_eq!(list.page_count, 3);
    let page0 = load_page_bytes("rar5-comic", &path_str, "rar", 0).expect("page0");
    let page1 = load_page_bytes("rar5-comic", &path_str, "rar", 1).expect("page1");
    assert_eq!(page0, b"page-one");
    assert_eq!(page1, b"page-two");
}

#[test]
fn cbr_extension_aliases_rar_reader_behavior() {
    let src = fixture("sample-rar4.rar");
    let temp = tempfile::tempdir().expect("tempdir");
    let cbr = temp.path().join("sample.cbr");
    std::fs::copy(&src, &cbr).expect("copy cbr");
    let path_str = cbr.to_string_lossy().to_string();

    open_reader("cbr-comic", &path_str, "cbr").expect("open");
    let list = load_page_list("cbr-comic", &path_str, "cbr").expect("list");
    assert_eq!(list.page_count, 2);
    assert_eq!(
        load_page_bytes("cbr-comic", &path_str, "cbr", 0).expect("page0"),
        b"page-one"
    );
}

#[test]
fn parse_file_recognizes_rar_and_cbr_comics() {
    let rar = parse_file(&fixture("sample-rar4.rar"))
        .expect("parse rar")
        .expect("rar should be a comic");
    assert_eq!(rar.resource_type, "rar");
    assert_eq!(rar.page_count, 2);

    let temp = tempfile::tempdir().expect("tempdir");
    let cbr_path = temp.path().join("alias.cbr");
    std::fs::copy(fixture("sample-rar4.rar"), &cbr_path).expect("copy");
    let cbr = parse_file(&cbr_path)
        .expect("parse cbr")
        .expect("cbr should be a comic");
    assert_eq!(cbr.resource_type, "cbr");
    assert_eq!(cbr.page_count, 2);
}

#[test]
fn rar_cover_prefers_cover_named_entry() {
    let cover = read_rar_cover_bytes(&fixture("sample-rar5.rar"))
        .expect("read cover")
        .expect("cover bytes");
    assert_eq!(cover, b"cover-bytes");
}
