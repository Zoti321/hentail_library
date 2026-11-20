use std::collections::{HashMap, HashSet};
use std::path::{Component, Path, PathBuf};

use sea_orm::{
    ActiveModelTrait, ColumnTrait, ConnectionTrait, EntityTrait, QueryFilter, TransactionTrait,
};

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_carriers, image_set_images, libraries};
use crate::error::HentaiError;
use crate::library::is_image_set_catalog;
use crate::library_write::with_library_write;
use crate::resource::{basename, extension_lower, is_comic_image_extension};

use super::dimensions::probe_image_file;
use super::dto::{CarrierKind, ImageSetImageDto};
use super::ids::image_set_image_id;
use super::workspace::{load_set_images, require_set};

/// Copies local image files into a directory Image set's first-level folder; appends catalog order.
pub async fn copy_images_into_image_set(
    library_id: &str,
    image_set_id: &str,
    source_paths: &[String],
) -> Result<Vec<ImageSetImageDto>, HentaiError> {
    if source_paths.is_empty() {
        return Ok(Vec::new());
    }
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let lib = require_mutation_library(&txn, library_id).await?;
        let set = require_set(&txn, library_id, image_set_id).await?;
        refuse_root_archive(&txn, library_id, &set.relative_path).await?;

        let set_dir = resolve_under_root(&lib.root_path, &set.relative_path)?;
        std::fs::create_dir_all(&set_dir).map_err(|e| {
            HentaiError::validation(format!("无法创建图集目录: {}: {e}", set.relative_path))
        })?;

        let existing = load_set_images(&txn, library_id, image_set_id).await?;
        let mut next_order = existing
            .iter()
            .map(|row| row.sort_order)
            .max()
            .map(|m| m.saturating_add(1))
            .unwrap_or(0);
        let mut used_names: HashSet<String> = existing.iter().map(|row| row.name.clone()).collect();
        // Also reserve first-level filenames already on disk.
        if let Ok(entries) = std::fs::read_dir(&set_dir) {
            for entry in entries.flatten() {
                if let Some(name) = entry.file_name().to_str() {
                    used_names.insert(name.to_string());
                }
            }
        }

        let mut inserted = Vec::with_capacity(source_paths.len());
        for source in source_paths {
            let src = Path::new(source);
            validate_source_image(src)?;
            let file_name = unique_file_name(&basename(src), &used_names);
            used_names.insert(file_name.clone());
            let dest = set_dir.join(&file_name);
            std::fs::copy(src, &dest)
                .map_err(|e| HentaiError::validation(format!("复制图片失败: {file_name}: {e}")))?;

            let carrier_relative_path =
                format!("{}/{}", set.relative_path, file_name).replace('\\', "/");
            let (width, height) = match probe_image_file(&dest) {
                Some((w, h)) => (i32::try_from(w).ok(), i32::try_from(h).ok()),
                None => (None, None),
            };
            let row = image_set_images::Model {
                image_set_image_id: image_set_image_id(library_id, &carrier_relative_path, ""),
                library_id: library_id.to_string(),
                image_set_id: image_set_id.to_string(),
                carrier_relative_path: carrier_relative_path.clone(),
                member_path: String::new(),
                carrier_kind: CarrierKind::Loose.as_str().to_string(),
                name: file_name.clone(),
                sort_order: next_order,
                excluded: false,
                width,
                height,
            };
            next_order = next_order.saturating_add(1);
            let active: image_set_images::ActiveModel = row.clone().into();
            active.insert(&txn).await.map_err(|e| map_db_err(&e))?;
            inserted.push(ImageSetImageDto {
                image_set_image_id: row.image_set_image_id,
                image_set_id: row.image_set_id,
                library_id: row.library_id,
                carrier_relative_path: row.carrier_relative_path,
                member_path: row.member_path,
                carrier_kind: row.carrier_kind,
                name: row.name,
                excluded: row.excluded,
                width: row.width.and_then(|v| u32::try_from(v).ok()),
                height: row.height.and_then(|v| u32::try_from(v).ok()),
            });
        }

        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(inserted)
    })
    .await
}

/// Deletes loose Image set image files on disk and catalog rows (submission members cascade).
pub async fn delete_image_set_images_on_disk(
    library_id: &str,
    image_set_id: &str,
    image_ids: &[String],
) -> Result<(), HentaiError> {
    if image_ids.is_empty() {
        return Ok(());
    }
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let lib = require_mutation_library(&txn, library_id).await?;
        let set = require_set(&txn, library_id, image_set_id).await?;
        refuse_root_archive(&txn, library_id, &set.relative_path).await?;

        let rows = load_set_images(&txn, library_id, image_set_id).await?;
        let by_id: HashMap<&str, &image_set_images::Model> = rows
            .iter()
            .map(|row| (row.image_set_image_id.as_str(), row))
            .collect();
        let mut to_delete = Vec::with_capacity(image_ids.len());
        for id in image_ids {
            let Some(row) = by_id.get(id.as_str()) else {
                return Err(HentaiError::validation(format!(
                    "图集图片不属于该图集: {id}"
                )));
            };
            if row.carrier_kind != CarrierKind::Loose.as_str() || !row.member_path.is_empty() {
                return Err(HentaiError::validation(
                    "仅支持删除散落图片；压缩包成员不支持磁盘变更".to_string(),
                ));
            }
            to_delete.push((*row).clone());
        }

        for row in &to_delete {
            let path = resolve_under_root(&lib.root_path, &row.carrier_relative_path)?;
            if path.exists() {
                if std::fs::symlink_metadata(&path)
                    .map(|m| m.file_type().is_symlink())
                    .unwrap_or(false)
                {
                    return Err(HentaiError::validation(format!(
                        "拒绝删除符号链接: {}",
                        row.carrier_relative_path
                    )));
                }
                std::fs::remove_file(&path).map_err(|e| {
                    HentaiError::validation(format!(
                        "删除图片失败: {}: {e}",
                        row.carrier_relative_path
                    ))
                })?;
            }
        }

        image_set_images::Entity::delete_many()
            .filter(image_set_images::Column::ImageSetImageId.is_in(image_ids.to_vec()))
            .exec(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;

        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

pub(crate) async fn require_mutation_library<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
) -> Result<libraries::Model, HentaiError> {
    let lib = libraries::Entity::find_by_id(library_id)
        .one(db)
        .await
        .map_err(|e| map_db_err(&e))?
        .ok_or_else(|| HentaiError::validation("Library is unavailable"))?;
    if lib.kind != "local" || !is_image_set_catalog(&lib.catalog_kind) {
        return Err(HentaiError::validation(
            "Image set resource mutation is only available for Local Image set libraries",
        ));
    }
    if lib.image_set_resource_mutation == 0 {
        return Err(HentaiError::validation("图集资源变更未开启".to_string()));
    }
    Ok(lib)
}

pub(crate) async fn refuse_root_archive<C: ConnectionTrait>(
    db: &C,
    library_id: &str,
    relative_path: &str,
) -> Result<(), HentaiError> {
    let root_archive = image_set_carriers::Entity::find()
        .filter(image_set_carriers::Column::LibraryId.eq(library_id))
        .filter(image_set_carriers::Column::CarrierRelativePath.eq(relative_path))
        .one(db)
        .await
        .map_err(|e| map_db_err(&e))?
        .is_some();
    if root_archive {
        return Err(HentaiError::validation(
            "根压缩包图集不支持资源变更".to_string(),
        ));
    }
    Ok(())
}

fn validate_source_image(path: &Path) -> Result<(), HentaiError> {
    let meta = std::fs::symlink_metadata(path)
        .map_err(|e| HentaiError::validation(format!("源文件不可用: {}: {e}", path.display())))?;
    if meta.file_type().is_symlink() {
        return Err(HentaiError::validation(format!(
            "拒绝符号链接源: {}",
            path.display()
        )));
    }
    if !meta.is_file() {
        return Err(HentaiError::validation(format!(
            "源路径不是文件: {}",
            path.display()
        )));
    }
    if !is_comic_image_extension(&extension_lower(path)) {
        return Err(HentaiError::validation(format!(
            "不是支持的图片扩展名: {}",
            path.display()
        )));
    }
    Ok(())
}

pub(crate) fn resolve_under_root(root: &str, relative: &str) -> Result<PathBuf, HentaiError> {
    let rel = Path::new(relative);
    let safe = !relative.is_empty()
        && rel
            .components()
            .all(|component| matches!(component, Component::Normal(_)));
    if !safe {
        return Err(HentaiError::validation(format!("图集路径无效: {relative}")));
    }
    Ok(Path::new(root).join(rel))
}

fn unique_file_name(original: &str, used: &HashSet<String>) -> String {
    if !used.contains(original) {
        return original.to_string();
    }
    let path = Path::new(original);
    let stem = path.file_stem().and_then(|s| s.to_str()).unwrap_or("image");
    let ext = path
        .extension()
        .and_then(|s| s.to_str())
        .map(|e| format!(".{e}"))
        .unwrap_or_default();
    let mut n = 1u32;
    loop {
        let candidate = format!("{stem}_{n}{ext}");
        if !used.contains(&candidate) {
            return candidate;
        }
        n = n.saturating_add(1);
    }
}
