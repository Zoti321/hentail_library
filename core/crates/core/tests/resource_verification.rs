mod common;

use hentai_core::resource_verification::{
    verify_comic_resource, ResourceVerificationMode, ResourceVerificationStatus,
};
use hentai_core::*;
use sea_orm::{ConnectionTrait, Statement};

#[test]
fn persisted_fingerprint_is_projected_and_verification_never_accepts_a_new_baseline() {
    common::with_global_db(|| {
        let root = tempfile::tempdir().unwrap().keep();
        let library_root = root.join("library");
        let path = library_root.join("book.cbz");
        common::write_cbz(&path, 1);
        tokio::runtime::Runtime::new().unwrap().block_on(async {
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
            let id = comic_id_from_path(&path.to_string_lossy());
            let comic = find_comic_by_id(&id).await.unwrap().unwrap();
            let fingerprint = comic.resource_fingerprint.unwrap();
            assert!(fingerprint.digest.starts_with("sha256-file-v1:"));
            assert_eq!(
                fingerprint.size,
                std::fs::metadata(&path).unwrap().len() as i64
            );
            assert_eq!(
                verify_comic_resource(&id, ResourceVerificationMode::Quick)
                    .await
                    .unwrap()
                    .status,
                ResourceVerificationStatus::NotDetected
            );
            assert_eq!(
                verify_comic_resource(&id, ResourceVerificationMode::Strict)
                    .await
                    .unwrap()
                    .status,
                ResourceVerificationStatus::ContentMatches
            );

            let modified = std::fs::metadata(&path).unwrap().modified().unwrap();
            let mut bytes = std::fs::read(&path).unwrap();
            bytes[0] ^= 1;
            std::fs::write(&path, bytes).unwrap();
            std::fs::File::options()
                .write(true)
                .open(&path)
                .unwrap()
                .set_times(std::fs::FileTimes::new().set_modified(modified))
                .unwrap();
            assert_eq!(
                verify_comic_resource(&id, ResourceVerificationMode::Quick)
                    .await
                    .unwrap()
                    .status,
                ResourceVerificationStatus::NotDetected
            );
            assert_eq!(
                verify_comic_resource(&id, ResourceVerificationMode::Strict)
                    .await
                    .unwrap()
                    .status,
                ResourceVerificationStatus::ContentChanged
            );
            assert_eq!(
                find_comic_by_id(&id)
                    .await
                    .unwrap()
                    .unwrap()
                    .resource_fingerprint
                    .unwrap(),
                fingerprint
            );

            let db = connection().unwrap();
            db.execute(Statement::from_sql_and_values(
                db.get_database_backend(),
                "DELETE FROM comic_content_fingerprints WHERE comic_id = ?",
                [id.clone().into()],
            ))
            .await
            .unwrap();
            assert!(find_comic_by_id(&id)
                .await
                .unwrap()
                .unwrap()
                .resource_fingerprint
                .is_none());
            assert_eq!(
                verify_comic_resource(&id, ResourceVerificationMode::Strict)
                    .await
                    .unwrap()
                    .status,
                ResourceVerificationStatus::BaselineUnavailable
            );
            std::fs::remove_file(&path).unwrap();
            assert_eq!(
                verify_comic_resource(&id, ResourceVerificationMode::Strict)
                    .await
                    .unwrap()
                    .status,
                ResourceVerificationStatus::Missing
            );
        });
    });
}
