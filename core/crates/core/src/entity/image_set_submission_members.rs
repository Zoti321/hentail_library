use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_set_submission_members")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub submission_id: String,
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_set_image_id: String,
    pub sort_order: i64,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
