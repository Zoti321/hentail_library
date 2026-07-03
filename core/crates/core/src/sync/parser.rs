use std::fs::File;
use std::io::{BufReader, Read};
use std::path::{Path, PathBuf};

use zip::ZipArchive;

use crate::formats::{count_pdf_pages, count_rar_images, count_sevenz_images};
use crate::comic_id::comic_id_from_path;
use crate::error::HentaiError;

const COMIC_IMAGE_EXTENSIONS: &[&str] = &[".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"];

#[derive(Debug, Clone)]
pub struct ParsedResource {
    pub path: String,
    pub resource_type: String,
    pub title: String,
    pub authors: Vec<String>,
    pub page_count: Option<i32>,
}

pub fn comic_id_for_path(path: &str) -> String {
    comic_id_from_path(path)
}

pub fn can_generate_thumbnail(resource_type: &str) -> bool {
    matches!(resource_type, "dir" | "zip" | "cbz" | "epub")
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
        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0);
    let size = meta.len() as i64;
    let _ = resource_type;
    Ok(Some((modified_ms, size)))
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
    Ok(Some(ParsedResource {
        path: dir.to_string_lossy().to_string(),
        resource_type: "dir".to_string(),
        title: basename(dir),
        authors: vec![],
        page_count: Some(files.len() as i32),
    }))
}

pub fn parse_zip_archive(file: &Path, resource_type: &str) -> Result<Option<ParsedResource>, HentaiError> {
    let f = File::open(file).map_err(|e| HentaiError::validation(e.to_string()))?;
    let mut archive = match ZipArchive::new(BufReader::new(f)) {
        Ok(archive) => archive,
        Err(_) => return Ok(None),
    };
    let mut page_count = 0i32;
    for i in 0..archive.len() {
        let entry = match archive.by_index(i) {
            Ok(entry) => entry,
            Err(_) => return Ok(None),
        };
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
            page_count += 1;
        }
    }
    if page_count == 0 {
        return Ok(None);
    }
    Ok(Some(ParsedResource {
        path: file.to_string_lossy().to_string(),
        resource_type: resource_type.to_string(),
        title: basename_without_extension(file),
        authors: vec![],
        page_count: Some(page_count),
    }))
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
    Ok(Some(ParsedResource {
        path: file.to_string_lossy().to_string(),
        resource_type: resource_type.to_string(),
        title: basename_without_extension(file),
        authors: vec![],
        page_count: Some(page_count),
    }))
}

pub fn parse_sevenz_archive(
    file: &Path,
    resource_type: &str,
) -> Result<Option<ParsedResource>, HentaiError> {
    let page_count = count_sevenz_images(file)?;
    let Some(page_count) = page_count else {
        return Ok(None);
    };
    Ok(Some(ParsedResource {
        path: file.to_string_lossy().to_string(),
        resource_type: resource_type.to_string(),
        title: basename_without_extension(file),
        authors: vec![],
        page_count: Some(page_count),
    }))
}

pub fn parse_pdf(file: &Path) -> Result<Option<ParsedResource>, HentaiError> {
    let page_count = count_pdf_pages(file)?;
    let Some(page_count) = page_count else {
        return Ok(None);
    };
    Ok(Some(ParsedResource {
        path: file.to_string_lossy().to_string(),
        resource_type: "pdf".to_string(),
        title: basename_without_extension(file),
        authors: vec![],
        page_count: Some(page_count),
    }))
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
    let (title, authors) = parse_opf_metadata(&opf_content);
    let page_count = count_epub_images(&mut archive)?;
    if page_count == 0 {
        return Ok(None);
    }
    let title = if title.trim().is_empty() {
        basename_without_extension(file)
    } else {
        title
    };
    Ok(Some(ParsedResource {
        path: file.to_string_lossy().to_string(),
        resource_type: "epub".to_string(),
        title,
        authors,
        page_count: Some(page_count),
    }))
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

fn parse_opf_metadata(opf: &str) -> (String, Vec<String>) {
    let mut title = String::new();
    let mut authors = Vec::new();
    for line in opf.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("<dc:title") {
            if let Some(inner) = extract_xml_text(trimmed) {
                title = inner;
            }
        } else if trimmed.starts_with("<dc:creator") {
            if let Some(inner) = extract_xml_text(trimmed) {
                let t = inner.trim().to_string();
                if !t.is_empty() {
                    authors.push(t);
                }
            }
        }
    }
    (title, authors)
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
    crate::comic::ComicDto {
        comic_id: comic_id_for_path(&parsed.path),
        path: parsed.path.clone(),
        resource_type: parsed.resource_type.clone(),
        title: parsed.title.clone(),
        content_rating: "unknown".to_string(),
        page_count: parsed.page_count,
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
        assert_eq!(parsed.page_count, Some(2));
    }
}
