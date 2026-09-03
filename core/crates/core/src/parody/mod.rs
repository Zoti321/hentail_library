use sea_orm::{EntityTrait, QueryOrder};

use crate::db::{connection, map_db_err};
use crate::entity::{parodies, prelude::*};
use crate::error::HentaiError;

pub async fn list_all_parodies() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = Parodies::find()
        .order_by_asc(parodies::Column::Name)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.name).collect())
}
