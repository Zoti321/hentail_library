use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "author_image_cache")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub author_link_id: i64,
    #[sea_orm(primary_key, auto_increment = false)]
    pub slot: String,
    pub profile_url: String,
    pub image_url: Option<String>,
    pub checked_at: i64,
    pub fetched_at: Option<i64>,
    pub cache_key: Option<String>,
    pub link_version: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
