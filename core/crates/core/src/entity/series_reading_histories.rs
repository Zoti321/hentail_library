use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "series_reading_histories")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub series_id: String,
    pub last_read_comic_id: String,
    pub last_read_time: i64,
    pub page_index: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
