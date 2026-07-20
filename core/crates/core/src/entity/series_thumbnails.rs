use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "series_thumbnails")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub series_id: String,
    pub thumbnail: Vec<u8>,
    pub updated_at: i64,
    pub source_comic_id: String,
    pub source_page_index: i32,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
