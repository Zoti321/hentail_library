use std::fs::File;
use std::io::Write;
use std::path::Path;

use hentai_core::sync::parser::{parse_epub, parse_file, parse_zip_archive};
use tempfile::TempDir;
use zip::write::SimpleFileOptions;
use zip::ZipWriter;

fn create_cbz_with_comic_info(path: &Path, comic_info_xml: &str) {
    let file = File::create(path).expect("create cbz");
    let mut zip = ZipWriter::new(file);
    let options = SimpleFileOptions::default();

    zip.start_file("ComicInfo.xml", options).expect("comicinfo");
    zip.write_all(comic_info_xml.as_bytes()).expect("write comicinfo");

    zip.start_file("01.jpg", options).expect("page");
    zip.write_all(b"fake-jpeg").expect("write page");
    zip.start_file("02.png", options).expect("page2");
    zip.write_all(b"fake-png").expect("write page2");
    zip.finish().expect("finish");
}

fn create_epub_with_metadata(
    path: &Path,
    title: &str,
    creators: &[&str],
    description: &str,
    date: &str,
) {
    let file = File::create(path).expect("create epub");
    let mut zip = ZipWriter::new(file);
    let options = SimpleFileOptions::default();

    zip.start_file("META-INF/container.xml", options)
        .expect("container");
    zip.write_all(
        br#"<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>"#,
    )
    .expect("write container");

    zip.start_file("OEBPS/content.opf", options).expect("opf");
    let creators_xml: String = creators
        .iter()
        .map(|c| format!("    <dc:creator>{c}</dc:creator>\n"))
        .collect();
    let opf = format!(
        r#"<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>{title}</dc:title>
{creators_xml}    <dc:description>{description}</dc:description>
    <dc:date>{date}</dc:date>
  </metadata>
</package>"#
    );
    zip.write_all(opf.as_bytes()).expect("write opf");

    zip.start_file("OEBPS/page01.jpg", options).expect("page");
    zip.write_all(b"fake-jpeg").expect("write page");
    zip.finish().expect("finish");
}

fn write_minimal_pdf_with_metadata(
    path: &Path,
    title: &str,
    author: &str,
    subject: &str,
    creation_date: &str,
) {
    let info_obj = format!(
        "<< /Title ({title}) /Author ({author}) /Subject ({subject}) /CreationDate ({creation_date}) >>"
    );
    let mut objects: Vec<String> = Vec::new();
    objects.push("<< /Type /Catalog /Pages 2 0 R >>".to_string());
    objects.push("<< /Type /Pages /Kids [3 0 R] /Count 1 >>".to_string());
    objects.push("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>".to_string());
    objects.push(info_obj);

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
        pdf.push_str(&format!("{:010} 00000 n \n", offset));
    }
    pdf.push_str(&format!(
        "trailer\n<< /Size {} /Root 1 0 R /Info 4 0 R >>\nstartxref\n{}\n%%EOF\n",
        objects.len() + 1,
        xref_offset
    ));
    std::fs::write(path, pdf).expect("write pdf");
}

fn utc_ms(year: i32, month: u32, day: u32) -> i64 {
    use std::time::{Duration, UNIX_EPOCH};
    let days_from_ce = days_from_civil(year, month, day).expect("valid date");
    let secs = days_from_ce as i64 * 86_400;
    UNIX_EPOCH
        .checked_add(Duration::from_secs(secs.max(0) as u64))
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
        .expect("ms")
}

fn days_from_civil(year: i32, month: u32, day: u32) -> Option<u32> {
    if !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    let y = if month <= 2 { year - 1 } else { year } as u32;
    let era = y / 400;
    let yoe = y - era * 400;
    let doy = (153 * (if month > 2 { month - 3 } else { month + 9 }) + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    Some(era * 146097 + doe - 719468)
}

fn pdfium_available() -> bool {
    let temp = match TempDir::new() {
        Ok(temp) => temp,
        Err(_) => return false,
    };
    let probe = temp.path().join("probe.pdf");
    write_minimal_pdf_with_metadata(&probe, "probe", "probe", "probe", "D:20240101000000");
    parse_file(&probe).is_ok()
}

// --- ComicInfo.xml ---

#[test]
fn parse_cbz_reads_comic_info_metadata() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("comic.cbz");
    create_cbz_with_comic_info(
        &path,
        r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>漫画标题</Title>
  <Writer>作者甲, 作者乙</Writer>
  <Penciller>画师丙</Penciller>
  <Summary>这是概要</Summary>
  <Year>2024</Year>
  <Translator>译者丁</Translator>
  <Month>6</Month>
  <Day>15</Day>
</ComicInfo>"#,
    );

    let parsed = parse_zip_archive(&path, "cbz")
        .expect("parse")
        .expect("resource");

    assert_eq!(parsed.title, "漫画标题");
    assert_eq!(
        parsed.authors,
        vec!["作者甲".to_string(), "作者乙".to_string(), "画师丙".to_string()]
    );
    assert_eq!(parsed.description.as_deref(), Some("这是概要"));
    assert_eq!(parsed.published_at, Some(utc_ms(2024, 6, 15)));
    assert_eq!(parsed.page_count, 2);
}

#[test]
fn parse_cbz_comic_info_title_overrides_filename() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("filename.cbz");
    create_cbz_with_comic_info(
        &path,
        r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>XML 标题</Title>
</ComicInfo>"#,
    );

    let parsed = parse_zip_archive(&path, "cbz")
        .expect("parse")
        .expect("resource");

    assert_eq!(parsed.title, "XML 标题");
}

#[test]
fn parse_cbz_without_comic_info_falls_back_to_filename() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("fallback.cbz");
    let file = File::create(&path).expect("create");
    let mut zip = ZipWriter::new(file);
    let options = SimpleFileOptions::default();
    zip.start_file("01.jpg", options).expect("page");
    zip.write_all(b"fake-jpeg").expect("write");
    zip.finish().expect("finish");

    let parsed = parse_zip_archive(&path, "cbz")
        .expect("parse")
        .expect("resource");

    assert_eq!(parsed.title, "fallback");
    assert!(parsed.authors.is_empty());
    assert!(parsed.description.is_none());
    assert!(parsed.published_at.is_none());
}

#[test]
fn parse_file_cbz_reads_comic_info_via_dispatch() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("dispatch.cbz");
    create_cbz_with_comic_info(
        &path,
        r#"<?xml version="1.0"?>
<ComicInfo><Title>分发测试</Title></ComicInfo>"#,
    );

    let parsed = parse_file(&path).expect("parse").expect("resource");
    assert_eq!(parsed.title, "分发测试");
}

// --- EPUB ---

#[test]
fn parse_epub_reads_full_metadata() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("full.epub");
    create_epub_with_metadata(
        &path,
        "完整元数据",
        &["作者A", "作者B"],
        "EPUB 概要",
        "2023-12-25T00:00:00Z",
    );

    let parsed = parse_epub(&path).expect("parse").expect("resource");

    assert_eq!(parsed.title, "完整元数据");
    assert_eq!(
        parsed.authors,
        vec!["作者A".to_string(), "作者B".to_string()]
    );
    assert_eq!(parsed.description.as_deref(), Some("EPUB 概要"));
    assert_eq!(parsed.published_at, Some(utc_ms(2023, 12, 25)));
    assert_eq!(parsed.page_count, 1);
}

#[test]
fn parse_epub_empty_title_falls_back_to_filename() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("no-title.epub");
    create_epub_with_metadata(&path, "   ", &[], "", "2020-01-01");
    let parsed = parse_epub(&path).expect("parse").expect("resource");
    assert_eq!(parsed.title, "no-title");
}

#[test]
fn parse_epub_creator_splits_separators_and_deduplicates() {
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("creators.epub");
    create_epub_with_metadata(
        &path,
        "作者测试",
        &["作者A, 作者B", "作者B; 作者C"],
        "",
        "2020-01-01",
    );

    let parsed = parse_epub(&path).expect("parse").expect("resource");

    assert_eq!(
        parsed.authors,
        vec!["作者A".to_string(), "作者B".to_string(), "作者C".to_string()]
    );
}

// --- PDF ---

#[test]
fn parse_pdf_reads_embedded_metadata() {
    if !pdfium_available() {
        eprintln!("SKIP parse_pdf_reads_embedded_metadata: pdfium 不可用");
        return;
    }
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("meta.pdf");
    write_minimal_pdf_with_metadata(
        &path,
        "PDF 标题",
        "作者甲, 作者乙",
        "PDF 概要",
        "D:20240615120000",
    );

    let parsed = parse_file(&path).expect("parse").expect("resource");

    assert_eq!(parsed.resource_type, "pdf");
    assert_eq!(parsed.title, "PDF 标题");
    assert_eq!(parsed.authors, vec!["作者甲".to_string(), "作者乙".to_string()]);
    assert_eq!(parsed.description.as_deref(), Some("PDF 概要"));
    assert_eq!(parsed.published_at, Some(utc_ms(2024, 6, 15)));
    assert!(parsed.page_count >= 1);
}

#[test]
fn parse_pdf_missing_metadata_fields_are_none() {
    if !pdfium_available() {
        eprintln!("SKIP parse_pdf_missing_metadata_fields_are_none: pdfium 不可用");
        return;
    }
    let temp = TempDir::new().expect("tempdir");
    let path = temp.path().join("bare.pdf");
    write_minimal_pdf_with_metadata(&path, "", "", "", "D:20240101000000");

    let parsed = parse_file(&path).expect("parse").expect("resource");

    assert_eq!(parsed.title, "bare");
    assert!(parsed.authors.is_empty());
    assert!(parsed.description.is_none());
    assert_eq!(parsed.published_at, Some(utc_ms(2024, 1, 1)));
}
