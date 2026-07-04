use std::path::Path;

use hentai_core::formats::read_rar_cover_bytes;
use hentai_core::sync::parser::{can_generate_thumbnail, parse_rar_archive};

const USER_RAR: &str =
    r"E:\涩涩\本子 (原图无水印)\クール系人妻OLネトラレ日記 ︱ 高冷系人妻OL的NTR日记.rar";

#[test]
fn rar_thumbnail_pipeline_includes_recognized_archives() {
    let path = Path::new(USER_RAR);
    if !path.exists() {
        eprintln!("skip: user fixture not present at {USER_RAR}");
        return;
    }

    let parsed = parse_rar_archive(path, "rar")
        .expect("parse rar")
        .expect("rar should be recognized as comic");
    assert!(parsed.page_count.unwrap_or(0) > 0, "rar should contain image pages");
    assert!(
        can_generate_thumbnail("rar"),
        "rar should be eligible for thumbnail generation"
    );
    assert!(
        can_generate_thumbnail("cbr"),
        "cbr should be eligible for thumbnail generation"
    );

    let cover = read_rar_cover_bytes(path)
        .expect("read rar cover")
        .expect("rar cover bytes should exist");
    assert!(!cover.is_empty(), "cover bytes should not be empty");
    let is_jpeg = cover.starts_with(&[0xFF, 0xD8, 0xFF]);
    let is_png = cover.starts_with(&[0x89, 0x50, 0x4E, 0x47]);
    let is_webp = cover.len() > 12 && &cover[8..12] == b"WEBP";
    assert!(
        is_jpeg || is_png || is_webp,
        "cover should look like a supported comic image"
    );
}
