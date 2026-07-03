use std::fs::File;
use std::io::{BufReader, Read};
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use zip::ZipArchive;

use crate::comic_id::normalize_path_for_key;
use crate::error::HentaiError;
use crate::formats::{
    open_pdf_backend, open_rar_backend, open_sevenz_backend, PdfBackend, RarBackend, SevenZBackend,
};
use crate::sync::parser::{basename, extension_lower, is_comic_image_extension};
use crate::util::natural_sort::compare_filename_natural;

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
    pub archive: Mutex<ZipArchive<BufReader<File>>>,
    pub entry_indices: Vec<usize>,
}

pub struct EpubBackend {
    pub archive: Mutex<ZipArchive<BufReader<File>>>,
    pub image_entries: Vec<usize>,
}

pub fn open_backend(path: &str, resource_type: &str) -> Result<ReaderBackend, HentaiError> {
  let normalized = normalize_path_for_key(path);
  if normalized.is_empty() {
    return Err(HentaiError::reader_kind_mismatch("path 为空"));
  }
  let fs_path = PathBuf::from(&normalized);
  if !fs_path.exists() {
    return Err(HentaiError::reader_not_found(&normalized));
  }
  match resource_type {
    "dir" => {
      if !fs_path.is_dir() {
        return Err(HentaiError::reader_kind_mismatch(format!(
          "资源类型与路径不一致: path={normalized} expected=dir 期望目录"
        )));
      }
      Ok(ReaderBackend::Dir(open_dir(&fs_path)?))
    }
    "zip" | "cbz" => {
      if !fs_path.is_file() {
        return Err(HentaiError::reader_kind_mismatch(format!(
          "资源类型与路径不一致: path={normalized} expected={resource_type} 期望文件"
        )));
      }
      ensure_extension(&fs_path, resource_type)?;
      Ok(ReaderBackend::Zip(open_zip(&fs_path)?))
    }
    "epub" => {
      if !fs_path.is_file() {
        return Err(HentaiError::reader_kind_mismatch(format!(
          "资源类型与路径不一致: path={normalized} expected=epub 期望文件"
        )));
      }
      ensure_extension(&fs_path, "epub")?;
      Ok(ReaderBackend::Epub(open_epub(&fs_path)?))
    }
    "cbr" | "rar" => {
      if !fs_path.is_file() {
        return Err(HentaiError::reader_kind_mismatch(format!(
          "资源类型与路径不一致: path={normalized} expected={resource_type} 期望文件"
        )));
      }
      ensure_extension(&fs_path, resource_type)?;
      Ok(ReaderBackend::Rar(open_rar_backend(&fs_path)?))
    }
    "cb7" | "sevenz" => {
      if !fs_path.is_file() {
        return Err(HentaiError::reader_kind_mismatch(format!(
          "资源类型与路径不一致: path={normalized} expected={resource_type} 期望文件"
        )));
      }
      ensure_extension(&fs_path, resource_type)?;
      Ok(ReaderBackend::SevenZ(open_sevenz_backend(&fs_path)?))
    }
    "pdf" => {
      if !fs_path.is_file() {
        return Err(HentaiError::reader_kind_mismatch(format!(
          "资源类型与路径不一致: path={normalized} expected=pdf 期望文件"
        )));
      }
      ensure_extension(&fs_path, "pdf")?;
      Ok(ReaderBackend::Pdf(open_pdf_backend(&fs_path)?))
    }
    other => Err(HentaiError::reader_unsupported_type(other)),
  }
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

fn open_dir(dir: &Path) -> Result<DirBackend, HentaiError> {
  let mut files = Vec::new();
  for entry in std::fs::read_dir(dir).map_err(|e| HentaiError::reader_invalid_content(e.to_string()))? {
    let entry = entry.map_err(|e| HentaiError::reader_invalid_content(e.to_string()))?;
    let path = entry.path();
    if path.is_file() && is_comic_image_extension(&extension_lower(&path)) {
      files.push(path);
    }
  }
  files.sort_by(|a, b| {
    compare_filename_natural(&basename(a), &basename(b))
  });
  if files.is_empty() {
    return Err(HentaiError::reader_invalid_content(format!(
      "目录内无漫画图片: {}",
      dir.display()
    )));
  }
  Ok(DirBackend { files })
}

fn open_zip(file: &Path) -> Result<ZipBackend, HentaiError> {
  let f = File::open(file).map_err(|e| HentaiError::reader_not_found(e.to_string()))?;
  let mut archive = ZipArchive::new(BufReader::new(f))
    .map_err(|_| HentaiError::reader_invalid_content(format!("无法解码 ZIP: {}", file.display())))?;
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
    compare_filename_natural(
      &basename(Path::new(&a.1)),
      &basename(Path::new(&b.1)),
    )
  });
  let entry_indices: Vec<usize> = entries.into_iter().map(|(i, _)| i).collect();
  if entry_indices.is_empty() {
    return Err(HentaiError::reader_invalid_content(format!(
      "压缩包内无漫画图片: {}",
      file.display()
    )));
  }
  Ok(ZipBackend {
    archive: Mutex::new(archive),
    entry_indices,
  })
}

fn open_epub(file: &Path) -> Result<EpubBackend, HentaiError> {
  let f = File::open(file).map_err(|e| HentaiError::reader_not_found(e.to_string()))?;
  let mut archive = ZipArchive::new(BufReader::new(f))
    .map_err(|_| HentaiError::reader_invalid_content(format!("无法解析 EPUB: {}", file.display())))?;
  let image_entries = collect_epub_image_indices(&mut archive)?;
  if image_entries.is_empty() {
    return Err(HentaiError::reader_invalid_content(format!(
      "EPUB 内无图片: {}",
      file.display()
    )));
  }
  Ok(EpubBackend {
    archive: Mutex::new(archive),
    image_entries,
  })
}

fn collect_epub_image_indices(
  archive: &mut ZipArchive<BufReader<File>>,
) -> Result<Vec<usize>, HentaiError> {
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
    compare_filename_natural(
      &basename(Path::new(&a.1)),
      &basename(Path::new(&b.1)),
    )
  });
  Ok(all_images.into_iter().map(|(i, _)| i).collect())
}

pub fn read_zip_page(backend: &ZipBackend, page_index: usize) -> Result<Vec<u8>, HentaiError> {
  let idx = *backend
    .entry_indices
    .get(page_index)
    .ok_or_else(|| {
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
  let idx = *backend
    .image_entries
    .get(page_index)
    .ok_or_else(|| {
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
