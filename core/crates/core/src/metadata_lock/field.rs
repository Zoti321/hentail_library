//! Metadata field table: the single list of user-editable Comic / Series fields (ADR-0007).
//!
//! ADR-0007 asks for "which fields exist, and what happens to each" to be written down once.
//! Every field a user-meta write can touch appears here exactly once, together with the value
//! column (or junction table) it writes, the `*_locked` column that records user ownership, and
//! whether a Library scan can supply the field at all. Auto-lock, lock patches and the DTO
//! coverage checks all iterate this table, so adding a field is "add a variant + add a
//! migration" — and the guard tests at the bottom fail when the `comic_meta` / `series` /
//! junction schema drifts from the table.

/// User-editable Comic Metadata field; one lock column per field (ADR-0007).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum ComicMetaField {
    Title,
    Description,
    PublishedAt,
    ContentRating,
    Authors,
    Tags,
    Languages,
    Parodies,
    Characters,
}

/// Where a field's value rows live; the `*_locked` owner flag is always a `comic_meta` column.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComicMetaStorage {
    /// Value column on `comic_meta`.
    Column,
    /// One value row per name in a junction table (`comic_authors`, `comic_tags`, ...).
    Junction {
        table: &'static str,
        /// Junction column carrying the value: a name column for tags / parodies / characters,
        /// `author_id` for the stable-identity Author table (ADR-0024, name lives in `authors`).
        key_column: &'static str,
    },
}

impl ComicMetaField {
    /// Every field, in the canonical metadata order used by writes and locks — not the physical
    /// `comic_meta` column order (`content_rating` is created before `description`).
    pub const ALL: [ComicMetaField; 9] = [
        ComicMetaField::Title,
        ComicMetaField::Description,
        ComicMetaField::PublishedAt,
        ComicMetaField::ContentRating,
        ComicMetaField::Authors,
        ComicMetaField::Tags,
        ComicMetaField::Languages,
        ComicMetaField::Parodies,
        ComicMetaField::Characters,
    ];

    /// Lock key and `ComicMetaLocks` serde key; the `comic_meta` value column when
    /// [`Self::storage`] is [`ComicMetaStorage::Column`].
    pub const fn as_str(self) -> &'static str {
        match self {
            ComicMetaField::Title => "title",
            ComicMetaField::Description => "description",
            ComicMetaField::PublishedAt => "published_at",
            ComicMetaField::ContentRating => "content_rating",
            ComicMetaField::Authors => "authors",
            ComicMetaField::Tags => "tags",
            ComicMetaField::Languages => "languages",
            ComicMetaField::Parodies => "parodies",
            ComicMetaField::Characters => "characters",
        }
    }

    /// `comic_meta` lock column; a user meta write for this field sets it to `true`.
    pub const fn lock_column(self) -> &'static str {
        match self {
            ComicMetaField::Title => "title_locked",
            ComicMetaField::Description => "description_locked",
            ComicMetaField::PublishedAt => "published_at_locked",
            ComicMetaField::ContentRating => "content_rating_locked",
            ComicMetaField::Authors => "authors_locked",
            ComicMetaField::Tags => "tags_locked",
            ComicMetaField::Languages => "languages_locked",
            ComicMetaField::Parodies => "parodies_locked",
            ComicMetaField::Characters => "characters_locked",
        }
    }

    /// Where this field's value rows live (ADR-0007 field table).
    pub const fn storage(self) -> ComicMetaStorage {
        match self {
            ComicMetaField::Title
            | ComicMetaField::Description
            | ComicMetaField::PublishedAt
            | ComicMetaField::ContentRating
            | ComicMetaField::Languages => ComicMetaStorage::Column,
            ComicMetaField::Authors => ComicMetaStorage::Junction {
                table: "comic_authors",
                key_column: "author_id",
            },
            ComicMetaField::Tags => ComicMetaStorage::Junction {
                table: "comic_tags",
                key_column: "tag_name",
            },
            ComicMetaField::Parodies => ComicMetaStorage::Junction {
                table: "comic_parodies",
                key_column: "parody_name",
            },
            ComicMetaField::Characters => ComicMetaStorage::Junction {
                table: "comic_characters",
                key_column: "character_name",
            },
        }
    }

    /// Whether Library sync / Metadata refresh can derive this field from the Resource. All nine
    /// Comic fields are scanned, so for Comic the lock — not a missing scan source — is what keeps
    /// a stored value; the ADR-0007 merge rules still apply on top (a `content_rating` scan of
    /// `unknown` and an empty multi-value scan never overwrite — see `metadata_lock::comic`).
    ///
    /// This is a declared contract pinned by `scan_sources_match_adr_0007`, not a runtime switch:
    /// each field's merge path has its own signature, so the rule lives in `metadata_lock::comic`.
    pub const fn has_scan_source(self) -> bool {
        match self {
            ComicMetaField::Title
            | ComicMetaField::Description
            | ComicMetaField::PublishedAt
            | ComicMetaField::ContentRating
            | ComicMetaField::Authors
            | ComicMetaField::Tags
            | ComicMetaField::Languages
            | ComicMetaField::Parodies
            | ComicMetaField::Characters => true,
        }
    }

    /// Position in [`Self::ALL`]; the table is the only ordering source.
    pub fn index(self) -> usize {
        Self::ALL
            .iter()
            .position(|field| *field == self)
            .expect("ComicMetaField::ALL must contain every variant")
    }
}

/// User-editable Series Metadata field; one lock column per field (ADR-0007).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum SeriesMetaField {
    Name,
    SerializationStatus,
    TotalCount,
}

impl SeriesMetaField {
    /// Every field, in `series` column order.
    pub const ALL: [SeriesMetaField; 3] = [
        SeriesMetaField::Name,
        SeriesMetaField::SerializationStatus,
        SeriesMetaField::TotalCount,
    ];

    /// `series` value column and lock-flag base (`{as_str}_locked`); the guard test
    /// `series_locks_mirror_the_field_table` keeps it aligned with `SeriesMetaLocks`'s field names.
    pub const fn as_str(self) -> &'static str {
        match self {
            SeriesMetaField::Name => "name",
            SeriesMetaField::SerializationStatus => "serialization_status",
            SeriesMetaField::TotalCount => "total_count",
        }
    }

    /// `series` lock column; a user meta write for this field sets it to `true`.
    pub const fn lock_column(self) -> &'static str {
        match self {
            SeriesMetaField::Name => "name_locked",
            SeriesMetaField::SerializationStatus => "serialization_status_locked",
            SeriesMetaField::TotalCount => "total_count_locked",
        }
    }

    /// Only the folder name is derived from the Library; status and count are user-only, so
    /// Library sync never rewrites them (ADR-0007). Declared contract, pinned by
    /// `scan_sources_match_adr_0007`; the merge itself lives in `metadata_lock::series`.
    pub const fn has_scan_source(self) -> bool {
        matches!(self, SeriesMetaField::Name)
    }

    /// Position in [`Self::ALL`]; the table is the only ordering source.
    pub fn index(self) -> usize {
        Self::ALL
            .iter()
            .position(|field| *field == self)
            .expect("SeriesMetaField::ALL must contain every variant")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sea_orm::{ConnectionTrait, Database, DatabaseBackend, Statement};
    use sea_orm_migration::MigratorTrait;

    /// Post-migration schema: every table with its `PRAGMA table_info` column names.
    struct Schema {
        columns: std::collections::BTreeMap<String, Vec<String>>,
    }

    impl Schema {
        fn columns_of(&self, table: &str) -> Vec<String> {
            self.columns
                .get(table)
                .unwrap_or_else(|| panic!("迁移后不存在表 {table}"))
                .clone()
        }

        fn has_column(&self, table: &str, column: &str) -> bool {
            self.columns_of(table).iter().any(|name| name == column)
        }
    }

    /// Run every migration against an in-memory database and read the resulting schema.
    async fn migrated_schema() -> Schema {
        let db = Database::connect("sqlite::memory:")
            .await
            .expect("in-memory db");
        crate::migration::Migrator::up(&db, None)
            .await
            .expect("run migrations");

        let names: Vec<String> = db
            .query_all(Statement::from_string(
                DatabaseBackend::Sqlite,
                "SELECT name FROM sqlite_master WHERE type = 'table'".to_string(),
            ))
            .await
            .expect("list tables")
            .into_iter()
            .map(|row| row.try_get_by_index::<String>(0).expect("table name"))
            .collect();

        let mut columns = std::collections::BTreeMap::new();
        for name in names {
            columns.insert(name.clone(), table_columns(&db, &name).await);
        }
        Schema { columns }
    }

    async fn table_columns(db: &sea_orm::DatabaseConnection, table: &str) -> Vec<String> {
        db.query_all(Statement::from_string(
            DatabaseBackend::Sqlite,
            format!("PRAGMA table_info('{table}')"),
        ))
        .await
        .expect("table_info")
        .into_iter()
        .map(|row| row.try_get_by_index::<String>(1).expect("column name"))
        .collect()
    }

    #[tokio::test]
    async fn comic_meta_columns_cover_every_field() {
        let schema = migrated_schema().await;
        let columns = schema.columns_of("comic_meta");

        for field in ComicMetaField::ALL {
            assert!(
                columns.iter().any(|column| column == field.lock_column()),
                "comic_meta 缺少锁列 {}，请补齐迁移",
                field.lock_column()
            );
            match field.storage() {
                ComicMetaStorage::Column => assert!(
                    columns.iter().any(|column| column == field.as_str()),
                    "comic_meta 缺少值列 {}，请补齐迁移",
                    field.as_str()
                ),
                ComicMetaStorage::Junction { table, key_column } => {
                    assert!(
                        schema.has_column(table, key_column),
                        "字段 {field:?} 的附着表 {table} 缺少 {key_column}，请补齐迁移"
                    );
                    assert!(
                        !columns.iter().any(|column| column == field.as_str()),
                        "字段 {field:?} 的值在 {table}，comic_meta 不应再有 {} 列",
                        field.as_str()
                    );
                }
            }
        }
        for column in columns.iter().filter(|column| column.ends_with("_locked")) {
            assert!(
                ComicMetaField::ALL
                    .iter()
                    .any(|field| field.lock_column() == column),
                "comic_meta 的锁列 {column} 未登记进 ComicMetaField"
            );
        }
    }

    #[tokio::test]
    async fn series_columns_cover_every_field() {
        let schema = migrated_schema().await;
        let columns = schema.columns_of("series");

        for field in SeriesMetaField::ALL {
            assert!(
                columns.iter().any(|column| column == field.as_str()),
                "series 缺少值列 {}，请补齐迁移",
                field.as_str()
            );
            assert!(
                columns.iter().any(|column| column == field.lock_column()),
                "series 缺少锁列 {}，请补齐迁移",
                field.lock_column()
            );
        }
        for column in columns.iter().filter(|column| column.ends_with("_locked")) {
            assert!(
                SeriesMetaField::ALL
                    .iter()
                    .any(|field| field.lock_column() == column),
                "series 的锁列 {column} 未登记进 SeriesMetaField"
            );
        }
    }

    #[test]
    fn field_tables_list_every_variant() {
        // The exhaustive `match` arms (`as_str` / `lock_column` / `storage` / `has_scan_source`)
        // already fail to compile for a new variant; this test is what forces it into `ALL`, which
        // the guard tests and `index()` iterate.
        assert_eq!(
            ComicMetaField::ALL,
            [
                ComicMetaField::Title,
                ComicMetaField::Description,
                ComicMetaField::PublishedAt,
                ComicMetaField::ContentRating,
                ComicMetaField::Authors,
                ComicMetaField::Tags,
                ComicMetaField::Languages,
                ComicMetaField::Parodies,
                ComicMetaField::Characters,
            ],
            "新增 ComicMetaField 变体时必须同时加进 ALL"
        );
        assert_eq!(
            SeriesMetaField::ALL,
            [
                SeriesMetaField::Name,
                SeriesMetaField::SerializationStatus,
                SeriesMetaField::TotalCount,
            ],
            "新增 SeriesMetaField 变体时必须同时加进 ALL"
        );
    }

    #[test]
    fn field_tables_are_internally_consistent() {
        for (position, field) in ComicMetaField::ALL.iter().enumerate() {
            assert_eq!(
                field.index(),
                position,
                "{field:?} 的 index() 与 ALL 顺序不一致"
            );
            assert_eq!(field.lock_column(), format!("{}_locked", field.as_str()));
        }
        for (position, field) in SeriesMetaField::ALL.iter().enumerate() {
            assert_eq!(
                field.index(),
                position,
                "{field:?} 的 index() 与 ALL 顺序不一致"
            );
            assert_eq!(field.lock_column(), format!("{}_locked", field.as_str()));
        }

        let mut comic_keys: Vec<&str> = ComicMetaField::ALL.iter().map(|f| f.as_str()).collect();
        comic_keys.sort_unstable();
        comic_keys.dedup();
        assert_eq!(comic_keys.len(), ComicMetaField::ALL.len());

        let mut series_keys: Vec<&str> = SeriesMetaField::ALL.iter().map(|f| f.as_str()).collect();
        series_keys.sort_unstable();
        series_keys.dedup();
        assert_eq!(series_keys.len(), SeriesMetaField::ALL.len());
    }

    #[test]
    fn scan_sources_match_adr_0007() {
        assert!(ComicMetaField::ALL
            .iter()
            .all(|field| field.has_scan_source()));

        let scanned: Vec<SeriesMetaField> = SeriesMetaField::ALL
            .iter()
            .copied()
            .filter(|field| field.has_scan_source())
            .collect();
        assert_eq!(scanned, vec![SeriesMetaField::Name]);
    }

    #[test]
    fn series_locks_mirror_the_field_table() {
        // `SeriesMetaLocks` carries no serde keys, so the pin is this exhaustive match: a new
        // `SeriesMetaField` variant breaks it and forces the matching lock flag to be declared.
        let locks = crate::SeriesMetaLocks {
            name: true,
            serialization_status: false,
            total_count: true,
        };
        let pairs: Vec<(&str, bool)> = SeriesMetaField::ALL
            .iter()
            .map(|field| {
                let locked = match field {
                    SeriesMetaField::Name => locks.name,
                    SeriesMetaField::SerializationStatus => locks.serialization_status,
                    SeriesMetaField::TotalCount => locks.total_count,
                };
                (field.as_str(), locked)
            })
            .collect();
        assert_eq!(
            pairs,
            vec![
                ("name", true),
                ("serialization_status", false),
                ("total_count", true)
            ],
            "SeriesMetaLocks 的字段必须能对回字段表"
        );
    }

    #[test]
    fn comic_meta_locks_serde_keys_match_field_table() {
        let all_locked = crate::comic::ComicMetaLocks {
            title: true,
            description: true,
            published_at: true,
            content_rating: true,
            authors: true,
            tags: true,
            languages: true,
            parodies: true,
            characters: true,
        };
        let value = serde_json::to_value(&all_locked).expect("serialize ComicMetaLocks");
        let mut keys: Vec<String> = value
            .as_object()
            .expect("ComicMetaLocks serializes to an object")
            .keys()
            .cloned()
            .collect();
        keys.sort();

        let mut expected: Vec<String> = ComicMetaField::ALL
            .iter()
            .map(|field| field.as_str().to_string())
            .collect();
        expected.sort();

        assert_eq!(keys, expected, "ComicMetaLocks 的 JSON 键必须与字段表一致");
    }
}
