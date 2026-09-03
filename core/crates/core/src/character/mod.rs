use sea_orm::{EntityTrait, QueryOrder};

use crate::db::{connection, map_db_err};
use crate::entity::{characters, prelude::*};
use crate::error::HentaiError;

pub async fn list_all_characters() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = Characters::find()
        .order_by_asc(characters::Column::Name)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.name).collect())
}
