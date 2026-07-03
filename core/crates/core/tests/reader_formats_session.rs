use std::fs;
use std::io::Write;

use hentai_core::{load_page_bytes, load_page_list, open_reader};

#[test]
fn sevenz_reader_lists_and_reads_image_pages() {
    let temp = tempfile::tempdir().expect("tempdir");
    let source_dir = temp.path().join("pages");
    fs::create_dir_all(&source_dir).expect("mkdir");
    fs::write(source_dir.join("001.png"), b"page-one").expect("write1");
    fs::write(source_dir.join("002.png"), b"page-two").expect("write2");

    let archive_path = temp.path().join("comic.cb7");
    sevenz_rust::compress_to_path(&source_dir, &archive_path).expect("compress");

    let path = archive_path.to_string_lossy().to_string();
    open_reader("sevenz-comic", &path, "cb7").expect("open");
    let list = load_page_list("sevenz-comic", &path, "cb7").expect("list");
    assert_eq!(list.page_count, 2);
    let page0 = load_page_bytes("sevenz-comic", &path, "cb7", 0).expect("page0");
    let page1 = load_page_bytes("sevenz-comic", &path, "cb7", 1).expect("page1");
    assert_eq!(page0, b"page-one");
    assert_eq!(page1, b"page-two");
}

#[test]
fn zip_reader_session_reuses_archive_for_multiple_pages() {
    let temp = tempfile::tempdir().expect("tempdir");
    let zip_path = temp.path().join("comic.cbz");
    {
        use std::fs::File;
        let file = File::create(&zip_path).expect("create");
        let mut zip = zip::ZipWriter::new(file);
        let options =
            zip::write::SimpleFileOptions::default().compression_method(zip::CompressionMethod::Stored);
        zip.start_file("001.jpg", options).expect("start");
        zip.write_all(b"page-one").expect("write");
        zip.start_file("002.jpg", options).expect("start2");
        zip.write_all(b"page-two").expect("write2");
        zip.finish().expect("finish");
    }
    let path = zip_path.to_string_lossy().to_string();
    open_reader("test-comic", &path, "cbz").expect("open");
    let list = load_page_list("test-comic", &path, "cbz").expect("list");
    assert_eq!(list.page_count, 2);
    let page0 = load_page_bytes("test-comic", &path, "cbz", 0).expect("page0");
    let page1 = load_page_bytes("test-comic", &path, "cbz", 1).expect("page1");
    assert_eq!(page0, b"page-one");
    assert_eq!(page1, b"page-two");
}
