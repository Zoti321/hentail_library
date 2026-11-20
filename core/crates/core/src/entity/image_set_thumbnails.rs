use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_set_thumbnails")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_set_id: String,
    pub thumbnail: Vec<u8>,
    pub source_image_set_image_id: String,
    pub source_modified_ms: i64,
    pub source_size: i64,
    pub updated_at: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
