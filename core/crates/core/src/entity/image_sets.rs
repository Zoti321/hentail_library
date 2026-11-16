use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_sets")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_set_id: String,
    pub library_id: String,
    /// `/`-separated path under the Library root; empty for the Library root image set.
    pub relative_path: String,
    /// Folder basename; empty for the Library root image set.
    pub name: String,
    pub is_root: bool,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
