use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "comic_meta")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub comic_id: String,
    pub title: String,
    pub content_rating: String,
    pub page_count: i32,
    pub description: Option<String>,
    pub published_at: Option<i64>,
    pub title_locked: bool,
    pub description_locked: bool,
    pub published_at_locked: bool,
    pub content_rating_locked: bool,
    pub authors_locked: bool,
    pub tags_locked: bool,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
