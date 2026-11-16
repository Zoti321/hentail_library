use sea_orm::{ColumnTrait, DatabaseConnection, EntityTrait, QueryFilter, TransactionTrait};

use crate::db::map_db_err;
use crate::entity::{image_set_carriers, image_set_images, image_sets};
use crate::error::HentaiError;
use crate::library::{record_library_sync_failure, record_library_sync_success_in, LibraryDto};
use crate::resource::local_access;
use crate::sync::{
    LibrarySyncCountsDto, SyncHandle, SyncLibraryPhaseDto, SyncLibraryProgressDto,
    SyncLibraryRouteDto,
};

use super::discovery::{observe_library, PriorCarrierStats};
use super::plan::{plan_image_set_sync, ImageSetPlan, PriorCatalog};
use super::writer::apply_image_set_plan;

/// Manual Image set sync for one Image set library.
///
/// `Ok(None)` means cancelled with nothing written. An unreadable root returns a warning-only
/// progress and records the failure, leaving every record untouched.
pub(crate) async fn sync_image_set_library(
    db: &DatabaseConnection,
    handle: &SyncHandle,
    library: &LibraryDto,
    emit: &mut impl FnMut(SyncLibraryProgressDto),
) -> Result<Option<SyncLibraryProgressDto>, HentaiError> {
    let library_id = library.library_id.as_str();
    let root = library.root_path.as_str();
    if let Err(err) = local_access().probe_root(root) {
        let warning = format!("已跳过不可读的图集库 {root}: {}", err.message);
        tracing::warn!("{warning}");
        record_library_sync_failure(library_id, &warning).await?;
        return Ok(Some(progress(
            SyncLibraryPhaseDto::Scanning,
            0,
            Some(warning),
        )));
    }
    emit(progress(SyncLibraryPhaseDto::Scanning, 0, None));

    let prior = load_prior(db, library_id).await?;
    let prior_stats: PriorCarrierStats = prior
        .carriers
        .iter()
        .map(|c| {
            (
                c.carrier_relative_path.clone(),
                (c.observed_size, c.observed_modified_ms),
            )
        })
        .collect();
    let Some(obs) = observe_library(root, &prior_stats, handle)? else {
        return Ok(None);
    };
    let plan = plan_image_set_sync(library_id, &obs, &prior);
    emit(progress(SyncLibraryPhaseDto::WritingDb, 0, None));

    let txn = db.begin().await.map_err(map_db_err)?;
    let writes: Result<(), HentaiError> = async {
        apply_image_set_plan(&txn, library_id, &plan).await?;
        record_library_sync_success_in(&txn, library_id).await?;
        Ok(())
    }
    .await;
    if let Err(error) = writes {
        txn.rollback().await.map_err(map_db_err)?;
        return Err(error);
    }
    if handle.is_cancelled() {
        txn.rollback().await.map_err(map_db_err)?;
        return Ok(None);
    }
    txn.commit().await.map_err(map_db_err)?;
    crate::revision::notify_committed();

    tracing::info!(
        added = plan.images_insert.len(),
        removed = plan.images_delete.len(),
        warnings = plan.warnings.len(),
        "image set sync write complete"
    );
    Ok(Some(success_progress(&plan)))
}

async fn load_prior(
    db: &DatabaseConnection,
    library_id: &str,
) -> Result<PriorCatalog, HentaiError> {
    Ok(PriorCatalog {
        sets: image_sets::Entity::find()
            .filter(image_sets::Column::LibraryId.eq(library_id))
            .all(db)
            .await
            .map_err(map_db_err)?,
        images: image_set_images::Entity::find()
            .filter(image_set_images::Column::LibraryId.eq(library_id))
            .all(db)
            .await
            .map_err(map_db_err)?,
        carriers: image_set_carriers::Entity::find()
            .filter(image_set_carriers::Column::LibraryId.eq(library_id))
            .all(db)
            .await
            .map_err(map_db_err)?,
    })
}

fn success_progress(plan: &ImageSetPlan) -> SyncLibraryProgressDto {
    let mut done = progress(
        SyncLibraryPhaseDto::WritingDb,
        plan.kept_count as i32 + plan.images_insert.len() as i32,
        (!plan.warnings.is_empty()).then(|| plan.warnings.join("\n")),
    );
    done.added_count = Some(plan.images_insert.len() as i32);
    done.removed_count = Some(plan.images_delete.len() as i32);
    done.kept_count = Some(plan.kept_count as i32);
    done
}

fn progress(
    phase: SyncLibraryPhaseDto,
    accepted_total: i32,
    error_message: Option<String>,
) -> SyncLibraryProgressDto {
    SyncLibraryProgressDto {
        phase,
        route: SyncLibraryRouteDto::WithRoots,
        current_path: None,
        accepted_total,
        counts: LibrarySyncCountsDto::default(),
        removed_count: None,
        added_count: None,
        kept_count: None,
        migrated_count: None,
        thumbnail_total: None,
        thumbnail_done: None,
        thumbnail_failed_count: None,
        error_message,
    }
}
