use sea_orm::entity::prelude::*;

#[derive(Clone, Debug, PartialEq, Eq, DeriveEntityModel)]
#[sea_orm(table_name = "image_sets")]
pub struct Model {
    #[sea_orm(primary_key, auto_increment = false)]
    pub image_set_id: String,
    pub library_id: String,
    /// `/`-separated path under the Library root (first-level folder or archive name).
    pub relative_path: String,
    /// Display name; sync scan source is the `relative_path` basename.
    pub name: String,
    /// Legacy flag; new sync no longer creates Library root image sets (ADR-0062).
    pub is_root: bool,
    pub name_locked: bool,
}

#[derive(Copy, Clone, Debug, EnumIter, DeriveRelation)]
pub enum Relation {}

impl ActiveModelBehavior for ActiveModel {}
