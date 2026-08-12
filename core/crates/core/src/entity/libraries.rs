use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "libraries")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub library_id: String,
    pub kind: String,
    #[sea_orm(unique)]
    pub root_path: String,
    pub name: String,
    pub enabled_format_groups: String,
    pub created_at: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
