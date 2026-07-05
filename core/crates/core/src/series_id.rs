use std::path::Path;

use crate::comic_id::{comic_id_from_normalized_path, normalize_path_for_key};

pub fn folder_path_from_comic_path(comic_path: &str) -> Option<String> {
    let normalized = normalize_path_for_key(comic_path);
    if normalized.is_empty() {
        return None;
    }
    let parent = Path::new(&normalized).parent()?;
    let parent_str = parent.to_string_lossy();
    if parent_str.is_empty() {
        return None;
    }
    Some(normalize_path_for_key(&parent_str))
}

pub fn series_id_from_folder_path(folder_path: &str) -> String {
    let normalized = normalize_path_for_key(folder_path);
    comic_id_from_normalized_path(&normalized)
}

pub fn series_name_from_folder_path(folder_path: &str) -> String {
    let normalized = normalize_path_for_key(folder_path);
    Path::new(&normalized)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or(normalized.as_str())
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn folder_path_is_parent_of_comic_path() {
        let folder = folder_path_from_comic_path("E:/lib/Series/vol1.cbz").expect("folder");
        assert_eq!(folder, normalize_path_for_key("E:/lib/Series"));
    }

    #[test]
    fn series_id_is_stable_for_folder_path() {
        let folder = normalize_path_for_key("E:/lib/Series");
        let id = series_id_from_folder_path("E:/lib/Series");
        assert_eq!(id, comic_id_from_normalized_path(&folder));
    }
}
