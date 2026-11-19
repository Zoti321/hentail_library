#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

use std::io::{Cursor, Write};

use hentai_core::resource::{parse_resource_with, FakeResourceAccess};
use hentai_core::HentaiErrorCode;

#[test]
fn resource_kind_dispatches_image_directories_even_with_file_extensions() {
    for name in ["Images", "Images.cbz", "Images.pdf"] {
        let location = format!("/resources/{name}");
        let mut access = FakeResourceAccess::new();
        access.insert_file(format!("{location}/001.jpg"), b"page-one");
        access.insert_file(format!("{location}/002.png"), b"page-two");
        let parsed = parse_resource_with(&access, &location).unwrap().unwrap();
        assert_eq!(parsed.path, location);
        assert_eq!(parsed.title, name);
        assert_eq!(parsed.resource_type, "dir");
        assert_eq!(parsed.page_count, 2);
        assert_eq!(parsed.resource_size, 16);
    }
}

#[test]
fn resource_kind_dispatches_files_to_their_format_parser() {
    let mut zip = zip::ZipWriter::new(Cursor::new(Vec::new()));
    let options = zip::write::SimpleFileOptions::default();
    zip.start_file("001.jpg", options).unwrap();
    zip.write_all(b"page").unwrap();
    zip.start_file("ComicInfo.xml", options).unwrap();
    zip.write_all(b"<ComicInfo><Title>Embedded title</Title></ComicInfo>")
        .unwrap();
    let bytes = zip.finish().unwrap().into_inner();
    let size = hentai_core::util::usize_to_i64(bytes.len());
    let location = "/resources/book.cbz";
    let mut access = FakeResourceAccess::new();
    access.insert_file(location, bytes);
    let parsed = parse_resource_with(&access, location).unwrap().unwrap();
    assert_eq!(parsed.path, location);
    assert_eq!(parsed.resource_type, "cbz");
    assert_eq!(parsed.title, "Embedded title");
    assert_eq!(parsed.page_count, 1);
    assert_eq!(parsed.resource_size, size);
}

#[test]
fn resource_kind_keeps_missing_invalid_and_non_comic_resources_absent() {
    let mut access = FakeResourceAccess::new();
    access.insert_dir("/empty");
    access.insert_file("/mixed/001.jpg", b"page");
    access.insert_file("/mixed/notes.txt", b"notes");
    access.insert_file("/nested/001.jpg", b"page");
    access.insert_dir("/nested/subfolder");
    access.insert_file("/notes.txt", b"notes");
    access.insert_file("/broken.cbz", b"not an archive");
    for location in [
        "/missing",
        "/empty",
        "/mixed",
        "/nested",
        "/notes.txt",
        "/broken.cbz",
    ] {
        assert!(
            parse_resource_with(&access, location).unwrap().is_none(),
            "{location}"
        );
    }
}

#[test]
fn resource_kind_preserves_access_errors() {
    let mut access = FakeResourceAccess::new();
    access.set_unreachable("401 auth rejected");
    let error = parse_resource_with(&access, "/resources/book.cbz").unwrap_err();
    assert_eq!(error.code, HentaiErrorCode::RemoteAuthFailed);
    assert_eq!(error.message, "401 auth rejected");
}
