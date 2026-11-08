//! EPUB package helpers: OPF spine reading order for comic page images.

use std::collections::HashMap;
use std::io::{Read, Seek};
use std::path::Path;

use zip::ZipArchive;

use crate::error::HentaiError;

use super::media::is_comic_image_extension;

/// Resolve comic page image entry names in OPF spine order.
///
/// Fixed-layout / manga EPUBs usually put one XHTML (or image) per spine item;
/// filenames are often content hashes, so ZIP / natural filename order is wrong.
/// Returns empty when the package has no usable spine images (caller may fall back).
pub fn collect_epub_spine_image_names<R: Read + Seek>(
    archive: &mut ZipArchive<R>,
) -> Result<Vec<String>, HentaiError> {
    let Ok(opf_path) = find_opf_path(archive) else {
        return Ok(Vec::new());
    };
    let Ok(opf) = read_zip_entry_string(archive, &opf_path) else {
        return Ok(Vec::new());
    };
    let opf_dir = parent_dir(&opf_path);
    let Some((manifest, spine)) = parse_opf_manifest_and_spine(&opf) else {
        return Ok(Vec::new());
    };

    let mut names = Vec::with_capacity(spine.len());
    let mut seen = std::collections::HashSet::new();
    for idref in spine {
        let Some(item) = manifest.get(&idref) else {
            continue;
        };
        let href_path = join_opf_href(&opf_dir, &item.href);
        let resolved = if is_image_media(&item.media_type)
            || is_comic_image_extension(&extension_of(&href_path))
        {
            Some(href_path)
        } else {
            first_image_from_xhtml(archive, &href_path)
        };
        let Some(image_path) = resolved else {
            continue;
        };
        let Some(entry_name) = resolve_archive_name(archive, &image_path) else {
            continue;
        };
        if seen.insert(entry_name.clone()) {
            names.push(entry_name);
        }
    }
    Ok(names)
}

fn find_opf_path<R: Read + Seek>(archive: &mut ZipArchive<R>) -> Result<String, HentaiError> {
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
    Some(normalize_zip_path(&rest[..end]))
}

fn read_zip_entry_string<R: Read + Seek>(
    archive: &mut ZipArchive<R>,
    name: &str,
) -> Result<String, HentaiError> {
    let normalized = normalize_zip_path(name);
    let mut buf = String::new();
    if let Ok(mut file) = archive.by_name(&normalized) {
        file.read_to_string(&mut buf)
            .map_err(|e| HentaiError::validation(e.to_string()))?;
        return Ok(buf);
    }
    let mut file = archive
        .by_name(name)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    file.read_to_string(&mut buf)
        .map_err(|e| HentaiError::validation(e.to_string()))?;
    Ok(buf)
}

struct ManifestItem {
    href: String,
    media_type: String,
}

fn parse_opf_manifest_and_spine(
    opf: &str,
) -> Option<(HashMap<String, ManifestItem>, Vec<String>)> {
    let mut manifest = HashMap::new();
    let mut spine = Vec::new();

    for raw in opf.split('<').skip(1) {
        let line = raw.trim_start();
        if line.starts_with("item ") || line.starts_with("item\t") || line.starts_with("item\n") {
            let attrs = attribute_map(line);
            let Some(id) = attrs.get("id").cloned() else {
                continue;
            };
            let Some(href_raw) = attrs.get("href") else {
                continue;
            };
            let href = normalize_zip_path(href_raw);
            let media_type = attrs
                .get("media-type")
                .cloned()
                .unwrap_or_default();
            manifest.insert(
                id,
                ManifestItem {
                    href,
                    media_type,
                },
            );
        } else if line.starts_with("itemref ")
            || line.starts_with("itemref\t")
            || line.starts_with("itemref\n")
        {
            let attrs = attribute_map(line);
            if let Some(idref) = attrs.get("idref") {
                spine.push(idref.clone());
            }
        }
    }

    if spine.is_empty() {
        None
    } else {
        Some((manifest, spine))
    }
}

fn attribute_map(tag_open: &str) -> HashMap<String, String> {
    let mut out = HashMap::new();
    let bytes = tag_open.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        while i < bytes.len() && !is_name_start(bytes[i]) {
            if bytes[i] == b'>' || bytes[i] == b'/' {
                return out;
            }
            i += 1;
        }
        if i >= bytes.len() {
            break;
        }
        let name_start = i;
        i += 1;
        while i < bytes.len() && is_name_char(bytes[i]) {
            i += 1;
        }
        let name = &tag_open[name_start..i];
        while i < bytes.len() && bytes[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= bytes.len() || bytes[i] != b'=' {
            continue;
        }
        i += 1;
        while i < bytes.len() && bytes[i].is_ascii_whitespace() {
            i += 1;
        }
        if i >= bytes.len() {
            break;
        }
        let quote = bytes[i];
        if quote != b'"' && quote != b'\'' {
            continue;
        }
        i += 1;
        let value_start = i;
        while i < bytes.len() && bytes[i] != quote {
            i += 1;
        }
        if i >= bytes.len() {
            break;
        }
        let value = &tag_open[value_start..i];
        out.insert(name.to_string(), value.to_string());
        i += 1;
    }
    out
}

fn is_name_start(b: u8) -> bool {
    b.is_ascii_alphabetic() || b == b'_' || b == b':'
}

fn is_name_char(b: u8) -> bool {
    is_name_start(b) || b.is_ascii_digit() || b == b'-' || b == b'.'
}

fn first_image_from_xhtml<R: Read + Seek>(
    archive: &mut ZipArchive<R>,
    xhtml_path: &str,
) -> Option<String> {
    let entry_name = resolve_archive_name(archive, xhtml_path)?;
    let content = read_zip_entry_string(archive, &entry_name).ok()?;
    let base = parent_dir(&entry_name);
    for src in iter_image_refs(&content) {
        if src.starts_with("data:") || src.contains("://") {
            continue;
        }
        let joined = join_opf_href(&base, src);
        if is_comic_image_extension(&extension_of(&joined)) {
            return Some(joined);
        }
    }
    None
}

fn iter_image_refs(content: &str) -> impl Iterator<Item = &str> {
    const KEYS: [&str; 3] = ["src=\"", "xlink:href=\"", "href=\""];
    let mut out = Vec::new();
    for key in KEYS {
        let mut rest = content;
        while let Some(start) = rest.find(key) {
            let after = &rest[start + key.len()..];
            if let Some(end) = after.find('"') {
                let value = &after[..end];
                let lower = value.to_ascii_lowercase();
                if key != "href=\""
                    || lower.ends_with(".jpg")
                    || lower.ends_with(".jpeg")
                    || lower.ends_with(".png")
                    || lower.ends_with(".webp")
                    || lower.ends_with(".gif")
                    || lower.ends_with(".bmp")
                {
                    out.push(value);
                }
                rest = &after[end + 1..];
            } else {
                break;
            }
        }
    }
    out.into_iter()
}

fn resolve_archive_name<R: Read + Seek>(archive: &mut ZipArchive<R>, path: &str) -> Option<String> {
    let normalized = normalize_zip_path(path);
    if archive.by_name(&normalized).is_ok() {
        return Some(normalized);
    }
    if path != normalized && archive.by_name(path).is_ok() {
        return Some(path.to_string());
    }
    let target = Path::new(&normalized)
        .file_name()
        .and_then(|s| s.to_str())?
        .to_string();
    let suffix = format!("/{target}");
    for i in 0..archive.len() {
        let Ok(entry) = archive.by_index(i) else {
            continue;
        };
        let name = normalize_zip_path(entry.name());
        drop(entry);
        if name == normalized || name.ends_with(&suffix) {
            return Some(name);
        }
    }
    None
}

fn is_image_media(media_type: &str) -> bool {
    media_type.to_ascii_lowercase().starts_with("image/")
}

fn extension_of(path: &str) -> String {
    Path::new(path)
        .extension()
        .and_then(|e| e.to_str())
        .map(|e| format!(".{}", e.to_ascii_lowercase()))
        .unwrap_or_default()
}

fn parent_dir(path: &str) -> String {
    match path.rfind('/') {
        Some(idx) => path[..idx].to_string(),
        None => String::new(),
    }
}

fn join_opf_href(base_dir: &str, href: &str) -> String {
    let href = href.replace('\\', "/");
    if href.starts_with('/') {
        return normalize_zip_path(&href[1..]);
    }
    if base_dir.is_empty() {
        return normalize_zip_path(&href);
    }
    // 必须先拼接再折叠 `..`，否则单独 normalize href 会丢掉父路径段。
    normalize_zip_path(&format!("{base_dir}/{href}"))
}

fn normalize_zip_path(path: &str) -> String {
    let normalized = path.replace('\\', "/");
    let mut out: Vec<&str> = Vec::new();
    for part in normalized.split('/') {
        match part {
            "" | "." => {}
            ".." => {
                out.pop();
            }
            other => out.push(other),
        }
    }
    out.join("/")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_opf_reads_spine_order() {
        let opf = r#"<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <manifest>
    <item id="p2" href="html/b.xhtml" media-type="application/xhtml+xml"/>
    <item id="p1" href="html/a.xhtml" media-type="application/xhtml+xml"/>
    <item id="img" href="image/x.png" media-type="image/png"/>
  </manifest>
  <spine>
    <itemref idref="p1"/>
    <itemref idref="p2"/>
  </spine>
</package>"#;
        let (manifest, spine) = parse_opf_manifest_and_spine(opf).expect("opf");
        assert_eq!(spine, vec!["p1".to_string(), "p2".to_string()]);
        assert_eq!(manifest["p1"].href, "html/a.xhtml");
    }

    #[test]
    fn join_opf_href_resolves_parent_segments() {
        assert_eq!(
            join_opf_href("OEBPS/html", "../image/a.png"),
            "OEBPS/image/a.png"
        );
    }
}
