use sea_orm::entity::prelude::*;

/// Archive carrier observed by the last successful Image set sync (loose images have no row).
#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_set_carriers")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub library_id: String,
    #[sea_orm(primary_key, auto_increment = false)]
    pub carrier_relative_path: String,
    pub image_set_id: String,
    pub carrier_kind: String,
    pub observed_size: i64,
    pub observed_modified_ms: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
