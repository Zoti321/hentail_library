use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_set_images")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_set_image_id: String,
    pub library_id: String,
    pub image_set_id: String,
    pub carrier_relative_path: String,
    /// Empty for loose images; archive entry path otherwise.
    pub member_path: String,
    pub carrier_kind: String,
    pub name: String,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
