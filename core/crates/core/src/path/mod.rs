use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, Set,
};

use crate::comic::read_data_version;
use crate::db::{connection, map_db_err};
use crate::entity::{prelude::*, saved_paths};
use crate::error::HentaiError;

pub async fn list_all_paths() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = SavedPaths::find().all(&db).await.map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.raw_path).collect())
}

pub async fn add_path(raw_path: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    let active = saved_paths::ActiveModel {
        raw_path: Set(raw_path.to_string()),
        security_bookmark: Set(None),
        ..Default::default()
    };
    SavedPaths::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(saved_paths::Column::RawPath)
                .do_nothing()
                .to_owned(),
        )
        .do_nothing()
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn remove_path(raw_path: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    SavedPaths::delete_many()
        .filter(saved_paths::Column::RawPath.eq(raw_path))
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn watch_paths(
    mut emit: impl FnMut(Vec<String>) -> Result<(), HentaiError>,
) -> Result<(), HentaiError> {
    let mut last = read_data_version().await?;
    emit(list_all_paths().await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = read_data_version().await?;
        if version != last {
            last = version;
            emit(list_all_paths().await?)?;
        }
    }
}
