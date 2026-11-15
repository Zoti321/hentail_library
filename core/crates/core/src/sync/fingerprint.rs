//! Content evidence for location migration; all Resource I/O precedes the write transaction.
use super::{handle::SyncHandle, scanner::ScanItem};
use crate::db::map_db_err;
use crate::error::HentaiError;
use crate::resource::{
    extension_lower, is_comic_image_extension, read_source_stat_with, ResourceAccess, ResourceKind,
};
use sea_orm::{ConnectionTrait, Statement};
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::io::Read;

pub(crate) struct StoredFingerprint {
    pub digest: String,
    pub(crate) resource_type: String,
    modified_ms: i64,
    size: i64,
}

pub(crate) async fn load_fingerprints(
    db: &impl ConnectionTrait,
    library_id: &str,
) -> Result<HashMap<String, StoredFingerprint>, HentaiError> {
    db.query_all(Statement::from_sql_and_values(db.get_database_backend(),
        "SELECT f.* FROM comic_content_fingerprints f JOIN comics c ON c.comic_id = f.comic_id WHERE c.library_id = ?",
        [library_id.into()])).await.map_err(map_db_err)?.into_iter().map(|row| {
        Ok((row.try_get("", "comic_id").map_err(map_db_err)?, StoredFingerprint {
            digest: row.try_get("", "digest").map_err(map_db_err)?,
            resource_type: row.try_get("", "resource_type").map_err(map_db_err)?,
            modified_ms: row.try_get("", "modified_ms").map_err(map_db_err)?,
            size: row.try_get("", "size").map_err(map_db_err)?,
        }))
    }).collect()
}

/// Capture missing/changed fingerprints. False means cancellation; nothing has been written.
pub async fn prepare_content_fingerprints(
    db: &impl ConnectionTrait,
    library_id: &str,
    access: &dyn ResourceAccess,
    items: &mut [ScanItem],
    handle: &SyncHandle,
) -> Result<bool, HentaiError> {
    let stored = load_fingerprints(db, library_id).await?;
    for item in items {
        if handle.is_cancelled() {
            return Ok(false);
        }
        let before = read_source_stat_with(access, &item.path, &item.resource_type)?
            .ok_or_else(|| HentaiError::validation("Fingerprint source disappeared"))?;
        if item
            .observed_stat
            .is_some_and(|observed| observed != before)
            || before.1 != item.comic.resource_size
        {
            return Err(HentaiError::validation(
                "Fingerprint source changed since scan",
            ));
        }
        // Directory timestamps do not describe child changes. Unknown file times are not cache keys.
        let cached = stored.get(&item.comic.comic_id).filter(|old| {
            item.resource_type != "dir"
                && before.0 > 0
                && old.modified_ms == before.0
                && old.size == before.1
                && old.resource_type == item.resource_type
        });
        item.content_digest = match cached {
            Some(old) => Some(old.digest.clone()),
            None => content_digest(access, item, handle)?,
        };
        if handle.is_cancelled() {
            return Ok(false);
        }
        if read_source_stat_with(access, &item.path, &item.resource_type)? != Some(before) {
            return Err(HentaiError::validation(
                "Fingerprint source changed while reading",
            ));
        }
        item.observed_stat = Some(before);
    }
    Ok(true)
}

fn hash_file(
    access: &dyn ResourceAccess,
    path: &str,
    handle: &SyncHandle,
) -> Result<Option<[u8; 32]>, HentaiError> {
    let before = access
        .stat(path)?
        .ok_or_else(|| HentaiError::validation("Fingerprint file disappeared"))?;
    if before.kind != ResourceKind::File {
        return Err(HentaiError::validation("Fingerprint expected file"));
    }
    let mut stream = access.open_stream(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 65536];
    let mut total = 0u64;
    loop {
        if handle.is_cancelled() {
            return Ok(None);
        }
        let count = stream
            .read(&mut buffer)
            .map_err(|e| HentaiError::validation(e.to_string()))?;
        if count == 0 {
            break;
        }
        total += count as u64;
        hasher.update(&buffer[..count]);
    }
    if total != before.size || access.stat(path)?.as_ref() != Some(&before) {
        return Err(HentaiError::validation(
            "Fingerprint file changed while reading",
        ));
    }
    Ok(Some(hasher.finalize().into()))
}

pub(crate) fn content_digest(
    access: &dyn ResourceAccess,
    item: &ScanItem,
    handle: &SyncHandle,
) -> Result<Option<String>, HentaiError> {
    resource_content_digest(access, &item.path, &item.resource_type, handle)
}

pub(crate) fn resource_content_digest(
    access: &dyn ResourceAccess,
    path: &str,
    resource_type: &str,
    handle: &SyncHandle,
) -> Result<Option<String>, HentaiError> {
    if resource_type != "dir" {
        return hash_file(access, path, handle).map(|digest| {
            digest.map(|digest| {
                format!(
                    "sha256-file-v1:{}",
                    digest
                        .iter()
                        .map(|byte| format!("{byte:02x}"))
                        .collect::<String>()
                )
            })
        });
    }
    let mut pages: Vec<_> = access
        .list(path)?
        .into_iter()
        .filter(|entry| {
            entry.kind == ResourceKind::File
                && is_comic_image_extension(&extension_lower(std::path::Path::new(&entry.name)))
        })
        .collect();
    pages.sort_by(|a, b| {
        crate::util::natural_sort::compare_filename_natural(&a.name, &b.name)
            .then_with(|| a.name.cmp(&b.name))
    });
    if pages.windows(2).any(|pair| {
        crate::util::natural_sort::compare_filename_natural(&pair[0].name, &pair[1].name).is_eq()
    }) {
        // The Reader cannot promise a stable order for naturally equivalent names.
        return Ok(None);
    }
    if pages.is_empty() {
        return Err(HentaiError::validation(
            "Fingerprint directory has no pages",
        ));
    }
    let mut hasher = Sha256::new();
    hasher.update((pages.len() as u64).to_le_bytes());
    let mut observations = Vec::new();
    for page in &pages {
        observations.push(access.stat(&page.location)?);
        let Some(digest) = hash_file(access, &page.location, handle)? else {
            return Ok(None);
        };
        hasher.update(digest);
    }
    let mut after: Vec<_> = access
        .list(path)?
        .into_iter()
        .filter(|entry| {
            entry.kind == ResourceKind::File
                && is_comic_image_extension(&extension_lower(std::path::Path::new(&entry.name)))
        })
        .collect();
    after.sort_by(|a, b| {
        crate::util::natural_sort::compare_filename_natural(&a.name, &b.name)
            .then_with(|| a.name.cmp(&b.name))
    });
    if pages != after {
        return Err(HentaiError::validation(
            "Fingerprint directory changed while reading",
        ));
    }
    for (page, observed) in pages.iter().zip(observations) {
        if access.stat(&page.location)? != observed {
            return Err(HentaiError::validation(
                "Fingerprint page changed while reading",
            ));
        }
    }
    Ok(Some(format!("sha256-pages-v1:{:x}", hasher.finalize())))
}

pub(crate) async fn store_fingerprint(
    db: &impl ConnectionTrait,
    item: &ScanItem,
) -> Result<(), HentaiError> {
    if let (Some(digest), Some((modified, size))) = (&item.content_digest, item.observed_stat) {
        db.execute(Statement::from_sql_and_values(db.get_database_backend(),
            "INSERT INTO comic_content_fingerprints (comic_id, digest, resource_type, modified_ms, size) VALUES (?, ?, ?, ?, ?) ON CONFLICT(comic_id) DO UPDATE SET digest = excluded.digest, resource_type = excluded.resource_type, modified_ms = excluded.modified_ms, size = excluded.size",
            vec![item.comic.comic_id.clone().into(), digest.clone().into(), item.resource_type.clone().into(), modified.into(), size.into()])).await.map_err(map_db_err)?;
    } else {
        db.execute(Statement::from_sql_and_values(
            db.get_database_backend(),
            "DELETE FROM comic_content_fingerprints WHERE comic_id = ?",
            [item.comic.comic_id.clone().into()],
        ))
        .await
        .map_err(map_db_err)?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::resource::FakeResourceAccess;
    #[test]
    fn changed_stat_and_truncated_stream_cannot_produce_fingerprints() {
        use crate::resource::{ResourceEntry, ResourceStat, ResourceStream};
        use std::sync::atomic::{AtomicUsize, Ordering};
        struct Access {
            fake: FakeResourceAccess,
            reads: AtomicUsize,
            truncate: bool,
        }
        impl ResourceAccess for Access {
            fn stat(&self, path: &str) -> Result<Option<ResourceStat>, HentaiError> {
                let mut stat = self.fake.stat(path)?;
                if !self.truncate && self.reads.fetch_add(1, Ordering::SeqCst) > 0 {
                    if let Some(stat) = &mut stat {
                        stat.modified_ms += 1;
                    }
                }
                Ok(stat)
            }
            fn list(&self, path: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
                self.fake.list(path)
            }
            fn open_stream(&self, path: &str) -> Result<ResourceStream, HentaiError> {
                if self.truncate {
                    Ok(Box::new(std::io::Cursor::new(b"ab".to_vec())))
                } else {
                    self.fake.open_stream(path)
                }
            }
        }
        for truncate in [false, true] {
            let mut fake = FakeResourceAccess::new();
            fake.insert_file("/book.cbz", b"abc");
            let access = Access {
                fake,
                reads: AtomicUsize::new(0),
                truncate,
            };
            assert!(hash_file(&access, "/book.cbz", &crate::create_sync_handle()).is_err());
        }
    }

    #[test]
    fn full_file_hash_matches_sha256_vector_and_cancel_does_not_produce_evidence() {
        let mut access = FakeResourceAccess::new();
        access.insert_file("/book.cbz", b"abc");
        let handle = crate::create_sync_handle();
        let digest = hash_file(&access, "/book.cbz", &handle).unwrap().unwrap();
        assert_eq!(
            digest
                .iter()
                .map(|byte| format!("{byte:02x}"))
                .collect::<String>(),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
        crate::cancel_sync(&handle);
        assert!(hash_file(&access, "/book.cbz", &handle).unwrap().is_none());
    }
}
