use std::fs::File;
use std::io::{BufReader, Read};
use std::path::{Path, PathBuf};
use std::time::{Duration, UNIX_EPOCH};

use quick_xml::events::Event;
use quick_xml::Reader;
use zip::ZipArchive;

use crate::comic::now_ms;
use crate::formats::{count_pdf_pages, count_rar_images, count_sevenz_images, read_pdf_embedded_meta};
use crate::comic_id::comic_id_from_path;
use crate::error::HentaiError;

const COMIC_IMAGE_EXTENSIONS: &[&str] = &[".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"];

#[derive(Debug, Clone)]
pub struct ParsedResource {
    pub path: String,
    pub resource_type: String,
    pub title: String,
    pub authors: Vec<String>,
    pub page_count: i32,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub resource_size: i64,
}

pub fn comic_id_for_path(path: &str) -> String {
    comic_id_from_path(path)
}

pub fn can_generate_thumbnail(resource_type: &str) -> bool {
    matches!(
        resource_type,
        "dir" | "zip" | "cbz" | "epub" | "rar" | "cbr"
    )
}

pub fn is_comic_image_extension(ext: &str) -> bool {
    let lower = ext.to_lowercase();
    COMIC_IMAGE_EXTENSIONS.contains(&lower.as_str())
}

pub fn extension_lower(path: &Path) -> String {
    path.extension()
        .and_then(|e| e.to_str())
        .map(|e| format!(".{}", e.to_lowercase()))
        .unwrap_or_default()
}

pub fn basename(path: &Path) -> String {
    path.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_string()
}

pub fn basename_without_extension(path: &Path) -> String {
    path.file_stem()
        .and_then(|n| n.to_str())
        .unwrap_or("")
        .to_string()
}

pub fn read_resource_size(path: &Path, resource_type: &str) -> Result<Option<i64>, HentaiError> {
    if !path.exists() {
        return Ok(None);
    }
    if resource_type == "dir" {
        return compute_dir_image_files_size(path);
    }
    let meta = std::fs::metadata(path).map_err(|e| {
        HentaiError::validation(format!("stat 失败: {} ({})", path.display(), e))
    })?;
    Ok(Some(meta.len() as i64))
}

fn compute_dir_image_files_size(dir: &Path) -> Result<Option<i64>, HentaiError> {
    let mut total = 0i64;
    for entry in std::fs::read_dir(dir).map_err(|e| {
        HentaiError::validation(format!("读取目录失败: {} ({})", dir.display(), e))
    })? {
        let entry = entry.map_err(|e| HentaiError::validation(e.to_string()))?;
        let path = entry.path();
        if path.is_dir() {
            return Ok(None);
        }
        if path.is_file() && is_comic_image_extension(&extension_lower(&path)) {
            let meta = std::fs::metadata(&path).map_err(|e| HentaiError::validation(e.to_string()))?;
            total += meta.len() as i64;
        }
    }
    if total <= 0 {
        return Ok(None);
    }
    Ok(Some(total))
}

pub fn read_source_stat(path: &Path, resource_type: &str) -> Result<Option<(i64, i64)>, HentaiError> {
    if !path.exists() {
        return Ok(None);
    }
    let meta = std::fs::metadata(path).map_err(|e| {
        HentaiError::validation(format!("stat 失败: {} ({})", path.display(), e))
    })?;
    let modified_ms = meta
        .modified()
        .ok()
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0);
    let size = read_resource_size(path, resource_type)?.unwrap_or(0);
    Ok(Some((modified_ms, size)))
}

fn finalize_parsed(
    path: &Path,
    resource_type: &str,
    title: String,
    authors: Vec<String>,
    page_count: i32,
    description: Option<String>,
    published_at: Option<i64>,
) -> Result<Option<ParsedResource>, HentaiError> {
    if page_count <= 0 {
        return Ok(None);
    }
    let Some(resource_size) = read_resource_size(path, resource_type)? else {
        return Ok(None);
    };
    Ok(Some(ParsedResource {
        path: path.to_string_lossy().to_string(),
        resource_type: resource_type.to_string(),
        title,
        authors,
        page_count,
        description,
        published_at,
        resource_size,
    }))
}

pub fn parse_directory(dir: &Path) -> Result<Option<ParsedResource>, HentaiError> {
    if !dir.is_dir() {
        return Ok(None);
    }
    let mut files = Vec::new();
    for entry in std::fs::read_dir(dir).map_err(|e| {
        HentaiError::validation(format!("读取目录失败: {} ({})", dir.display(), e))
    })? {
        let entry = entry.map_err(|e| HentaiError::validation(e.to_string()))?;
        let path = entry.path();
        if path.is_dir() {
            return Ok(None);
        }
        if path.is_file() {
            files.push(path);
        }
    }
    if files.is_empty() {
        return Ok(None);
    }
    if !files.iter().all(|f| is_comic_image_extension(&extension_lower(f))) {
        return Ok(None);
    }
    finalize_parsed(
        dir,
        "dir",
        basename(dir),
        vec![],
        files.len() as i32,
        None,
        None,
    )
}

pub fn parse_zip_archive(file: &Path, resource_type: &str) -> Result<Option<ParsedResource>, HentaiError> {
    let f = File::open(file).map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut archive = match ZipArchive::new(BufReader::new(f)) {
        Ok(archive) => archive,
        Err(_) => return Ok(None),
    };
    let mut page_count = 0i32;
    let mut comic_info_xml: Option<String> = None;
    for i in 0..archive.len() {
        let mut entry = match archive.by_index(i) {
            Ok(entry) => entry,
            Err(_) => return Ok(None),
        };
        let name = entry.name().replace('\\', "/");
        if entry.is_dir() || name.ends_with('/') {
            continue;
        }
        if is_comic_info_entry(&name) {
            let mut buf = String::new();
            if entry.read_to_string(&mut buf).is_ok() {
                comic_info_xml = Some(buf);
            }
            continue;
        }
        let ext = Path::new(&name)
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| format!(".{}", e.to_lowercase()))
            .unwrap_or_default();
        if is_comic_image_extension(&ext) {
            page_count += 1;
        }
    }
    let meta = comic_info_xml
        .as_deref()
        .map(parse_comic_info_xml)
        .unwrap_or_default();
    let title = if meta.title.trim().is_empty() {
        basename_without_extension(file)
    } else {
        meta.title
    };
    finalize_parsed(
        file,
        resource_type,
        title,
        meta.authors,
        page_count,
        meta.description,
        meta.published_at,
    )
}

fn is_comic_info_entry(name: &str) -> bool {
    name.rsplit('/')
        .next()
        .is_some_and(|base| base.eq_ignore_ascii_case("ComicInfo.xml"))
}

#[derive(Debug, Default)]
struct ComicInfoMetadata {
    title: String,
    authors: Vec<String>,
    description: Option<String>,
    published_at: Option<i64>,
    year: Option<i32>,
    month: Option<u32>,
    day: Option<u32>,
}

fn parse_comic_info_xml(xml: &str) -> ComicInfoMetadata {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut buf = Vec::new();
    let mut meta = ComicInfoMetadata::default();
    let mut current_field: Option<&'static str> = None;

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let local = String::from_utf8_lossy(e.local_name().as_ref()).into_owned();
                current_field = match local.as_str() {
                    "Title" => Some("title"),
                    "Writer" | "Penciller" | "Colorist" | "Letterer" | "CoverArtist" => {
                        Some("author")
                    }
                    "Summary" => Some("summary"),
                    "Year" => Some("year"),
                    "Month" => Some("month"),
                    "Day" => Some("day"),
                    _ => None,
                };
            }
            Ok(Event::Text(e)) => {
                let text = e
                    .unescape()
                    .map(|s| s.into_owned())
                    .unwrap_or_default()
                    .trim()
                    .to_string();
                if text.is_empty() {
                    buf.clear();
                    continue;
                }
                match current_field {
                    Some("title") => meta.title = text,
                    Some("author") => extend_authors(&mut meta.authors, &text),
                    Some("summary") => meta.description = Some(text),
                    Some("year") => meta.year = text.parse().ok(),
                    Some("month") => meta.month = text.parse().ok(),
                    Some("day") => meta.day = text.parse().ok(),
                    _ => {}
                }
            }
            Ok(Event::End(_)) => current_field = None,
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
        buf.clear();
    }

    meta.published_at = comic_info_date_to_ms(meta.year, meta.month, meta.day);
    meta
}

fn extend_authors(authors: &mut Vec<String>, raw: &str) {
    for part in raw.split([',', ';']) {
        let name = part.trim();
        if name.is_empty() {
            continue;
        }
        if !authors.iter().any(|a| a == name) {
            authors.push(name.to_string());
        }
    }
}

fn comic_info_date_to_ms(year: Option<i32>, month: Option<u32>, day: Option<u32>) -> Option<i64> {
    let year = year?;
    let month = month?;
    let day = day?;
    date_to_utc_ms(year, month, day, 0, 0, 0)
}

pub fn parse_file(file: &Path) -> Result<Option<ParsedResource>, HentaiError> {
    let name = basename(file);
    if name.starts_with('.') {
        return Ok(None);
    }
    let ext = extension_lower(file);
    match ext.as_str() {
        ".zip" => parse_zip_archive(file, "zip"),
        ".cbz" => parse_zip_archive(file, "cbz"),
        ".epub" => parse_epub(file),
        ".cbr" => parse_rar_archive(file, "cbr"),
        ".rar" => parse_rar_archive(file, "rar"),
        ".cb7" => parse_sevenz_archive(file, "cb7"),
        ".7z" => parse_sevenz_archive(file, "sevenz"),
        ".pdf" => parse_pdf(file),
        _ => Ok(None),
    }
}

pub fn parse_rar_archive(file: &Path, resource_type: &str) -> Result<Option<ParsedResource>, HentaiError> {
    let page_count = count_rar_images(file)?;
    let Some(page_count) = page_count else {
        return Ok(None);
    };
    finalize_parsed(
        file,
        resource_type,
        basename_without_extension(file),
        vec![],
        page_count,
        None,
        None,
    )
}

pub fn parse_sevenz_archive(
    file: &Path,
    resource_type: &str,
) -> Result<Option<ParsedResource>, HentaiError> {
    let page_count = count_sevenz_images(file)?;
    let Some(page_count) = page_count else {
        return Ok(None);
    };
    finalize_parsed(
        file,
        resource_type,
        basename_without_extension(file),
        vec![],
        page_count,
        None,
        None,
    )
}

pub fn parse_pdf(file: &Path) -> Result<Option<ParsedResource>, HentaiError> {
    let page_count = count_pdf_pages(file)?;
    let Some(page_count) = page_count else {
        return Ok(None);
    };
    let (title, authors, description, published_at) =
        read_pdf_embedded_meta(file).unwrap_or((None, vec![], None, None));
    finalize_parsed(
        file,
        "pdf",
        title.unwrap_or_else(|| basename_without_extension(file)),
        authors,
        page_count,
        description,
        published_at,
    )
}

pub fn parse_epub(file: &Path) -> Result<Option<ParsedResource>, HentaiError> {
    let f = File::open(file).map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut archive = match ZipArchive::new(BufReader::new(f)) {
        Ok(a) => a,
        Err(_) => return Ok(None),
    };
    let opf_path = match find_opf_path(&mut archive) {
        Ok(p) => p,
        Err(_) => return Ok(None),
    };
    let opf_content = match read_zip_entry_string(&mut archive, &opf_path) {
        Ok(c) => c,
        Err(_) => return Ok(None),
    };
    let meta = parse_opf_metadata(&opf_content);
    let page_count = count_epub_images(&mut archive)?;
    let title = if meta.title.trim().is_empty() {
        basename_without_extension(file)
    } else {
        meta.title
    };
    finalize_parsed(
        file,
        "epub",
        title,
        meta.authors,
        page_count,
        meta.description,
        meta.published_at,
    )
}

fn find_opf_path(archive: &mut ZipArchive<BufReader<File>>) -> Result<String, HentaiError> {
    let container_xml = read_zip_entry_string(archive, "META-INF/container.xml")
        .map_err(|_| HentaiError::validation("epub container.xml 缺失".to_string()))?;
    extract_container_opf_path(&container_xml)
        .ok_or_else(|| HentaiError::validation("epub OPF 路径解析失败".to_string()))
}

fn extract_container_opf_path(container_xml: &str) -> Option<String> {
    let needle = "full-path=\"";
    let start = container_xml.find(needle)? + needle.len();
    let rest = &container_xml[start..];
    let end = rest.find('"')?;
    Some(rest[..end].replace('\\', "/"))
}

fn read_zip_entry_string(
    archive: &mut ZipArchive<BufReader<File>>,
    name: &str,
) -> Result<String, HentaiError> {
    let normalized = name.replace('\\', "/");
    let mut file = archive
        .by_name(&normalized)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut buf = String::new();
    file.read_to_string(&mut buf)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(buf)
}

struct OpfMetadata {
    title: String,
    authors: Vec<String>,
    description: Option<String>,
    published_at: Option<i64>,
}

fn parse_opf_metadata(opf: &str) -> OpfMetadata {
    let mut title = String::new();
    let mut authors = Vec::new();
    let mut description = None;
    let mut published_at = None;
    for line in opf.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("<dc:title") {
            if let Some(inner) = extract_xml_text(trimmed) {
                title = inner;
            }
        } else if trimmed.starts_with("<dc:creator") {
            if let Some(inner) = extract_xml_text(trimmed) {
                extend_authors(&mut authors, inner.trim());
            }
        } else if trimmed.starts_with("<dc:description") {
            if let Some(inner) = extract_xml_text(trimmed) {
                let t = inner.trim().to_string();
                if !t.is_empty() {
                    description = Some(t);
                }
            }
        } else if trimmed.starts_with("<dc:date") {
            if let Some(inner) = extract_xml_text(trimmed) {
                published_at = parse_iso_date_prefix_to_ms(inner.trim());
            }
        }
    }
    OpfMetadata {
        title,
        authors,
        description,
        published_at,
    }
}

fn parse_iso_date_prefix_to_ms(raw: &str) -> Option<i64> {
    if raw.len() < 10 {
        return None;
    }
    let date_part = &raw[0..10];
    let mut parts = date_part.split('-');
    let year: i32 = parts.next()?.parse().ok()?;
    let month: u32 = parts.next()?.parse().ok()?;
    let day: u32 = parts.next()?.parse().ok()?;
    date_to_utc_ms(year, month, day, 0, 0, 0)
}

fn date_to_utc_ms(
    year: i32,
    month: u32,
    day: u32,
    hour: u32,
    minute: u32,
    second: u32,
) -> Option<i64> {
    let days_from_ce = days_from_civil(year, month, day)?;
    let secs = days_from_ce as i64 * 86_400
        + hour as i64 * 3600
        + minute as i64 * 60
        + second as i64;
    UNIX_EPOCH
        .checked_add(Duration::from_secs(secs.max(0) as u64))
        .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
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

fn extract_xml_text(line: &str) -> Option<String> {
    let start = line.find('>')? + 1;
    let rest = &line[start..];
    let end = rest.find('<')?;
    Some(rest[..end].to_string())
}

fn count_epub_images(archive: &mut ZipArchive<BufReader<File>>) -> Result<i32, HentaiError> {
    let mut count = 0i32;
    for i in 0..archive.len() {
        let entry = archive
            .by_index(i)
            .map_err(|e| HentaiError::validation(e.to_string()))?;
        let name = entry.name().replace('\\', "/");
        if entry.is_dir() || name.ends_with('/') {
            continue;
        }
        let ext = Path::new(&name)
            .extension()
            .and_then(|e| e.to_str())
            .map(|e| format!(".{}", e.to_lowercase()))
            .unwrap_or_default();
        if is_comic_image_extension(&ext) {
            count += 1;
        }
    }
    Ok(count)
}

pub fn parsed_to_comic(parsed: &ParsedResource) -> crate::comic::ComicDto {
    let now = now_ms();
    crate::comic::ComicDto {
        comic_id: comic_id_for_path(&parsed.path),
        path: parsed.path.clone(),
        resource_type: parsed.resource_type.clone(),
        resource_size: parsed.resource_size,
        created_at: now,
        last_updated_at: now,
        title: crate::util::decode_basic_html_entities(&parsed.title),
        content_rating: "unknown".to_string(),
        page_count: parsed.page_count,
        description: parsed.description.clone(),
        published_at: parsed.published_at,
        last_read_time_ms: None,
        authors: parsed.authors.clone(),
        tags: vec![],
    }
}

pub fn normalize_roots(roots: &[String]) -> Vec<PathBuf> {
    roots
        .iter()
        .map(|r| r.trim())
        .filter(|r| !r.is_empty())
        .map(PathBuf::from)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::TempDir;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    #[test]
    fn can_generate_thumbnail_includes_rar_and_cbr() {
        assert!(can_generate_thumbnail("rar"));
        assert!(can_generate_thumbnail("cbr"));
    }

    #[test]
    fn parse_zip_archive_skips_invalid_zip() {
        let temp = TempDir::new().expect("tempdir");
        let path = temp.path().join("broken.zip");
        std::fs::write(&path, b"not-a-zip").expect("write");

        let parsed = parse_zip_archive(&path, "zip").expect("parse");

        assert!(parsed.is_none());
    }

    #[test]
    fn parse_zip_archive_counts_image_entries() {
        let temp = TempDir::new().expect("tempdir");
        let path = temp.path().join("comic.cbz");
        let file = File::create(&path).expect("create");
        let mut zip = ZipWriter::new(file);
        zip.start_file("01.jpg", SimpleFileOptions::default())
            .expect("start");
        zip.write_all(b"fake-jpeg").expect("write");
        zip.start_file("02.png", SimpleFileOptions::default())
            .expect("start");
        zip.write_all(b"fake-png").expect("write");
        zip.start_file("readme.txt", SimpleFileOptions::default())
            .expect("start");
        zip.write_all(b"notes").expect("write");
        zip.finish().expect("finish");

        let parsed = parse_zip_archive(&path, "cbz")
            .expect("parse")
            .expect("resource");

        assert_eq!(parsed.resource_type, "cbz");
        assert_eq!(parsed.page_count, 2);
        assert!(parsed.resource_size > 0);
    }

    #[test]
    fn parsed_to_comic_decodes_html_entities_in_title() {
        let comic = parsed_to_comic(&ParsedResource {
            path: "/library/Fate Heaven&#039;s Feel.cbz".to_string(),
            resource_type: "cbz".to_string(),
            title: "Fate╱Stay Night Heaven&#039;s Feel - 卷04".to_string(),
            authors: vec![],
            page_count: 10,
            description: None,
            published_at: None,
            resource_size: 1024,
        });
        assert_eq!(comic.title, "Fate╱Stay Night Heaven's Feel - 卷04");
    }

    #[test]
    fn parse_comic_info_xml_reads_standard_fields() {
        let meta = parse_comic_info_xml(
            r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>标题</Title>
  <Writer>作者A, 作者B</Writer>
  <Summary>概要</Summary>
  <Year>2022</Year>
  <Month>3</Month>
  <Day>9</Day>
</ComicInfo>"#,
        );
        assert_eq!(meta.title, "标题");
        assert_eq!(meta.authors, vec!["作者A", "作者B"]);
        assert_eq!(meta.description.as_deref(), Some("概要"));
        assert_eq!(meta.published_at, Some(date_to_utc_ms(2022, 3, 9, 0, 0, 0).unwrap()));
    }

    #[test]
    fn parse_comic_info_xml_year_only_keeps_published_at_empty() {
        let meta = parse_comic_info_xml(
            r#"<ComicInfo><Year>2020</Year></ComicInfo>"#,
        );
        assert_eq!(meta.published_at, None);
    }

    #[test]
    fn parse_comic_info_xml_deduplicates_authors() {
        let meta = parse_comic_info_xml(
            r#"<ComicInfo>
  <Writer>同人</Writer>
  <Penciller>同人</Penciller>
</ComicInfo>"#,
        );
        assert_eq!(meta.authors, vec!["同人"]);
    }

    #[test]
    fn parse_comic_info_xml_excludes_translator_from_authors() {
        let meta = parse_comic_info_xml(
            r#"<ComicInfo>
  <Writer>作者</Writer>
  <Translator>译者</Translator>
</ComicInfo>"#,
        );
        assert_eq!(meta.authors, vec!["作者"]);
    }

    #[test]
    fn parse_opf_metadata_splits_creator_separators_and_deduplicates() {
        let meta = parse_opf_metadata(
            r#"<?xml version="1.0"?>
<package>
  <metadata>
    <dc:creator>作者A, 作者B</dc:creator>
    <dc:creator>作者B; 作者C</dc:creator>
  </metadata>
</package>"#,
        );
        assert_eq!(
            meta.authors,
            vec!["作者A", "作者B", "作者C"]
        );
    }
}
