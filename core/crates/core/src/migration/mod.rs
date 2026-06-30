use sea_orm_migration::prelude::*;

mod m20240630_000002_drift_v2_seed;
mod m20240630_000003_thumbnail_columns;

pub struct Migrator;

#[async_trait::async_trait]
impl MigratorTrait for Migrator {
    fn migrations() -> Vec<Box<dyn MigrationTrait>> {
        vec![
            Box::new(m20240630_000002_drift_v2_seed::Migration),
            Box::new(m20240630_000003_thumbnail_columns::Migration),
        ]
    }
}
