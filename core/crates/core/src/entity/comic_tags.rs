use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "comic_tags")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub comic_id: String,
    #[sea_orm(primary_key, auto_increment = false)]
    pub tag_name: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
