use sea_orm_migration::prelude::*;

#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager.get_connection().execute_unprepared(
            "CREATE TABLE IF NOT EXISTS image_sets (
                image_set_id TEXT PRIMARY KEY NOT NULL,
                library_id TEXT NOT NULL REFERENCES libraries(library_id) ON DELETE CASCADE ON UPDATE CASCADE,
                relative_path TEXT NOT NULL,
                name TEXT NOT NULL,
                is_root INTEGER NOT NULL DEFAULT 0 CHECK (is_root IN (0, 1)),
                UNIQUE (library_id, relative_path)
            );
            CREATE TABLE IF NOT EXISTS image_set_carriers (
                library_id TEXT NOT NULL REFERENCES libraries(library_id) ON DELETE CASCADE ON UPDATE CASCADE,
                carrier_relative_path TEXT NOT NULL,
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                carrier_kind TEXT NOT NULL,
                observed_size INTEGER NOT NULL,
                observed_modified_ms INTEGER NOT NULL,
                PRIMARY KEY (library_id, carrier_relative_path)
            );
            CREATE TABLE IF NOT EXISTS image_set_images (
                image_set_image_id TEXT PRIMARY KEY NOT NULL,
                library_id TEXT NOT NULL REFERENCES libraries(library_id) ON DELETE CASCADE ON UPDATE CASCADE,
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                carrier_relative_path TEXT NOT NULL,
                member_path TEXT NOT NULL,
                carrier_kind TEXT NOT NULL,
                name TEXT NOT NULL,
                UNIQUE (library_id, carrier_relative_path, member_path)
            );
            CREATE INDEX IF NOT EXISTS image_set_images_by_set ON image_set_images(image_set_id);",
        )
        .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
