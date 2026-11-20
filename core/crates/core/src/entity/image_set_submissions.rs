use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_set_submissions")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub submission_id: String,
    pub library_id: String,
    pub image_set_id: String,
    pub name: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
