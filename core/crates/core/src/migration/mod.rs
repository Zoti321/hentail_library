use sea_orm_migration::prelude::*;

mod m20240630_000002_drift_v2_seed;
mod m20240630_000003_thumbnail_columns;
mod m20240703_000004_drop_series_reading_histories;
mod m20250705_000005_comic_meta_split;
mod m20250705_000006_folder_series;
mod m20250705_000007_restore_series_reading_histories;
mod m20260717_000008_ensure_greenfield_schema;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20240630_000002_drift_v2_seed::Migration),
            Box::new(m20240630_000003_thumbnail_columns::Migration),
            Box::new(m20240703_000004_drop_series_reading_histories::Migration),
            Box::new(m20250705_000005_comic_meta_split::Migration),
            Box::new(m20250705_000006_folder_series::Migration),
            Box::new(m20250705_000007_restore_series_reading_histories::Migration),
            Box::new(m20260717_000008_ensure_greenfield_schema::Migration),
        ]
    }
}
