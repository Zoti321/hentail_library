use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "series")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub series_id: String,
    #[sea_orm(unique)]
    pub folder_path: String,
    pub name: String,
    pub name_sort_key: String,
    pub serialization_status: String,
    pub total_count: Option<i32>,
    pub name_locked: bool,
    pub serialization_status_locked: bool,
    pub total_count_locked: bool,
    pub library_id: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
