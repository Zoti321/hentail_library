//! Read-only comparisons against the content evidence saved by Library sync.
use std::collections::HashMap;

use sea_orm::{ConnectionTrait, Statement};
use serde::{Deserialize, Serialize};

use crate::db::map_db_err;
use crate::error::HentaiError;
use crate::resource::{read_source_stat_with, ResourceAccess, ResourceKind};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResourceFingerprint {
    pub digest: String,
    pub resource_type: String,
    pub modified_ms: i64,
    pub size: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResourceVerificationMode {
    Quick,
    Strict,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResourceVerificationStatus {
    NotDetected,
    ObservationChanged,
    ContentMatches,
    ContentChanged,
    Missing,
    BaselineUnavailable,
    Indeterminate,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResourceVerificationResult {
    pub status: ResourceVerificationStatus,
    pub observed_modified_ms: Option<i64>,
    pub observed_size: Option<i64>,
}

pub(crate) async fn load_fingerprints(
    db: &impl ConnectionTrait,
    ids: &[String],
) -> Result<HashMap<String, ResourceFingerprint>, HentaiError> {
    let mut fingerprints = HashMap::new();
    // Bound SQLite parameter counts for large unpaged reads.
    for chunk in ids.chunks(500) {
        let placeholders = vec!["?"; chunk.len()].join(",");
        let rows = db
            .query_all(Statement::from_sql_and_values(
                db.get_database_backend(),
                format!(
                    "SELECT * FROM comic_content_fingerprints WHERE comic_id IN ({placeholders})"
                ),
                chunk
                    .iter()
                    .cloned()
                    .map(Into::into)
                    .collect::<Vec<sea_orm::Value>>(),
            ))
            .await
            .map_err(map_db_err)?;
        for row in rows {
            fingerprints.insert(
                row.try_get("", "comic_id").map_err(map_db_err)?,
                ResourceFingerprint {
                    digest: row.try_get("", "digest").map_err(map_db_err)?,
                    resource_type: row.try_get("", "resource_type").map_err(map_db_err)?,
                    modified_ms: row.try_get("", "modified_ms").map_err(map_db_err)?,
                    size: row.try_get("", "size").map_err(map_db_err)?,
                },
            );
        }
    }
    Ok(fingerprints)
}

pub async fn verify_comic_resource(
    comic_id: &str,
    mode: ResourceVerificationMode,
) -> Result<ResourceVerificationResult, HentaiError> {
    let comic = crate::find_comic_by_id(comic_id)
        .await?
        .ok_or_else(|| HentaiError::validation("Comic does not exist"))?;
    if crate::is_comic_trashed(comic_id).await? {
        return Err(HentaiError::validation("Comic is trashed"));
    }
    tokio::task::spawn_blocking(move || {
        let access = crate::resolve_access_for_comic(&comic)?;
        verify_with(
            access.as_dyn(),
            &comic.path,
            &comic.resource_type,
            comic.resource_fingerprint.as_ref(),
            mode,
        )
    })
    .await
    .map_err(|error| HentaiError::validation(error.to_string()))?
}

fn verify_with(
    access: &dyn ResourceAccess,
    path: &str,
    resource_type: &str,
    baseline: Option<&ResourceFingerprint>,
    mode: ResourceVerificationMode,
) -> Result<ResourceVerificationResult, HentaiError> {
    use ResourceVerificationStatus::*;
    let Some(stat) = access.stat(path)? else {
        return Ok(ResourceVerificationResult {
            status: Missing,
            observed_modified_ms: None,
            observed_size: None,
        });
    };
    let expected_kind = if resource_type == "dir" {
        ResourceKind::Dir
    } else {
        ResourceKind::File
    };
    if stat.kind != expected_kind {
        return Ok(ResourceVerificationResult {
            status: ObservationChanged,
            observed_modified_ms: (stat.modified_ms > 0).then_some(stat.modified_ms),
            observed_size: None,
        });
    }
    let observation = read_source_stat_with(access, path, resource_type)?;
    let (modified, size) = observation
        .ok_or_else(|| HentaiError::validation("Resource disappeared during verification"))?;
    let result = |status| ResourceVerificationResult {
        status,
        observed_modified_ms: (modified > 0).then_some(modified),
        observed_size: Some(size),
    };
    let Some(baseline) = baseline else {
        return Ok(result(BaselineUnavailable));
    };
    if baseline.resource_type != resource_type {
        return Ok(result(BaselineUnavailable));
    }
    if mode == ResourceVerificationMode::Quick {
        let status = if size != baseline.size
            || (modified > 0 && baseline.modified_ms > 0 && modified != baseline.modified_ms)
        {
            ObservationChanged
        } else if resource_type == "dir" || modified <= 0 || baseline.modified_ms <= 0 {
            Indeterminate
        } else {
            NotDetected
        };
        if access.stat(path)?.as_ref() != Some(&stat) {
            return Err(HentaiError::validation(
                "Resource changed during verification",
            ));
        }
        return Ok(result(status));
    }
    let prefix = if resource_type == "dir" {
        "sha256-pages-v1:"
    } else {
        "sha256-file-v1:"
    };
    let valid_digest = baseline
        .digest
        .strip_prefix(prefix)
        .is_some_and(|hex| hex.len() == 64 && hex.bytes().all(|byte| byte.is_ascii_hexdigit()));
    if !valid_digest {
        return Ok(result(BaselineUnavailable));
    }
    let digest = crate::sync::fingerprint::resource_content_digest(
        access,
        path,
        resource_type,
        &crate::create_sync_handle(),
    )?;
    if access.stat(path)?.as_ref() != Some(&stat)
        || read_source_stat_with(access, path, resource_type)? != Some((modified, size))
    {
        return Err(HentaiError::validation(
            "Resource changed during verification",
        ));
    }
    Ok(result(match digest {
        None => Indeterminate,
        Some(digest) if digest == baseline.digest => ContentMatches,
        Some(_) => ContentChanged,
    }))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::resource::{FakeResourceAccess, ResourceEntry, ResourceStat, ResourceStream};
    use ResourceVerificationMode::{Quick, Strict};
    use ResourceVerificationStatus::*;

    struct NoReads(FakeResourceAccess);

    impl ResourceAccess for NoReads {
        fn stat(&self, path: &str) -> Result<Option<ResourceStat>, HentaiError> {
            self.0.stat(path)
        }
        fn list(&self, path: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
            self.0.list(path)
        }
        fn open_stream(&self, _: &str) -> Result<ResourceStream, HentaiError> {
            panic!("Quick verification must not read resource contents")
        }
    }

    fn file() -> FakeResourceAccess {
        let mut access = FakeResourceAccess::new();
        access.insert_file("/book.cbz", b"abc");
        access.set_modified_ms("/book.cbz", 100);
        access
    }

    fn baseline(access: &dyn ResourceAccess, path: &str, kind: &str) -> ResourceFingerprint {
        let (modified_ms, size) = read_source_stat_with(access, path, kind).unwrap().unwrap();
        ResourceFingerprint {
            // Independently known SHA-256("abc") for the ordinary-file fixture.
            digest: if kind != "dir" {
                "sha256-file-v1:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
                    .into()
            } else {
                crate::sync::fingerprint::resource_content_digest(
                    access,
                    path,
                    kind,
                    &crate::create_sync_handle(),
                )
                .unwrap()
                .unwrap()
            },
            resource_type: kind.into(),
            modified_ms,
            size,
        }
    }

    #[test]
    fn quick_stats_cannot_prove_content_and_strict_bypasses_cached_observations() {
        let mut access = file();
        let saved = baseline(&access, "/book.cbz", "cbz");
        assert_eq!(
            verify_with(
                &NoReads(access.clone()),
                "/book.cbz",
                "cbz",
                Some(&saved),
                Quick
            )
            .unwrap()
            .status,
            NotDetected
        );
        assert_eq!(
            verify_with(&access, "/book.cbz", "cbz", Some(&saved), Strict)
                .unwrap()
                .status,
            ContentMatches
        );
        access.insert_file("/book.cbz", b"abd");
        access.set_modified_ms("/book.cbz", 100);
        assert_eq!(
            verify_with(
                &NoReads(access.clone()),
                "/book.cbz",
                "cbz",
                Some(&saved),
                Quick
            )
            .unwrap()
            .status,
            NotDetected
        );
        assert_eq!(
            verify_with(&access, "/book.cbz", "cbz", Some(&saved), Strict)
                .unwrap()
                .status,
            ContentChanged
        );
        access.set_modified_ms("/book.cbz", 200);
        assert_eq!(
            verify_with(&NoReads(access), "/book.cbz", "cbz", Some(&saved), Quick)
                .unwrap()
                .status,
            ObservationChanged
        );
    }

    #[test]
    fn missing_unrecorded_unknown_and_incompatible_sources_remain_distinct() {
        let mut access = file();
        let saved = baseline(&access, "/book.cbz", "cbz");
        assert_eq!(
            verify_with(&access, "/missing", "cbz", None, Strict)
                .unwrap()
                .status,
            Missing
        );
        assert_eq!(
            verify_with(&NoReads(access.clone()), "/book.cbz", "cbz", None, Strict)
                .unwrap()
                .status,
            BaselineUnavailable
        );
        access.set_modified_ms("/book.cbz", 0);
        assert_eq!(
            verify_with(
                &NoReads(access.clone()),
                "/book.cbz",
                "cbz",
                Some(&saved),
                Quick
            )
            .unwrap()
            .status,
            Indeterminate
        );
        assert_eq!(
            verify_with(&access, "/book.cbz", "cbz", Some(&saved), Strict)
                .unwrap()
                .status,
            ContentMatches
        );
        let mut incompatible = saved.clone();
        incompatible.digest = "sha256-file-v2:unknown".into();
        assert_eq!(
            verify_with(
                &NoReads(access.clone()),
                "/book.cbz",
                "cbz",
                Some(&incompatible),
                Strict
            )
            .unwrap()
            .status,
            BaselineUnavailable
        );
        assert_eq!(
            verify_with(&access, "/book.cbz", "dir", Some(&saved), Strict)
                .unwrap()
                .status,
            ObservationChanged
        );
        access.set_unreachable("401 unauthorized");
        assert!(verify_with(&access, "/book.cbz", "cbz", Some(&saved), Quick).is_err());
    }

    #[test]
    fn directory_verification_uses_reading_order_and_quick_checks_are_inconclusive() {
        let mut access = FakeResourceAccess::new();
        access.insert_file("/pages/1.jpg", b"first");
        access.insert_file("/pages/2.jpg", b"second");
        let saved = baseline(&access, "/pages", "dir");
        assert_eq!(
            verify_with(
                &NoReads(access.clone()),
                "/pages",
                "dir",
                Some(&saved),
                Quick
            )
            .unwrap()
            .status,
            Indeterminate
        );
        assert_eq!(
            verify_with(&access, "/pages", "dir", Some(&saved), Strict)
                .unwrap()
                .status,
            ContentMatches
        );
        access.insert_file("/pages/1.jpg", b"second");
        access.insert_file("/pages/2.jpg", b"first");
        assert_eq!(
            verify_with(&access, "/pages", "dir", Some(&saved), Strict)
                .unwrap()
                .status,
            ContentChanged
        );
        access.insert_file("/pages/01.jpg", b"duplicate order");
        assert_eq!(
            verify_with(&access, "/pages", "dir", Some(&saved), Strict)
                .unwrap()
                .status,
            Indeterminate
        );
    }

    #[test]
    fn strict_verification_rejects_truncated_or_changed_sources() {
        use std::sync::atomic::{AtomicBool, Ordering};
        struct Unstable {
            access: FakeResourceAccess,
            opened: AtomicBool,
            truncated: bool,
        }
        impl ResourceAccess for Unstable {
            fn stat(&self, path: &str) -> Result<Option<ResourceStat>, HentaiError> {
                let mut stat = self.access.stat(path)?;
                if !self.truncated && self.opened.load(Ordering::Relaxed) {
                    if let Some(stat) = &mut stat {
                        stat.modified_ms += 1;
                    }
                }
                Ok(stat)
            }
            fn list(&self, path: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
                self.access.list(path)
            }
            fn open_stream(&self, path: &str) -> Result<ResourceStream, HentaiError> {
                self.opened.store(true, Ordering::Relaxed);
                if self.truncated {
                    return Ok(Box::new(std::io::Cursor::new(b"ab".to_vec())));
                }
                self.access.open_stream(path)
            }
        }
        for truncated in [true, false] {
            let access = file();
            let saved = baseline(&access, "/book.cbz", "cbz");
            let access = Unstable {
                access,
                opened: AtomicBool::new(false),
                truncated,
            };
            assert!(verify_with(&access, "/book.cbz", "cbz", Some(&saved), Strict).is_err());
        }
    }
}
