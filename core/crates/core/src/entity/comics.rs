use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "comics")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub comic_id: String,
    pub path: String,
    pub resource_type: String,
    pub title: String,
    pub content_rating: String,
    pub page_count: Option<i32>,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
