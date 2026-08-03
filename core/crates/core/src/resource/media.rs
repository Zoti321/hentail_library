use std::path::Path;

const COMIC_IMAGE_EXTENSIONS: &[&str] = &[".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif"];

/// Resource types that support thumbnail generation from disk content.
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
