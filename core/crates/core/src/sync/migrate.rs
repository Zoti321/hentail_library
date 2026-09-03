use std::collections::{HashMap, HashSet};

use crate::comic::ComicDto;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct ResourceFingerprint {
    pub resource_type: String,
    pub resource_size: i64,
    pub page_count: i32,
}

impl ResourceFingerprint {
    pub fn from_comic(comic: &ComicDto) -> Self {
        Self {
            resource_type: comic.resource_type.clone(),
            resource_size: comic.resource_size,
            page_count: comic.page_count,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ComicMigrationPair {
    pub from_comic_id: String,
    pub to_comic_id: String,
}

#[derive(Debug, Clone)]
pub struct ComicMigration {
    pub from_comic_id: String,
    pub to_comic: ComicDto,
}

/// 在 removed / added 集合间按资源指纹做 1:1 唯一配对。
pub fn detect_path_migration_pairs(
    removed: &HashMap<String, ComicDto>,
    added: &HashMap<String, ComicDto>,
) -> Vec<ComicMigrationPair> {
    let removed_by_fp = group_ids_by_fingerprint(removed);
    let added_by_fp = group_ids_by_fingerprint(added);
    let mut pairs = Vec::new();
    for (fp, from_ids) in removed_by_fp {
        if from_ids.len() != 1 {
            continue;
        }
        let Some(to_ids) = added_by_fp.get(&fp) else {
            continue;
        };
        if to_ids.len() != 1 {
            continue;
        }
        pairs.push(ComicMigrationPair {
            from_comic_id: from_ids[0].clone(),
            to_comic_id: to_ids[0].clone(),
        });
    }
    pairs
}

pub fn migrated_id_sets(pairs: &[ComicMigrationPair]) -> (HashSet<String>, HashSet<String>) {
    let mut from_ids = HashSet::new();
    let mut to_ids = HashSet::new();
    for pair in pairs {
        from_ids.insert(pair.from_comic_id.clone());
        to_ids.insert(pair.to_comic_id.clone());
    }
    (from_ids, to_ids)
}

fn group_ids_by_fingerprint(
    comics: &HashMap<String, ComicDto>,
) -> HashMap<ResourceFingerprint, Vec<String>> {
    let mut grouped: HashMap<ResourceFingerprint, Vec<String>> = HashMap::new();
    for (comic_id, comic) in comics {
        grouped
            .entry(ResourceFingerprint::from_comic(comic))
            .or_default()
            .push(comic_id.clone());
    }
    grouped
}

#[cfg(test)]
mod tests {
    use super::*;

    fn comic(
        id: &str,
        path: &str,
        resource_type: &str,
        page_count: i32,
        resource_size: i64,
    ) -> ComicDto {
        ComicDto {
            comic_id: id.to_string(),
            path: path.to_string(),
            resource_type: resource_type.to_string(),
            resource_size,
            created_at: 1,
            last_updated_at: 1,
            title: "title".to_string(),
            content_rating: "unknown".to_string(),
            page_count,
            description: None,
            published_at: None,
            last_read_time_ms: None,
            authors: vec![],
            tags: vec![],
            languages: vec![],
            parodies: vec![],
            locks: crate::comic::ComicMetaLocks::default(),
            library_id: String::new(),
        }
    }

    #[test]
    fn detect_pairs_returns_one_migration_for_unique_matching_fingerprint() {
        let mut removed = HashMap::new();
        removed.insert(
            "old".to_string(),
            comic("old", "/a/old.cbz", "cbz", 10, 1024),
        );
        let mut added = HashMap::new();
        added.insert(
            "new".to_string(),
            comic("new", "/a/new.cbz", "cbz", 10, 1024),
        );

        let pairs = detect_path_migration_pairs(&removed, &added);

        assert_eq!(
            pairs,
            vec![ComicMigrationPair {
                from_comic_id: "old".to_string(),
                to_comic_id: "new".to_string(),
            }]
        );
    }

    #[test]
    fn detect_pairs_returns_empty_when_fingerprint_differs() {
        let mut removed = HashMap::new();
        removed.insert(
            "old".to_string(),
            comic("old", "/a/old.cbz", "cbz", 10, 1024),
        );
        let mut added = HashMap::new();
        added.insert(
            "new".to_string(),
            comic("new", "/a/new.cbz", "cbz", 11, 1024),
        );

        assert!(detect_path_migration_pairs(&removed, &added).is_empty());
    }

    #[test]
    fn detect_pairs_skips_ambiguous_fingerprint_matches() {
        let mut removed = HashMap::new();
        removed.insert(
            "old1".to_string(),
            comic("old1", "/a/1.cbz", "cbz", 10, 1024),
        );
        removed.insert(
            "old2".to_string(),
            comic("old2", "/a/2.cbz", "cbz", 10, 1024),
        );
        let mut added = HashMap::new();
        added.insert(
            "new1".to_string(),
            comic("new1", "/a/3.cbz", "cbz", 10, 1024),
        );
        added.insert(
            "new2".to_string(),
            comic("new2", "/a/4.cbz", "cbz", 10, 1024),
        );

        assert!(detect_path_migration_pairs(&removed, &added).is_empty());
    }
}
