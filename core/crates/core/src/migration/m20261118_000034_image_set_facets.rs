use sea_orm_migration::prelude::*;

/// Image set Author / Tag / Parody / Character bindings on the global dictionaries.
/// No facet lock columns: sync has no facet scan source.
#[derive(DeriveMigrationName)]
pub struct Migration;

#[async_trait::async_trait]
impl MigrationTrait for Migration {
    async fn up(&self, manager: &SchemaManager) -> Result<(), DbErr> {
        manager
            .get_connection()
            .execute_unprepared(
                "CREATE TABLE IF NOT EXISTS image_set_authors (
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                author_id INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
                PRIMARY KEY (image_set_id, author_id)
            );
            CREATE TABLE IF NOT EXISTS image_set_tags (
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                tag_name TEXT NOT NULL REFERENCES tags(name) ON DELETE CASCADE,
                PRIMARY KEY (image_set_id, tag_name)
            );
            CREATE TABLE IF NOT EXISTS image_set_parodies (
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                parody_name TEXT NOT NULL REFERENCES parodies(name) ON DELETE CASCADE,
                PRIMARY KEY (image_set_id, parody_name)
            );
            CREATE TABLE IF NOT EXISTS image_set_characters (
                image_set_id TEXT NOT NULL REFERENCES image_sets(image_set_id) ON DELETE CASCADE ON UPDATE CASCADE,
                character_name TEXT NOT NULL REFERENCES characters(name) ON DELETE CASCADE,
                PRIMARY KEY (image_set_id, character_name)
            );
            CREATE INDEX IF NOT EXISTS image_set_authors_by_author ON image_set_authors(author_id);
            CREATE INDEX IF NOT EXISTS image_set_tags_by_name ON image_set_tags(tag_name);
            CREATE INDEX IF NOT EXISTS image_set_parodies_by_name ON image_set_parodies(parody_name);
            CREATE INDEX IF NOT EXISTS image_set_characters_by_name ON image_set_characters(character_name);",
            )
            .await?;
        Ok(())
    }

    async fn down(&self, _manager: &SchemaManager) -> Result<(), DbErr> {
        Ok(())
    }
}
