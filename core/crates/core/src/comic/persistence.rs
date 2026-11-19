//! Transaction-scoped persistence for the complete Comic write set.

use sea_orm::{
    ColumnTrait, ConnectionTrait, DatabaseTransaction, EntityTrait, NotSet, QueryFilter, Set,
    Statement,
};

use crate::comic::{now_ms, ComicDto};
use crate::db::map_db_err;
use crate::entity::{comic_meta, comic_tags, comics, prelude::*};
use crate::error::HentaiError;
use crate::named_facet::{replace_comic_named_facet, JunctionNamedFacet};
use crate::util::compute_sort_key;

pub(crate) async fn delete_comics_side_effects(
    db: &DatabaseTransaction,
    comic_ids: &[String],
) -> Result<(), HentaiError> {
    const BATCH_SIZE: usize = 500;
    if comic_ids.is_empty() {
        return Ok(());
    }
    for chunk in comic_ids.chunks(BATCH_SIZE) {
        delete_comics_side_effects_batch(db, chunk).await?;
    }
    Ok(())
}

async fn delete_comics_side_effects_batch(
    db: &DatabaseTransaction,
    comic_ids: &[String],
) -> Result<(), HentaiError> {
    if comic_ids.is_empty() {
        return Ok(());
    }
    let placeholders = comic_ids.iter().map(|_| "?").collect::<Vec<_>>().join(",");
    let values: Vec<sea_orm::Value> = comic_ids
        .iter()
        .map(|id| sea_orm::Value::String(Some(Box::new(id.clone()))))
        .collect();
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comic_reading_histories WHERE comic_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comic_finished_marks WHERE comic_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM series_items WHERE comic_id IN ({placeholders})"),
        values.clone(),
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    db.execute(Statement::from_sql_and_values(
        sea_orm::DatabaseBackend::Sqlite,
        format!("DELETE FROM comics WHERE comic_id IN ({placeholders})"),
        values,
    ))
    .await
    .map_err(|e| map_db_err(&e))?;
    Ok(())
}

/// Upsert a comic write set: `comics` + `comic_meta` + the four junction facets.
///
/// A comic whose `page_count <= 0` is not written at all, so that a placeholder
/// scan result never clobbers a real page count. Such comics are returned so the
/// caller can tell "wrote nothing" apart from "wrote successfully"; every write
/// the function does perform happens in the caller's transaction, keeping the
/// whole write set atomic.
pub(crate) async fn upsert_comics(
    db: &DatabaseTransaction,
    comics_list: &[ComicDto],
) -> Result<Vec<String>, HentaiError> {
    let mut skipped_without_pages = Vec::new();
    for comic in comics_list {
        if comic.page_count <= 0 {
            skipped_without_pages.push(comic.comic_id.clone());
            continue;
        }
        upsert_single_comic(db, comic).await?;
    }
    Ok(skipped_without_pages)
}

async fn upsert_single_comic(
    db: &DatabaseTransaction,
    comic: &ComicDto,
) -> Result<(), HentaiError> {
    let existing_comic = Comics::find_by_id(comic.comic_id.clone())
        .one(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let existing_meta = ComicMeta::find_by_id(comic.comic_id.clone())
        .one(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let is_new = existing_comic.is_none();
    let now = now_ms();
    let created_at = if is_new { now } else { comic.created_at };
    let mut changed = is_new;
    if let Some(ref row) = existing_comic {
        changed |= row.path != comic.path
            || row.resource_type != comic.resource_type
            || row.resource_size != comic.resource_size;
    }
    if let Some(ref row) = existing_meta {
        changed |= row.title != comic.title
            || row.content_rating != comic.content_rating
            || row.page_count != comic.page_count
            || row.description != comic.description
            || row.published_at != comic.published_at;
    }
    if !is_new {
        let existing_authors = load_author_names_for_comic(db, &comic.comic_id).await?;
        let existing_tags = load_tag_names_for_comic(db, &comic.comic_id).await?;
        changed |= existing_authors != comic.author_names() || existing_tags != comic.tags;
    }
    let last_updated_at = if changed { now } else { comic.last_updated_at };
    insert_comic_row(db, comic, created_at, last_updated_at).await?;
    insert_comic_meta_row(db, comic).await?;
    replace_comic_junction_facets(db, comic).await
}

async fn insert_comic_row(
    db: &DatabaseTransaction,
    comic: &ComicDto,
    created_at: i64,
    last_updated_at: i64,
) -> Result<(), HentaiError> {
    let comic_active = comics::ActiveModel {
        comic_id: Set(comic.comic_id.clone()),
        path: Set(comic.path.clone()),
        resource_type: Set(comic.resource_type.clone()),
        resource_size: Set(comic.resource_size),
        created_at: Set(created_at),
        last_updated_at: Set(last_updated_at),
        library_id: Set(comic.library_id.clone()),
        // Not in the conflict update list: sync keeps Comic trash as-is.
        deleted_at: NotSet,
    };
    Comics::insert(comic_active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(comics::Column::ComicId)
                .update_columns([
                    comics::Column::Path,
                    comics::Column::ResourceType,
                    comics::Column::ResourceSize,
                    comics::Column::LastUpdatedAt,
                    comics::Column::LibraryId,
                ])
                .to_owned(),
        )
        .exec(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(())
}

async fn insert_comic_meta_row(
    db: &DatabaseTransaction,
    comic: &ComicDto,
) -> Result<(), HentaiError> {
    let meta_active = comic_meta::ActiveModel {
        comic_id: Set(comic.comic_id.clone()),
        title: Set(comic.title.clone()),
        title_sort_key: Set(compute_sort_key(&comic.title)),
        content_rating: Set(comic.content_rating.clone()),
        page_count: Set(comic.page_count),
        description: Set(comic.description.clone()),
        published_at: Set(comic.published_at),
        title_locked: Set(comic.locks.title),
        description_locked: Set(comic.locks.description),
        published_at_locked: Set(comic.locks.published_at),
        content_rating_locked: Set(comic.locks.content_rating),
        authors_locked: Set(comic.locks.authors),
        tags_locked: Set(comic.locks.tags),
        languages: Set(crate::comic::serialize_languages(&comic.languages)),
        languages_locked: Set(comic.locks.languages),
        parodies_locked: Set(comic.locks.parodies),
        characters_locked: Set(comic.locks.characters),
    };
    ComicMeta::insert(meta_active)
        .on_conflict(
            sea_orm::sea_query::OnConflict::column(comic_meta::Column::ComicId)
                .update_columns([
                    comic_meta::Column::Title,
                    comic_meta::Column::TitleSortKey,
                    comic_meta::Column::ContentRating,
                    comic_meta::Column::PageCount,
                    comic_meta::Column::Description,
                    comic_meta::Column::PublishedAt,
                    comic_meta::Column::TitleLocked,
                    comic_meta::Column::DescriptionLocked,
                    comic_meta::Column::PublishedAtLocked,
                    comic_meta::Column::ContentRatingLocked,
                    comic_meta::Column::AuthorsLocked,
                    comic_meta::Column::TagsLocked,
                    comic_meta::Column::Languages,
                    comic_meta::Column::LanguagesLocked,
                    comic_meta::Column::ParodiesLocked,
                    comic_meta::Column::CharactersLocked,
                ])
                .to_owned(),
        )
        .exec(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    Ok(())
}

async fn replace_comic_junction_facets(
    db: &DatabaseTransaction,
    comic: &ComicDto,
) -> Result<(), HentaiError> {
    crate::author::replace_comic_authors(db, &comic.comic_id, &comic.author_names()).await?;
    replace_comic_named_facet(db, JunctionNamedFacet::Tag, &comic.comic_id, &comic.tags).await?;
    replace_comic_named_facet(
        db,
        JunctionNamedFacet::Parody,
        &comic.comic_id,
        &comic.parodies,
    )
    .await?;
    replace_comic_named_facet(
        db,
        JunctionNamedFacet::Character,
        &comic.comic_id,
        &comic.characters,
    )
    .await?;
    Ok(())
}

async fn load_author_names_for_comic<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let map = crate::author::load_author_names_for_comics(db, &[comic_id.to_string()]).await?;
    Ok(map.get(comic_id).cloned().unwrap_or_default())
}

async fn load_tag_names_for_comic<C: ConnectionTrait>(
    db: &C,
    comic_id: &str,
) -> Result<Vec<String>, HentaiError> {
    let rows = ComicTags::find()
        .filter(comic_tags::Column::ComicId.eq(comic_id))
        .all(db)
        .await
        .map_err(|e| map_db_err(&e))?;
    let mut names: Vec<String> = rows.into_iter().map(|r| r.tag_name).collect();
    names.sort();
    Ok(names)
}

#[cfg(test)]
mod tests {
    use super::*;
    use sea_orm::{Database, TransactionTrait};

    async fn purge_fixture() -> sea_orm::DatabaseConnection {
        let db = Database::connect("sqlite::memory:")
            .await
            .expect("memory db");
        db.execute_unprepared(
            "CREATE TABLE comics (
                comic_id TEXT PRIMARY KEY,
                path TEXT NOT NULL,
                resource_type TEXT NOT NULL,
                resource_size INTEGER NOT NULL,
                created_at INTEGER NOT NULL,
                last_updated_at INTEGER NOT NULL,
                library_id TEXT NOT NULL,
                deleted_at INTEGER
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE comic_reading_histories (
                comic_id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                last_read_time INTEGER NOT NULL,
                page_index INTEGER
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE series_items (
                series_id TEXT NOT NULL,
                comic_id TEXT NOT NULL,
                PRIMARY KEY (series_id, comic_id)
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE comic_finished_marks (
                comic_id TEXT NOT NULL PRIMARY KEY,
                finished_at_ms INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "CREATE TABLE reading_duration_total (
                id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
                total_ms INTEGER NOT NULL CHECK (total_ms >= 0),
                updated_at_ms INTEGER NOT NULL
            )",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comics (
                comic_id, path, resource_type, resource_size, created_at, last_updated_at, library_id, deleted_at
             ) VALUES ('a', '/a', 'zip', 1, 1, 1, 'lib', 1)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_finished_marks (comic_id, finished_at_ms) VALUES ('a', 1)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO comic_reading_histories (comic_id, title, last_read_time, page_index) \
             VALUES ('a', 'Read title', 2, 3)",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO series_items (series_id, comic_id) VALUES ('series', 'a')",
        )
        .await
        .unwrap();
        db.execute_unprepared(
            "INSERT INTO reading_duration_total (id, total_ms, updated_at_ms) VALUES (1, 120000, 1)",
        )
        .await
        .unwrap();
        db
    }

    #[tokio::test]
    #[cfg_attr(miri, ignore = "sqlite/FFI unavailable under miri")]
    async fn purge_removes_finished_mark_but_not_duration() {
        let db = purge_fixture().await;
        let txn = db.begin().await.unwrap();
        delete_comics_side_effects(&txn, &["a".to_string()])
            .await
            .unwrap();
        txn.commit().await.unwrap();

        let mark = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT COUNT(*) AS c FROM comic_finished_marks".to_string(),
            ))
            .await
            .unwrap()
            .unwrap();
        assert_eq!(mark.try_get::<i64>("", "c").unwrap(), 0);

        let duration = db
            .query_one(Statement::from_string(
                sea_orm::DatabaseBackend::Sqlite,
                "SELECT total_ms, updated_at_ms FROM reading_duration_total WHERE id = 1"
                    .to_string(),
            ))
            .await
            .unwrap()
            .unwrap();
        assert_eq!(duration.try_get::<i64>("", "total_ms").unwrap(), 120000);
        assert_eq!(duration.try_get::<i64>("", "updated_at_ms").unwrap(), 1);
    }

    #[tokio::test]
    #[cfg_attr(miri, ignore = "sqlite/FFI unavailable under miri")]
    async fn final_comic_delete_failure_rolls_back_all_relations_and_preserves_duration() {
        let db = purge_fixture().await;
        db.execute_unprepared(
            "CREATE TRIGGER block_final_comic_delete BEFORE DELETE ON comics \
             BEGIN SELECT RAISE(ABORT, 'final comic deletion blocked'); END",
        )
        .await
        .unwrap();
        let txn = db.begin().await.unwrap();

        let error = delete_comics_side_effects(&txn, &["a".to_string()])
            .await
            .expect_err("final Comic deletion fails after related rows were deleted");
        assert!(
            error.message.contains("final comic deletion blocked"),
            "{error:?}"
        );
        let pending = txn
            .query_one(Statement::from_string(
                txn.get_database_backend(),
                "SELECT \
                 (SELECT COUNT(*) FROM comic_reading_histories WHERE comic_id = 'a') AS histories, \
                 (SELECT COUNT(*) FROM comic_finished_marks WHERE comic_id = 'a') AS marks, \
                 (SELECT COUNT(*) FROM series_items WHERE comic_id = 'a') AS memberships, \
                 (SELECT COUNT(*) FROM comics WHERE comic_id = 'a') AS comics"
                    .to_string(),
            ))
            .await
            .unwrap()
            .unwrap();
        assert_eq!(pending.try_get::<i64>("", "histories").unwrap(), 0);
        assert_eq!(pending.try_get::<i64>("", "marks").unwrap(), 0);
        assert_eq!(pending.try_get::<i64>("", "memberships").unwrap(), 0);
        assert_eq!(pending.try_get::<i64>("", "comics").unwrap(), 1);
        txn.rollback().await.unwrap();

        let restored = db
            .query_one(Statement::from_string(
                db.get_database_backend(),
                "SELECT c.path, c.deleted_at, h.title, h.last_read_time, h.page_index, \
                 f.finished_at_ms, s.series_id, d.total_ms, d.updated_at_ms \
                 FROM comics c \
                 INNER JOIN comic_reading_histories h ON h.comic_id = c.comic_id \
                 INNER JOIN comic_finished_marks f ON f.comic_id = c.comic_id \
                 INNER JOIN series_items s ON s.comic_id = c.comic_id \
                 CROSS JOIN reading_duration_total d \
                 WHERE c.comic_id = 'a' AND d.id = 1"
                    .to_string(),
            ))
            .await
            .unwrap()
            .expect("Comic, history, Finished mark and Series membership are all restored");
        assert_eq!(restored.try_get::<String>("", "path").unwrap(), "/a");
        assert_eq!(restored.try_get::<i64>("", "deleted_at").unwrap(), 1);
        assert_eq!(
            restored.try_get::<String>("", "title").unwrap(),
            "Read title"
        );
        assert_eq!(restored.try_get::<i64>("", "last_read_time").unwrap(), 2);
        assert_eq!(restored.try_get::<i32>("", "page_index").unwrap(), 3);
        assert_eq!(restored.try_get::<i64>("", "finished_at_ms").unwrap(), 1);
        assert_eq!(
            restored.try_get::<String>("", "series_id").unwrap(),
            "series"
        );
        assert_eq!(restored.try_get::<i64>("", "total_ms").unwrap(), 120000);
        assert_eq!(restored.try_get::<i64>("", "updated_at_ms").unwrap(), 1);
    }
}
