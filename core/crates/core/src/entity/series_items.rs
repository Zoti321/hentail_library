use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, DeriveEntityModel)]
#[sea_orm(table_name = "series_items")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub series_id: String,
    #[sea_orm(primary_key, auto_increment = false)]
    pub comic_id: String,
    pub sort_order: f64,
    pub sort_order_locked: bool,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
