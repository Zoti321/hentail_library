use sea_orm_migration::prelude::*;

mod m20240630_000002_drift_v2_seed;
mod m20240630_000003_thumbnail_columns;
mod m20240703_000004_drop_series_reading_histories;
mod m20250705_000005_comic_meta_split;
mod m20250705_000006_folder_series;
mod m20250705_000007_restore_series_reading_histories;
mod m20260717_000008_ensure_greenfield_schema;
mod m20260718_000009_user_set_and_series_thumbnails;
mod m20260801_000010_drop_series_reading_histories;
mod m20260801_000011_series_item_sort_order_real;
mod m20260801_000012_metadata_field_locks;
mod m20260805_000013_title_name_sort_keys;
mod m20260812_000014_multi_local_libraries;
mod m20260812_000015_remote_library_fields;

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
            Box::new(m20260718_000009_user_set_and_series_thumbnails::Migration),
            Box::new(m20260801_000010_drop_series_reading_histories::Migration),
            Box::new(m20260801_000011_series_item_sort_order_real::Migration),
            Box::new(m20260801_000012_metadata_field_locks::Migration),
            Box::new(m20260805_000013_title_name_sort_keys::Migration),
            Box::new(m20260812_000014_multi_local_libraries::Migration),
            Box::new(m20260812_000015_remote_library_fields::Migration),
        ]
    }
}
