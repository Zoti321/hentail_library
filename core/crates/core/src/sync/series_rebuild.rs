use std::collections::{HashMap, HashSet};
use std::path::Path;

use sea_orm::{
    ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, Set,
};

use crate::entity::{prelude::*, series, series_items};
use crate::error::HentaiError;
use crate::series_id::{
    folder_path_from_comic_path, series_id_from_folder_path, series_name_from_folder_path,
};

pub async fn rebuild_series_from_comics<C: ConnectionTrait>(
    db: &C,
) -> Result<(), HentaiError> {
    let comics = Comics::find().all(db).await.map_err(crate::db::map_db_err)?;
    let mut groups: HashMap<String, Vec<(String, String)>> = HashMap::new();
    for comic in comics {
        let Some(folder_path) = folder_path_from_comic_path(&comic.path) else {
            continue;
        };
        groups
            .entry(folder_path)
            .or_default()
            .push((comic.comic_id, comic.path));
    }

    let active_series_ids: HashSet<String> = groups
        .keys()
        .map(|folder_path| series_id_from_folder_path(folder_path))
        .collect();

    let existing_rows = Series::find().all(db).await.map_err(crate::db::map_db_err)?;
    for row in existing_rows {
        if !active_series_ids.contains(&row.series_id) {
            Series::delete_by_id(row.series_id)
                .exec(db)
                .await
                .map_err(crate::db::map_db_err)?;
        }
    }

    for (folder_path, mut entries) in groups {
        entries.sort_by(|a, b| compare_paths_by_filename(&a.1, &b.1));
        let series_id = series_id_from_folder_path(&folder_path);
        let name = series_name_from_folder_path(&folder_path);
        let existing = Series::find_by_id(series_id.clone())
            .one(db)
            .await
            .map_err(crate::db::map_db_err)?;

        if existing.is_some() {
            Series::update_many()
                .col_expr(
                    series::Column::FolderPath,
                    sea_orm::sea_query::Expr::value(folder_path.clone()),
                )
                .col_expr(
                    series::Column::Name,
                    sea_orm::sea_query::Expr::value(name.clone()),
                )
                .filter(series::Column::SeriesId.eq(series_id.clone()))
                .exec(db)
                .await
                .map_err(crate::db::map_db_err)?;
        } else {
            Series::insert(series::ActiveModel {
                series_id: Set(series_id.clone()),
                folder_path: Set(folder_path),
                name: Set(name),
                serialization_status: Set("unknown".to_string()),
                total_count: Set(None),
                ..Default::default()
            })
            .exec(db)
            .await
            .map_err(crate::db::map_db_err)?;
        }

        SeriesItems::delete_many()
            .filter(series_items::Column::SeriesId.eq(series_id.clone()))
            .exec(db)
            .await
            .map_err(crate::db::map_db_err)?;

        for (sort_order, (comic_id, _)) in entries.iter().enumerate() {
            SeriesItems::insert(series_items::ActiveModel {
                series_id: Set(series_id.clone()),
                comic_id: Set(comic_id.clone()),
                sort_order: Set(sort_order as i32),
                ..Default::default()
            })
            .exec(db)
            .await
            .map_err(crate::db::map_db_err)?;
        }
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
                    std::cmp::Ordering::Equal => continue,
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
        value = value * 10 + (ch as u64 - b'0' as u64);
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
