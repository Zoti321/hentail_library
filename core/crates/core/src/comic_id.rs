use sha1::{Digest, Sha1};

/// 与 Dart `PathNormalizer.normalizeForKey` 对齐的跨平台路径键。
pub fn normalize_path_for_key(raw_path: &str) -> String {
    let normalized_fs_path = normalize_for_file_system(raw_path);
    if normalized_fs_path.is_empty() {
        return String::new();
    }
    let posix_path = normalize_posix(&normalized_fs_path.replace('\\', "/"));
    trim_trailing_slash(&posix_path)
}

/// 与 Dart `generateComicId(normalizedPath)` 对齐：SHA1(utf8) 小写 hex。
pub fn comic_id_from_path(raw_path: &str) -> String {
    let normalized = normalize_path_for_key(raw_path);
    if normalized.is_empty() {
        return String::new();
    }
    comic_id_from_normalized_path(&normalized)
}

pub fn comic_id_from_normalized_path(normalized_path: &str) -> String {
    let mut hasher = Sha1::new();
    hasher.update(normalized_path.as_bytes());
    format!("{:x}", hasher.finalize())
}

fn normalize_for_file_system(raw_path: &str) -> String {
    let trimmed = raw_path.trim();
    if trimmed.is_empty() {
        return String::new();
    }
    normalize_like_dart_path(trimmed)
}

/// 模拟 `package:path` 的 `normalize`（Windows 语义，保证 comicId 稳定）。
fn normalize_like_dart_path(path: &str) -> String {
    let rooted = path.starts_with('/') || path.starts_with('\\');
    let (drive, rest) = split_drive(path);
    let has_drive = drive.is_some();
    let mut segments = split_segments(rest);
    resolve_dot_segments(&mut segments);
    let body = join_segments(&segments, '\\');
    let mut result = match drive {
        Some(prefix) if body.is_empty() => prefix,
        Some(prefix) => format!("{prefix}\\{body}"),
        None if body.is_empty() => {
            if rooted {
                "\\".to_string()
            } else {
                String::new()
            }
        }
        None => body,
    };
    if rooted && !has_drive && !result.is_empty()
        && !result.starts_with('\\') && !result.starts_with('/')
    {
        result.insert(0, '\\');
    }
    result
}

fn split_drive(path: &str) -> (Option<String>, &str) {
    let bytes = path.as_bytes();
    if bytes.len() >= 2 && bytes[1] == b':' {
        let drive = &path[..2];
        let rest = &path[2..];
        let rest = rest.strip_prefix(['\\', '/']).unwrap_or(rest);
        return (Some(drive.to_string()), rest);
    }
    (None, path)
}

fn split_segments(path: &str) -> Vec<String> {
    path.split(['\\', '/'])
        .filter(|segment| !segment.is_empty())
        .map(str::to_string)
        .collect()
}

fn resolve_dot_segments(segments: &mut Vec<String>) {
    let mut resolved: Vec<String> = Vec::new();
    for segment in segments.drain(..) {
        if segment == "." {
            continue;
        }
        if segment == ".." {
            resolved.pop();
            continue;
        }
        resolved.push(segment);
    }
    *segments = resolved;
}

fn join_segments(segments: &[String], separator: char) -> String {
    segments.join(&separator.to_string())
}

fn normalize_posix(path: &str) -> String {
    let rooted = path.starts_with('/');
    let (drive, rest) = split_drive(path);
    let mut segments = split_segments(rest);
    resolve_dot_segments(&mut segments);
    let body = join_segments(&segments, '/');
    match drive {
        Some(prefix) if body.is_empty() => prefix,
        Some(prefix) => format!("{prefix}/{body}"),
        None if body.is_empty() && rooted => "/".to_string(),
        None if rooted => format!("/{body}"),
        None => body,
    }
}

fn trim_trailing_slash(normalized_posix_path: &str) -> String {
    if normalized_posix_path == "/"
        || regex_drive_root(normalized_posix_path)
    {
        return normalized_posix_path.to_string();
    }
    let mut current = normalized_posix_path.to_string();
    while current.ends_with('/') {
        current.pop();
    }
    current
}

fn regex_drive_root(path: &str) -> bool {
    let bytes = path.as_bytes();
    bytes.len() == 3
        && bytes[1] == b':'
        && bytes[2] == b'/'
        && bytes[0].is_ascii_alphabetic()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use std::path::PathBuf;

    #[test]
    fn comic_id_golden_vectors() {
        let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let fixture = manifest_dir
            .join("../../tests/fixtures/comic_id_vectors.json")
            .canonicalize()
            .expect("fixture path");
        let raw = fs::read_to_string(fixture).expect("read fixture");
        let json: serde_json::Value = serde_json::from_str(&raw).expect("parse json");
        let cases = json["cases"].as_array().expect("cases array");

        for case in cases {
            let description = case["description"].as_str().unwrap_or("?");
            let input = case["raw"].as_str().expect("raw");
            let expected_normalized = case["normalized"].as_str().expect("normalized");
            let expected_id = case["expected_comic_id"].as_str().expect("expected_comic_id");

            let normalized = normalize_path_for_key(input);
            assert_eq!(
                normalized, expected_normalized,
                "normalize mismatch: {description}"
            );

            let comic_id = comic_id_from_path(input);
            assert_eq!(comic_id, expected_id, "comic_id mismatch: {description}");
        }
    }
}
