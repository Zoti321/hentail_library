use sea_orm::{
    ActiveModelTrait, ColumnTrait, EntityTrait, PaginatorTrait, QueryFilter, QueryOrder, QuerySelect,
    Set, TransactionTrait,
};

use crate::comic::read_data_version;
use crate::db::{connection, map_db_err};
use crate::entity::{comic_tags, prelude::*, tags};
use crate::error::HentaiError;

pub async fn list_all_tags() -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = Tags::find()
        .order_by_asc(tags::Column::Name)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.name).collect())
}

pub async fn count_all_tags() -> Result<i64, HentaiError> {
    let db = connection()?;
    Tags::find().count(&db).await.map_err(map_db_err).map(|c| c as i64)
}

pub async fn fetch_tags_page(limit: i32, offset: i32) -> Result<Vec<String>, HentaiError> {
    let db = connection()?;
    let rows = Tags::find()
        .order_by_asc(tags::Column::Name)
        .limit(limit as u64)
        .offset(offset as u64)
        .all(&db)
        .await
        .map_err(map_db_err)?;
    Ok(rows.into_iter().map(|r| r.name).collect())
}

pub async fn add_tag(name: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    let active = tags::ActiveModel {
        name: Set(name.to_string()),
        ..Default::default()
    };
    Tags::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(tags::Column::Name)
                .do_nothing()
                .to_owned(),
        )
        .do_nothing()
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn delete_tags_by_names(names: Vec<String>) -> Result<(), HentaiError> {
    if names.is_empty() {
        return Ok(());
    }
    let db = connection()?;
    Tags::delete_many()
        .filter(tags::Column::Name.is_in(names))
        .exec(&db)
        .await
        .map_err(map_db_err)?;
    Ok(())
}

pub async fn rename_tag(old_name: &str, new_name: &str) -> Result<(), HentaiError> {
    let db = connection()?;
    let txn = db.begin().await.map_err(map_db_err)?;
    let active = tags::ActiveModel {
        name: Set(new_name.to_string()),
        ..Default::default()
    };
    Tags::insert(active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(tags::Column::Name)
                .do_nothing()
                .to_owned(),
        )
        .do_nothing()
        .exec(&txn)
        .await
        .map_err(map_db_err)?;
    ComicTags::update_many()
        .col_expr(comic_tags::Column::TagName, sea_orm::sea_query::Expr::value(new_name))
        .filter(comic_tags::Column::TagName.eq(old_name))
        .exec(&txn)
        .await
        .map_err(map_db_err)?;
    Tags::delete_many()
        .filter(tags::Column::Name.eq(old_name))
        .exec(&txn)
        .await
        .map_err(map_db_err)?;
    txn.commit().await.map_err(map_db_err)?;
    Ok(())
}

pub async fn watch_tags(mut emit: impl FnMut(Vec<String>) -> Result<(), HentaiError>) -> Result<(), HentaiError> {
    let mut last = read_data_version().await?;
    emit(list_all_tags().await?)?;
    loop {
        tokio::time::sleep(std::time::Duration::from_millis(400)).await;
        let version = read_data_version().await?;
        if version != last {
            last = version;
            emit(list_all_tags().await?)?;
        }
    }
}
