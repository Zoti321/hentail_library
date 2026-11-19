use std::collections::{HashMap, HashSet};
use std::path::Path;

use sea_orm::{ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, Set};

use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;
use crate::metadata_lock::{merge_series_name, resolve_member_sort_order};
use crate::series_id::{
    folder_path_from_comic_path, series_id_from_folder_path, series_name_from_folder_path,
};
use crate::util::compute_sort_key;

/// Rebuild Folder series from comics.
/// When `library_id` is `Some`, only that library's comics/series are considered.
pub async fn rebuild_series_from_comics<C: ConnectionTrait>(
    db: &C,
    library_id: Option<&str>,
) -> Result<(), HentaiError> {
    let comics = match library_id {
        Some(id) => Comics::find()
            .filter(crate::entity::comics::Column::LibraryId.eq(id))
            .all(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?,
        None => Comics::find()
            .all(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?,
    };
    let mut groups: HashMap<String, Vec<(String, String)>> = HashMap::new();
    let mut group_library: HashMap<String, String> = HashMap::new();
    for comic in comics {
        let Some(folder_path) = folder_path_from_comic_path(&comic.path) else {
            continue;
        };
        group_library
            .entry(folder_path.clone())
            .or_insert_with(|| comic.library_id.clone());
        groups
            .entry(folder_path)
            .or_default()
            .push((comic.comic_id, comic.path));
    }

    let active_series_ids: HashSet<String> = groups
        .keys()
        .map(|folder_path| series_id_from_folder_path(folder_path))
        .collect();

    let existing_rows = match library_id {
        Some(id) => Series::find()
            .filter(crate::entity::series::Column::LibraryId.eq(id))
            .all(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?,
        None => Series::find()
            .all(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?,
    };
    let rewrite_comic_ids: Vec<String> = groups
        .values()
        .flat_map(|entries| entries.iter().map(|(comic_id, _)| comic_id.clone()))
        .collect();

    // Snapshot before deleting stale Series, whose cascading delete removes member locks.
    let locked_orders: HashMap<String, f64> = if rewrite_comic_ids.is_empty() {
        HashMap::new()
    } else {
        SeriesItems::find()
            .filter(series_items::Column::ComicId.is_in(rewrite_comic_ids.clone()))
            .all(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?
            .into_iter()
            .filter(|item| item.sort_order_locked)
            .map(|item| (item.comic_id, item.sort_order))
            .collect()
    };

    for row in existing_rows {
        if !active_series_ids.contains(&row.series_id) {
            Series::delete_by_id(row.series_id)
                .exec(db)
                .await
                .map_err(|e| crate::db::map_db_err(&e))?;
        }
    }

    // Clear old memberships for comics we are about to rewrite so insert order
    // across Folder series cannot hit series_items.comic_id UNIQUE (#84).
    if !rewrite_comic_ids.is_empty() {
        SeriesItems::delete_many()
            .filter(series_items::Column::ComicId.is_in(rewrite_comic_ids))
            .exec(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?;
    }

    let mut folder_paths: Vec<String> = groups.keys().cloned().collect();
    folder_paths.sort();

    for folder_path in folder_paths {
        let Some(mut entries) = groups.remove(&folder_path) else {
            continue;
        };
        let series_library_id = group_library.get(&folder_path).cloned().unwrap_or_default();
        upsert_folder_series(db, &folder_path, series_library_id, &mut entries, &locked_orders)
            .await?;
    }

    Ok(())
}

async fn upsert_folder_series<C: ConnectionTrait>(
    db: &C,
    folder_path: &str,
    series_library_id: String,
    entries: &mut [(String, String)],
    locked_orders: &HashMap<String, f64>,
) -> Result<(), HentaiError> {
    entries.sort_by(|a, b| compare_paths_by_filename(&a.1, &b.1));
    let series_id = series_id_from_folder_path(folder_path);
    let name = series_name_from_folder_path(folder_path);
    let existing = Series::find_by_id(series_id.clone())
        .one(db)
        .await
        .map_err(|e| crate::db::map_db_err(&e))?;

    if let Some(existing_row) = existing {
        let mut active: series::ActiveModel = existing_row.clone().into();
        active.folder_path = Set(folder_path.to_owned());
        active.library_id = Set(series_library_id);
        // serialization_status / total_count have no scan source → never overwritten.
        let merged_name = merge_series_name(existing_row.name_locked, &existing_row.name, &name);
        active.name_sort_key = Set(compute_sort_key(&merged_name));
        active.name = Set(merged_name);
        active
            .update(db)
            .await
            .map_err(|e| crate::db::map_db_err(&e))?;
    } else {
        Series::insert(series::ActiveModel {
            series_id: Set(series_id.clone()),
            folder_path: Set(folder_path.to_owned()),
            name_sort_key: Set(compute_sort_key(&name)),
            name: Set(name),
            serialization_status: Set("unknown".to_string()),
            total_count: Set(None),
            name_locked: Set(false),
            serialization_status_locked: Set(false),
            total_count_locked: Set(false),
            library_id: Set(series_library_id),
        })
        .exec(db)
        .await
        .map_err(|e| crate::db::map_db_err(&e))?;
    }

    for (index, (comic_id, _)) in entries.iter().enumerate() {
        let (sort_order, sort_order_locked) = resolve_member_sort_order(
            locked_orders.get(comic_id).copied(),
            f64::from(crate::util::usize_to_i32(index) + 1),
        );
        SeriesItems::insert(series_items::ActiveModel {
            series_id: Set(series_id.clone()),
            comic_id: Set(comic_id.clone()),
            sort_order: Set(sort_order),
            sort_order_locked: Set(sort_order_locked),
        })
        .exec(db)
        .await
        .map_err(|e| crate::db::map_db_err(&e))?;
    }
    Ok(())
}

fn compare_paths_by_filename(a: &str, b: &str) -> std::cmp::Ordering {
    let a_name = path_basename(a);
    let b_name = path_basename(b);
    compare_natural(&a_name, &b_name)
}

fn path_basename(path: &str) -> String {
    Path::new(path)
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or(path)
        .to_string()
}

fn compare_natural(a: &str, b: &str) -> std::cmp::Ordering {
    let mut a_chars = a.chars().peekable();
    let mut b_chars = b.chars().peekable();
    loop {
        match (a_chars.peek(), b_chars.peek()) {
            (None, None) => return std::cmp::Ordering::Equal,
            (None, Some(_)) => return std::cmp::Ordering::Less,
            (Some(_), None) => return std::cmp::Ordering::Greater,
            (Some(a_ch), Some(b_ch)) if a_ch.is_ascii_digit() && b_ch.is_ascii_digit() => {
                let a_num = read_number(&mut a_chars);
                let b_num = read_number(&mut b_chars);
                match a_num.cmp(&b_num) {
                    std::cmp::Ordering::Equal => {}
                    other => return other,
                }
            }
            (Some(a_ch), Some(b_ch)) => {
                let a_lower = a_ch.to_ascii_lowercase();
                let b_lower = b_ch.to_ascii_lowercase();
                match a_lower.cmp(&b_lower) {
                    std::cmp::Ordering::Equal => {
                        a_chars.next();
                        b_chars.next();
                    }
                    other => return other,
                }
            }
        }
    }
}

fn read_number<I>(chars: &mut std::iter::Peekable<I>) -> u64
where
    I: Iterator<Item = char>,
{
    let mut value = 0u64;
    while let Some(ch) = chars.peek().copied() {
        if !ch.is_ascii_digit() {
            break;
        }
        let Some(digit) = ch.to_digit(10) else {
            break;
        };
        value = value * 10 + u64::from(digit);
        chars.next();
    }
    value
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn natural_sort_orders_numeric_suffixes() {
        let mut names = vec!["10.cbz", "2.cbz", "1.cbz"];
        names.sort_by(|a, b| compare_natural(a, b));
        assert_eq!(names, vec!["1.cbz", "2.cbz", "10.cbz"]);
    }
}
