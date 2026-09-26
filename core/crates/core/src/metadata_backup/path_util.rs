use std::path::Path;

use crate::comic_id::normalize_path_for_key;

pub fn compute_relative_path(comic_path: &str, library_root: &str) -> Option<String> {
    let normalized_path = normalize_path_for_key(comic_path);
    let normalized_root = normalize_path_for_key(library_root);
    if normalized_path.is_empty() || normalized_root.is_empty() {
        return None;
    }
    let rel = Path::new(&normalized_path)
        .strip_prefix(Path::new(&normalized_root))
        .ok()?;
    if rel.as_os_str().is_empty() {
        return None;
    }
    Some(rel.to_string_lossy().into_owned())
}
