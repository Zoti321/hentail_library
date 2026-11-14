mod common;

use hentai_core::entity::prelude::Libraries;
use hentai_core::*;
use sea_orm::EntityTrait;
use sea_orm::{ConnectionTrait, Statement};

#[test]
fn sync_rolls_back_catalog_snapshot_and_success_then_retry_converges() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        common::write_cbz(&library_root.join("a.cbz"), 1);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_local_library(&library_root.to_string_lossy(), None).await.unwrap();
            let sync = || sync_library(create_sync_handle(), SyncScanMode::Full, false,
                Some(library.library_id.as_str()), vec![], |_| {});
            sync().await.unwrap();
            let db = connection().unwrap();
            let previous = Libraries::find_by_id(&library.library_id).one(&db).await.unwrap().unwrap().last_successful_sync_at;
            let baseline = probe::load_snapshot_map(&db, &library.library_id).await.unwrap();
            let added = library_root.join("b.cbz");
            common::write_cbz(&added, 2);
            let added_id = comic_id_from_path(&added.to_string_lossy());
            for (table, event) in [("comic_meta", "INSERT"), ("library_resource_snapshots", "INSERT"), ("libraries", "UPDATE")] {
                db.execute(Statement::from_string(sea_orm::DatabaseBackend::Sqlite,
                    format!("CREATE TRIGGER fail_sync_{table} BEFORE {event} ON {table} BEGIN SELECT RAISE(ABORT, 'injected sync failure'); END"))).await.unwrap();
                assert!(sync().await.is_err());
                assert!(find_comic_by_id(&added_id).await.unwrap().is_none());
                assert_eq!(probe::load_snapshot_map(&db, &library.library_id).await.unwrap(), baseline);
                assert_eq!(Libraries::find_by_id(&library.library_id).one(&db).await.unwrap().unwrap().last_successful_sync_at, previous);
                db.execute(Statement::from_string(sea_orm::DatabaseBackend::Sqlite, format!("DROP TRIGGER fail_sync_{table}"))).await.unwrap();
            }
            sync().await.unwrap();
            sync().await.unwrap();
            assert!(find_comic_by_id(&added_id).await.unwrap().is_some());
            assert_eq!(probe::load_snapshot_map(&db, &library.library_id).await.unwrap().len(), 2);
        });
    });
}

#[test]
fn sync_cancellation_preserves_baseline_and_commit_revokes_reader() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        let page = library_root.join("a.cbz");
        common::write_cbz(&page, 1);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_local_library(&library_root.to_string_lossy(), None)
                .await
                .unwrap();
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .unwrap();
            let db = connection().unwrap();
            let baseline = probe::load_snapshot_map(&db, &library.library_id)
                .await
                .unwrap();
            let comic_id = comic_id_from_path(&page.to_string_lossy());
            reader::open_reader(&comic_id, &page.to_string_lossy(), "cbz").unwrap();
            let old_read = reader::ReaderPageRead::capture(&comic_id).unwrap();
            common::write_cbz(&library_root.join("b.cbz"), 2);
            let handle = create_sync_handle();
            sync_library(
                handle.clone(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |progress| {
                    if matches!(progress.phase, SyncLibraryPhaseDto::WritingDb) {
                        cancel_sync(&handle);
                    }
                },
            )
            .await
            .unwrap();
            assert_eq!(
                probe::load_snapshot_map(&db, &library.library_id)
                    .await
                    .unwrap(),
                baseline
            );
            assert!(reader::session_path_and_type(&comic_id).is_ok());
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .unwrap();
            assert!(reader::load_reader_page(old_read, 0).is_err());
            assert_eq!(
                probe::load_snapshot_map(&db, &library.library_id)
                    .await
                    .unwrap()
                    .len(),
                2
            );
        });
    });
}

#[test]
fn committed_sync_rejects_decode_already_running_without_waiting_for_codec() {
    use hentai_core::resource::{
        local_access, ResourceAccess, ResourceEntry, ResourceStat, ResourceStream,
    };
    use std::io::{Read, Seek, SeekFrom};
    use std::sync::{
        atomic::{AtomicBool, Ordering},
        mpsc, Arc, Mutex,
    };
    use std::time::Duration;
    struct Access {
        armed: Arc<AtomicBool>,
        entered: mpsc::Sender<()>,
        release: Arc<Mutex<mpsc::Receiver<()>>>,
    }
    struct Stream {
        inner: ResourceStream,
        armed: Arc<AtomicBool>,
        entered: mpsc::Sender<()>,
        release: Arc<Mutex<mpsc::Receiver<()>>>,
    }
    impl Read for Stream {
        fn read(&mut self, bytes: &mut [u8]) -> std::io::Result<usize> {
            if self.armed.swap(false, Ordering::SeqCst) {
                self.entered.send(()).unwrap();
                self.release
                    .lock()
                    .unwrap()
                    .recv_timeout(Duration::from_secs(20))
                    .unwrap();
            }
            self.inner.read(bytes)
        }
    }
    impl Seek for Stream {
        fn seek(&mut self, position: SeekFrom) -> std::io::Result<u64> {
            self.inner.seek(position)
        }
    }
    impl ResourceAccess for Access {
        fn local_path(&self, location: &str) -> Option<std::path::PathBuf> {
            local_access().local_path(location)
        }
        fn stat(&self, location: &str) -> Result<Option<ResourceStat>, HentaiError> {
            local_access().stat(location)
        }
        fn list(&self, location: &str) -> Result<Vec<ResourceEntry>, HentaiError> {
            local_access().list(location)
        }
        fn open_stream(&self, location: &str) -> Result<ResourceStream, HentaiError> {
            Ok(Box::new(Stream {
                inner: local_access().open_stream(location)?,
                armed: self.armed.clone(),
                entered: self.entered.clone(),
                release: self.release.clone(),
            }))
        }
    }
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        let path = library_root.join("a.cbz");
        common::write_cbz(&path, 1);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_local_library(&library_root.to_string_lossy(), None)
                .await
                .unwrap();
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .unwrap();
            let comic_id = comic_id_from_path(&path.to_string_lossy());
            let (entered, entered_rx) = mpsc::channel();
            let (release_tx, release) = mpsc::channel();
            let armed = Arc::new(AtomicBool::new(false));
            let access = Access {
                armed: armed.clone(),
                entered,
                release: Arc::new(Mutex::new(release)),
            };
            reader::open_reader_with(&access, &comic_id, &path.to_string_lossy(), "cbz").unwrap();
            let read = reader::ReaderPageRead::capture(&comic_id).unwrap();
            armed.store(true, Ordering::SeqCst);
            let worker = std::thread::spawn(move || reader::load_reader_page(read, 0));
            entered_rx.recv_timeout(Duration::from_secs(5)).unwrap();
            let committed = tokio::time::timeout(
                Duration::from_secs(5),
                sync_library(
                    create_sync_handle(),
                    SyncScanMode::Full,
                    false,
                    Some(&library.library_id),
                    vec![],
                    |_| {},
                ),
            )
            .await;
            release_tx.send(()).unwrap();
            committed.unwrap().unwrap();
            assert_eq!(
                worker.join().unwrap().unwrap_err().code,
                HentaiErrorCode::ReaderSessionNotOpen
            );
            reader::open_reader(&comic_id, &path.to_string_lossy(), "cbz").unwrap();
            assert!(reader::load_reader_page(
                reader::ReaderPageRead::capture(&comic_id).unwrap(),
                0
            )
            .is_ok());
            reader::close_reader(&comic_id);
        });
    });
}

#[test]
fn source_change_after_scan_preserves_successful_baseline() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        let path = library_root.join("a.cbz");
        common::write_cbz(&path, 1);
        let runtime = tokio::runtime::Runtime::new().unwrap();
        runtime.block_on(async {
            init_db_at_path(&root.join("db.sqlite")).await.unwrap();
            let library = create_local_library(&library_root.to_string_lossy(), None)
                .await
                .unwrap();
            sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |_| {},
            )
            .await
            .unwrap();
            let db = connection().unwrap();
            let baseline = probe::load_snapshot_map(&db, &library.library_id)
                .await
                .unwrap();
            let result = sync_library(
                create_sync_handle(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |progress| {
                    if matches!(progress.phase, SyncLibraryPhaseDto::WritingDb) {
                        common::write_cbz(&path, 3);
                    }
                },
            )
            .await;
            assert!(result.is_err());
            assert_eq!(
                probe::load_snapshot_map(&db, &library.library_id)
                    .await
                    .unwrap(),
                baseline
            );
            let comic_id = comic_id_from_path(&path.to_string_lossy());
            assert_eq!(
                find_comic_by_id(&comic_id)
                    .await
                    .unwrap()
                    .unwrap()
                    .page_count,
                1
            );
            let handle = create_sync_handle();
            let mut done = false;
            sync_library(
                handle.clone(),
                SyncScanMode::Full,
                false,
                Some(&library.library_id),
                vec![],
                |progress| {
                    if matches!(progress.phase, SyncLibraryPhaseDto::Done) {
                        done = true;
                        cancel_sync(&handle);
                    }
                },
            )
            .await
            .unwrap();
            assert!(done);
            assert_eq!(
                find_comic_by_id(&comic_id)
                    .await
                    .unwrap()
                    .unwrap()
                    .resource_size,
                std::fs::metadata(&path).unwrap().len() as i64
            );
            assert_ne!(
                probe::load_snapshot_map(&db, &library.library_id)
                    .await
                    .unwrap(),
                baseline
            );
        });
    });
}
