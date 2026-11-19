#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

use hentai_core::ReaderSessionRead;
mod common;

use std::fs;
use std::io::Write;

use hentai_core::{
    close_reader, init_db_at_path, load_page_bytes, load_page_list, load_reader_page, open_reader,
    HentaiErrorCode, ReaderPageCacheRequest, ReaderPageDto, ReaderPageRead,
};

#[test]
fn load_reader_page_cache_versions_follow_remote_resource_snapshots() {
    fn archive(page: &[u8]) -> Vec<u8> {
        let mut bytes = Vec::new();
        {
            let mut zip = zip::ZipWriter::new(std::io::Cursor::new(&mut bytes));
            zip.start_file("001.jpg", zip::write::SimpleFileOptions::default())
                .unwrap();
            zip.write_all(page).unwrap();
            zip.finish().unwrap();
        }
        bytes
    }

    fn cached_path(comic_id: &str) -> String {
        match load_reader_page(ReaderPageRead::capture(comic_id).unwrap(), 0).unwrap() {
            ReaderPageDto::FilePath { path } => path,
            ReaderPageDto::Bytes { .. } => panic!("versioned source should use disk cache"),
        }
    }

    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        hentai_core::runtime::block_on(init_db_at_path(&root.join("versioned.sqlite"))).unwrap();
        let location = "https://nas.example/versioned.cbz";
        let comic_id = "remote-cache-version";
        let mut first = hentai_core::resource::FakeResourceAccess::new();
        first.insert_file(location, archive(b"page-A"));
        first.set_modified_ms(location, 1000);
        hentai_core::open_reader_with(&first, comic_id, location, "cbz").unwrap();
        let first_path = cached_path(comic_id);
        assert_eq!(fs::read(&first_path).unwrap(), b"page-A");

        let mut replacement = hentai_core::resource::FakeResourceAccess::new();
        replacement.insert_file(location, archive(b"replacement-page-B"));
        replacement.set_modified_ms(location, 2000);
        let mut unavailable = replacement.clone();
        unavailable.set_unreachable("active session reuse must not perform source I/O");
        hentai_core::open_reader_with(&unavailable, comic_id, location, "cbz").unwrap();
        assert_eq!(cached_path(comic_id), first_path);
        close_reader(comic_id);

        hentai_core::open_reader_with(&replacement, comic_id, location, "cbz").unwrap();
        let second_path = cached_path(comic_id);
        assert_ne!(first_path, second_path);
        assert_eq!(fs::read(&second_path).unwrap(), b"replacement-page-B");
        assert_eq!(fs::read(&first_path).unwrap(), b"page-A");
        close_reader(comic_id);
        hentai_core::open_reader_with(&replacement, comic_id, location, "cbz").unwrap();
        assert_eq!(cached_path(comic_id), second_path);
        close_reader(comic_id);
    });
}

#[test]
fn load_reader_page_preserves_archive_cache_lifetimes() {
    common::with_global_db(|| {
        // Retain fixtures for manual cleanup; recursive removal is prohibited.
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let db_path = temp.join("test.sqlite");
        hentai_core::runtime::block_on(init_db_at_path(&db_path)).expect("init db");

        let zip_path = temp.join("comic.cbz");
        {
            use std::fs::File;
            let file = File::create(&zip_path).expect("create");
            let mut zip = zip::ZipWriter::new(file);
            let options = zip::write::SimpleFileOptions::default()
                .compression_method(zip::CompressionMethod::Stored);
            zip.start_file("001.jpg", options).expect("start");
            zip.write_all(b"\xFF\xD8\xFFpage-one").expect("write");
            zip.finish().expect("finish");
        }

        let path = zip_path.to_string_lossy().to_string();
        open_reader("cache-comic", &path, "cbz").expect("open");
        let page = ReaderPageRead::capture("cache-comic")
            .and_then(|read| load_reader_page(read, 0))
            .expect("load");
        match page {
            ReaderPageDto::FilePath { path: cached } => {
                assert!(std::path::Path::new(&cached).exists());
                let second = ReaderPageRead::capture("cache-comic")
                    .and_then(|read| load_reader_page(read, 0))
                    .expect("reload");
                match second {
                    ReaderPageDto::FilePath { path: cached_again } => {
                        assert_eq!(cached, cached_again);
                    }
                    ReaderPageDto::Bytes { .. } => {
                        panic!("expected cached file path on second load")
                    }
                }
            }
            ReaderPageDto::Bytes { .. } => panic!("expected cached file path on first load"),
        }
        let before_clear = ReaderPageRead::capture("cache-comic").unwrap();
        let _clear = ReaderPageCacheRequest::begin_clear("cache-comic");
        let after_clear = ReaderPageRead::capture("cache-comic").unwrap();
        for read in [before_clear, after_clear] {
            let page = load_reader_page(read, 0).expect("load during clear");
            match page {
                ReaderPageDto::Bytes { data } => assert_eq!(data, b"\xFF\xD8\xFFpage-one"),
                ReaderPageDto::FilePath { .. } => {
                    panic!("pending clear must not return cache path")
                }
            }
        }
        let _prefetch = ReaderPageCacheRequest::begin("cache-comic");
        let page = ReaderPageRead::capture("cache-comic")
            .and_then(|read| load_reader_page(read, 0))
            .expect("load after superseding clear");
        assert!(matches!(page, ReaderPageDto::FilePath { .. }));
        let obsolete = ReaderPageRead::capture("cache-comic").unwrap();
        close_reader("cache-comic");
        open_reader("cache-comic", &path, "cbz").unwrap();
        let error = load_reader_page(obsolete, 0).unwrap_err();
        assert_eq!(error.code, HentaiErrorCode::ReaderSessionNotOpen);
        let current = ReaderPageRead::capture("cache-comic").unwrap();
        assert!(matches!(
            load_reader_page(current, 0).unwrap(),
            ReaderPageDto::FilePath { .. }
        ));
        close_reader("cache-comic");
    });
}

#[test]
fn pdf_reader_lists_and_reads_first_page_as_jpeg() {
    common::with_global_db(|| {
        let temp = tempfile::tempdir().expect("tempdir");
        let pdf_path = temp.path().join("comic.pdf");
        write_minimal_one_page_pdf(&pdf_path);

        // 无 pdfium 的环境（含尚未配好的移动端交叉环境）跳过，避免误红。
        if open_reader("pdf-probe", &pdf_path.to_string_lossy(), "pdf").is_err() {
            eprintln!("SKIP pdf_reader_lists_and_reads_first_page_as_jpeg: pdfium 不可用");
            return;
        }
        close_reader("pdf-probe");

        let path = pdf_path.to_string_lossy().to_string();
        open_reader("pdf-comic", &path, "pdf").expect("open pdf");
        let list =
            load_page_list(&ReaderSessionRead::capture("pdf-comic").expect("capture session"))
                .expect("list");
        assert_eq!(list.page_count, 1);
        let page0 = load_page_bytes(
            &ReaderSessionRead::capture("pdf-comic").expect("capture session"),
            0,
        )
        .expect("page0");
        assert!(
            page0.len() >= 3 && page0[0] == 0xFF && page0[1] == 0xD8 && page0[2] == 0xFF,
            "expected JPEG SOI marker, got {} bytes",
            page0.len()
        );
    });
}

#[test]
fn pdf_reader_page_out_of_bounds_returns_error() {
    common::with_global_db(|| {
        let temp = tempfile::tempdir().expect("tempdir");
        let pdf_path = temp.path().join("comic.pdf");
        write_minimal_one_page_pdf(&pdf_path);
        let path = pdf_path.to_string_lossy().to_string();

        if open_reader("pdf-oob-probe", &path, "pdf").is_err() {
            eprintln!("SKIP pdf_reader_page_out_of_bounds_returns_error: pdfium 不可用");
            return;
        }
        close_reader("pdf-oob-probe");

        open_reader("pdf-oob", &path, "pdf").expect("open pdf");
        let err = load_page_bytes(
            &ReaderSessionRead::capture("pdf-oob").expect("capture session"),
            1,
        )
        .expect_err("index 1 of 1");
        assert_eq!(err.code, HentaiErrorCode::ReaderInvalidContent);
        close_reader("pdf-oob");
    });
}

fn write_minimal_one_page_pdf(path: &std::path::Path) {
    let objects: Vec<&str> = vec![
        "<< /Type /Catalog /Pages 2 0 R >>",
        "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>",
    ];
    let mut pdf = String::from("%PDF-1.4\n");
    let mut offsets: Vec<usize> = vec![0];
    for (i, obj) in objects.iter().enumerate() {
        offsets.push(pdf.len());
        pdf.push_str(&format!("{} 0 obj\n{}\nendobj\n", i + 1, obj));
    }
    let xref_offset = pdf.len();
    pdf.push_str("xref\n");
    pdf.push_str(&format!("0 {}\n", objects.len() + 1));
    pdf.push_str("0000000000 65535 f \n");
    for offset in offsets.iter().skip(1) {
        pdf.push_str(&format!("{offset:010} 00000 n \n"));
    }
    pdf.push_str(&format!(
        "trailer\n<< /Size {} /Root 1 0 R >>\nstartxref\n{}\n%%EOF\n",
        objects.len() + 1,
        xref_offset
    ));
    fs::write(path, pdf).expect("write pdf");
}

#[test]
fn sevenz_reader_lists_and_reads_image_pages() {
    common::with_global_db(|| {
        let temp = tempfile::tempdir().expect("tempdir");
        let source_dir = temp.path().join("pages");
        fs::create_dir_all(&source_dir).expect("mkdir");
        fs::write(source_dir.join("001.png"), b"page-one").expect("write1");
        fs::write(source_dir.join("002.png"), b"page-two").expect("write2");

        let archive_path = temp.path().join("comic.cb7");
        sevenz_rust::compress_to_path(&source_dir, &archive_path).expect("compress");

        let path = archive_path.to_string_lossy().to_string();
        open_reader("sevenz-comic", &path, "cb7").expect("open");
        let list =
            load_page_list(&ReaderSessionRead::capture("sevenz-comic").expect("capture session"))
                .expect("list");
        assert_eq!(list.page_count, 2);
        let page0 = load_page_bytes(
            &ReaderSessionRead::capture("sevenz-comic").expect("capture session"),
            0,
        )
        .expect("page0");
        let page1 = load_page_bytes(
            &ReaderSessionRead::capture("sevenz-comic").expect("capture session"),
            1,
        )
        .expect("page1");
        assert_eq!(page0, b"page-one");
        assert_eq!(page1, b"page-two");
    });
}

#[test]
fn zip_reader_session_reuses_archive_for_multiple_pages() {
    common::with_global_db(|| {
        let temp = tempfile::tempdir().expect("tempdir");
        let zip_path = temp.path().join("comic.cbz");
        {
            use std::fs::File;
            let file = File::create(&zip_path).expect("create");
            let mut zip = zip::ZipWriter::new(file);
            let options = zip::write::SimpleFileOptions::default()
                .compression_method(zip::CompressionMethod::Stored);
            zip.start_file("001.jpg", options).expect("start");
            zip.write_all(b"page-one").expect("write");
            zip.start_file("002.jpg", options).expect("start2");
            zip.write_all(b"page-two").expect("write2");
            zip.finish().expect("finish");
        }
        let path = zip_path.to_string_lossy().to_string();
        open_reader("test-comic", &path, "cbz").expect("open");
        let list =
            load_page_list(&ReaderSessionRead::capture("test-comic").expect("capture session"))
                .expect("list");
        assert_eq!(list.page_count, 2);
        let page0 = load_page_bytes(
            &ReaderSessionRead::capture("test-comic").expect("capture session"),
            0,
        )
        .expect("page0");
        let page1 = load_page_bytes(
            &ReaderSessionRead::capture("test-comic").expect("capture session"),
            1,
        )
        .expect("page1");
        assert_eq!(page0, b"page-one");
        assert_eq!(page1, b"page-two");
    });
}

#[test]
fn load_reader_page_without_open_returns_session_not_open() {
    let err = ReaderPageRead::capture("no-session")
        .and_then(|read| load_reader_page(read, 0))
        .expect_err("not open");
    assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
}

#[test]
fn close_reader_then_load_reader_page_returns_session_not_open() {
    common::with_global_db(|| {
        let temp = tempfile::tempdir().expect("tempdir").keep();
        let db_path = temp.join("test.sqlite");
        hentai_core::runtime::block_on(init_db_at_path(&db_path)).expect("init db");

        let zip_path = temp.join("comic.cbz");
        {
            use std::fs::File;
            let file = File::create(&zip_path).expect("create");
            let mut zip = zip::ZipWriter::new(file);
            let options = zip::write::SimpleFileOptions::default()
                .compression_method(zip::CompressionMethod::Stored);
            zip.start_file("001.jpg", options).expect("start");
            zip.write_all(b"\xFF\xD8\xFFpage-one").expect("write");
            zip.finish().expect("finish");
        }
        let path = zip_path.to_string_lossy().to_string();
        open_reader("closed-comic", &path, "cbz").expect("open");
        ReaderPageRead::capture("closed-comic")
            .and_then(|read| load_reader_page(read, 0))
            .expect("load while open");
        close_reader("closed-comic");
        let err = ReaderPageRead::capture("closed-comic")
            .and_then(|read| load_reader_page(read, 0))
            .expect_err("after close");
        assert_eq!(err.code, HentaiErrorCode::ReaderSessionNotOpen);
    });
}
