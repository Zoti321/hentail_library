use std::io::{BufReader, Read};
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use zip::ZipArchive;

use crate::comic_id::normalize_path_for_key;
use crate::error::HentaiError;
use crate::formats::{
    open_pdf_backend, open_pdf_backend_kept, open_rar_backend, open_rar_backend_kept,
    open_sevenz_backend, open_sevenz_backend_kept, PdfBackend, RarBackend, SevenZBackend,
};
use crate::resource::{
    basename, extension_lower, is_comic_image_extension, local_access, ResourceAccess, ResourceKind,
    ResourceStream,
};
use crate::sync::remote::normalize_remote_location_key;
use crate::util::natural_sort::compare_filename_natural;

type StreamArchive = ZipArchive<BufReader<ResourceStream>>;

pub enum ReaderBackend {
    Dir(DirBackend),
    Zip(ZipBackend),
    Epub(EpubBackend),
    Rar(RarBackend),
    SevenZ(SevenZBackend),
    Pdf(PdfBackend),
}

pub struct DirBackend {
    pub files: Vec<PathBuf>,
}

pub struct ZipBackend {
    pub archive: Mutex<StreamArchive>,
    pub entry_indices: Vec<usize>,
}

pub struct EpubBackend {
    pub archive: Mutex<StreamArchive>,
    pub image_entries: Vec<usize>,
}

#[tracing::instrument(err, fields(resource_type, path))]
pub fn open_backend(path: &str, resource_type: &str) -> Result<ReaderBackend, HentaiError> {
    open_backend_with(local_access(), path, resource_type)
}

pub fn open_backend_with(
    access: &dyn ResourceAccess,
    path: &str,
    resource_type: &str,
) -> Result<ReaderBackend, HentaiError> {
    tracing::debug!(resource_type, "opening reader backend");
    let normalized = normalize_reader_location(path);
    if normalized.is_empty() {
        return Err(HentaiError::reader_kind_mismatch("path 为空"));
    }
    let Some(stat) = access.stat(&normalized)? else {
        return Err(HentaiError::reader_not_found(&normalized));
    };
    match resource_type {
        "dir" => {
            if stat.kind != ResourceKind::Dir {
                return Err(HentaiError::reader_kind_mismatch(format!(
                    "资源类型与路径不一致: path={normalized} expected=dir 期望目录"
                )));
            }
            Ok(ReaderBackend::Dir(open_dir(access, &normalized)?))
        }
        "zip" | "cbz" => {
            ensure_file_kind(stat.kind, &normalized, resource_type)?;
            ensure_extension(Path::new(&normalized), resource_type)?;
            Ok(ReaderBackend::Zip(open_zip(access, &normalized)?))
        }
        "epub" => {
            ensure_file_kind(stat.kind, &normalized, "epub")?;
            ensure_extension(Path::new(&normalized), "epub")?;
            Ok(ReaderBackend::Epub(open_epub(access, &normalized)?))
        }
        "cbr" | "rar" => {
            ensure_file_kind(stat.kind, &normalized, resource_type)?;
            ensure_extension(Path::new(&normalized), resource_type)?;
            open_path_bound_rar(access, &normalized)
        }
        "cb7" | "sevenz" => {
            ensure_file_kind(stat.kind, &normalized, resource_type)?;
            ensure_extension(Path::new(&normalized), resource_type)?;
            open_path_bound_sevenz(access, &normalized)
        }
        "pdf" => {
            ensure_file_kind(stat.kind, &normalized, "pdf")?;
            ensure_extension(Path::new(&normalized), "pdf")?;
            open_path_bound_pdf(access, &normalized)
        }
        other => Err(HentaiError::reader_unsupported_type(other)),
    }
}

fn ensure_file_kind(
    kind: ResourceKind,
    location: &str,
    resource_type: &str,
) -> Result<(), HentaiError> {
    if kind != ResourceKind::File {
        return Err(HentaiError::reader_kind_mismatch(format!(
            "资源类型与路径不一致: path={location} expected={resource_type} 期望文件"
        )));
    }
    Ok(())
}

fn ensure_extension(path: &Path, resource_type: &str) -> Result<(), HentaiError> {
    let ext = extension_lower(path);
    let expected = match resource_type {
        "zip" => ".zip",
        "cbz" => ".cbz",
        "epub" => ".epub",
        "cbr" => ".cbr",
        "rar" => ".rar",
        "cb7" => ".cb7",
        "sevenz" => ".7z",
        "pdf" => ".pdf",
        other => return Err(HentaiError::reader_unsupported_type(other)),
    };
    if ext != expected {
        return Err(HentaiError::reader_kind_mismatch(format!(
            "资源类型与路径不一致: path={} expected={resource_type} 扩展名推断为 {ext}",
            path.display()
        )));
    }
    Ok(())
}

fn open_dir(access: &dyn ResourceAccess, dir: &str) -> Result<DirBackend, HentaiError> {
    let mut files = Vec::new();
    for entry in access.list(dir)? {
        if entry.kind == ResourceKind::File
            && is_comic_image_extension(&extension_lower(Path::new(&entry.name)))
        {
            files.push(PathBuf::from(entry.location));
        }
    }
    files.sort_by(|a, b| compare_filename_natural(&basename(a), &basename(b)));
    if files.is_empty() {
        return Err(HentaiError::reader_invalid_content(format!(
            "目录内无漫画图片: {dir}"
        )));
    }
    Ok(DirBackend { files })
}

fn open_zip(access: &dyn ResourceAccess, location: &str) -> Result<ZipBackend, HentaiError> {
    let stream = access
        .open_stream(location)
        .map_err(|e| HentaiError::reader_not_found(e.message))?;
    let mut archive = ZipArchive::new(BufReader::new(stream))
        .map_err(|_| HentaiError::reader_invalid_content(format!("无法解码 ZIP: {location}")))?;
    let mut entries: Vec<(usize, String)> = Vec::new();
    for i in 0..archive.len() {
        let entry = archive
            .by_index(i)
            .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
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
            entries.push((i, name));
        }
    }
    entries.sort_by(|a, b| {
        compare_filename_natural(&basename(Path::new(&a.1)), &basename(Path::new(&b.1)))
    });
    let entry_indices: Vec<usize> = entries.into_iter().map(|(i, _)| i).collect();
    if entry_indices.is_empty() {
        return Err(HentaiError::reader_invalid_content(format!(
            "压缩包内无漫画图片: {location}"
        )));
    }
    Ok(ZipBackend {
        archive: Mutex::new(archive),
        entry_indices,
    })
}

fn open_epub(access: &dyn ResourceAccess, location: &str) -> Result<EpubBackend, HentaiError> {
    let stream = access
        .open_stream(location)
        .map_err(|e| HentaiError::reader_not_found(e.message))?;
    let mut archive = ZipArchive::new(BufReader::new(stream))
        .map_err(|_| HentaiError::reader_invalid_content(format!("无法解析 EPUB: {location}")))?;
    let image_entries = collect_epub_image_indices(&mut archive)?;
    if image_entries.is_empty() {
        return Err(HentaiError::reader_invalid_content(format!(
            "EPUB 内无图片: {location}"
        )));
    }
    Ok(EpubBackend {
        archive: Mutex::new(archive),
        image_entries,
    })
}

pub(crate) fn normalize_reader_location_for_session(path: &str) -> String {
    normalize_reader_location(path)
}

fn normalize_reader_location(path: &str) -> String {
    let trimmed = path.trim();
    let lower = trimmed.to_ascii_lowercase();
    if lower.starts_with("http://") || lower.starts_with("https://") {
        normalize_remote_location_key(trimmed)
    } else {
        normalize_path_for_key(trimmed)
    }
}

fn is_remote_location(location: &str) -> bool {
    let lower = location.to_ascii_lowercase();
    lower.starts_with("http://") || lower.starts_with("https://")
}

fn materialize_remote_file(
    access: &dyn ResourceAccess,
    location: &str,
) -> Result<tempfile::NamedTempFile, HentaiError> {
    let mut stream = access
        .open_stream(location)
        .map_err(|e| HentaiError::reader_not_found(e.message))?;
    let mut temp = tempfile::NamedTempFile::new()
        .map_err(|e| HentaiError::validation(format!("创建临时文件失败: {e}")))?;
    std::io::copy(&mut stream, &mut temp)
        .map_err(|e| HentaiError::remote_unreachable(format!("下载远程资源失败: {e}")))?;
    Ok(temp)
}

fn open_path_bound_pdf(
    access: &dyn ResourceAccess,
    location: &str,
) -> Result<ReaderBackend, HentaiError> {
    if is_remote_location(location) {
        let temp = materialize_remote_file(access, location)?;
        let path = temp.path().to_path_buf();
        let backend = open_pdf_backend_kept(&path, temp)?;
        Ok(ReaderBackend::Pdf(backend))
    } else {
        Ok(ReaderBackend::Pdf(open_pdf_backend(Path::new(location))?))
    }
}

fn open_path_bound_rar(
    access: &dyn ResourceAccess,
    location: &str,
) -> Result<ReaderBackend, HentaiError> {
    if is_remote_location(location) {
        let temp = materialize_remote_file(access, location)?;
        let path = temp.path().to_path_buf();
        let backend = open_rar_backend_kept(&path, temp)?;
        Ok(ReaderBackend::Rar(backend))
    } else {
        Ok(ReaderBackend::Rar(open_rar_backend(Path::new(location))?))
    }
}

fn open_path_bound_sevenz(
    access: &dyn ResourceAccess,
    location: &str,
) -> Result<ReaderBackend, HentaiError> {
    if is_remote_location(location) {
        let temp = materialize_remote_file(access, location)?;
        let path = temp.path().to_path_buf();
        let backend = open_sevenz_backend_kept(&path, temp)?;
        Ok(ReaderBackend::SevenZ(backend))
    } else {
        Ok(ReaderBackend::SevenZ(open_sevenz_backend(Path::new(
            location,
        ))?))
    }
}

fn collect_epub_image_indices(archive: &mut StreamArchive) -> Result<Vec<usize>, HentaiError> {
    let mut all_images: Vec<(usize, String)> = Vec::new();
    for i in 0..archive.len() {
        let entry = archive
            .by_index(i)
            .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
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
            all_images.push((i, name));
        }
    }
    all_images.sort_by(|a, b| {
        compare_filename_natural(&basename(Path::new(&a.1)), &basename(Path::new(&b.1)))
    });
    Ok(all_images.into_iter().map(|(i, _)| i).collect())
}

pub fn read_zip_page(backend: &ZipBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
    let idx = *backend.entry_indices.get(page_index).ok_or_else(|| {
        HentaiError::reader_invalid_content(format!(
            "页索引越界: index={page_index} count={}",
            backend.entry_indices.len()
        ))
    })?;
    let mut archive = backend
        .archive
        .lock()
        .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    let mut entry = archive
        .by_index(idx)
        .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    let mut buf = Vec::new();
    entry
        .read_to_end(&mut buf)
        .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    Ok(buf)
}

pub fn read_epub_page(backend: &EpubBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
    let idx = *backend.image_entries.get(page_index).ok_or_else(|| {
        HentaiError::reader_invalid_content(format!(
            "页索引越界: index={page_index} count={}",
            backend.image_entries.len()
        ))
    })?;
    let mut archive = backend
        .archive
        .lock()
        .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    let mut entry = archive
        .by_index(idx)
        .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    let mut buf = Vec::new();
    entry
        .read_to_end(&mut buf)
        .map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    Ok(buf)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::resource::FakeResourceAccess;
    use std::io::{Cursor, Write};
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    #[test]
    fn fake_open_stream_feeds_zip_backend() {
        let mut bytes = Vec::new();
        {
            let mut zip = ZipWriter::new(Cursor::new(&mut bytes));
            zip.start_file("01.jpg", SimpleFileOptions::default())
                .expect("start");
            zip.write_all(b"fake-jpeg").expect("write");
            zip.finish().expect("finish");
        }
        let mut fake = FakeResourceAccess::new();
        fake.insert_file("/lib/comic.cbz", bytes);

        let backend = open_backend_with(&fake, "/lib/comic.cbz", "cbz").expect("open");
        let ReaderBackend::Zip(zip) = backend else {
            panic!("expected zip backend");
        };
        let page = read_zip_page(&zip, 0).expect("page");
        assert_eq!(page, b"fake-jpeg");
    }
}
