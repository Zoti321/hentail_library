use std::collections::HashMap;
use std::fs::File;
use std::io::{BufReader, Read};
use std::path::Path;

use sea_orm::{ActiveModelTrait, ColumnTrait, EntityTrait, QueryFilter, Set, TransactionTrait};
use zip::ZipArchive;

use crate::db::{connection, map_db_err};
use crate::entity::{image_set_carriers, image_set_images, image_set_submission_members};
use crate::error::HentaiError;
use crate::formats::{map_archive_err, read_rar_entry, read_sevenz_entry};
use crate::library_write::with_library_write;
use crate::resource::extension_lower;

use super::dto::CarrierKind;
use super::ids::image_set_image_id;
use super::mutation::{refuse_root_archive, require_mutation_library, resolve_under_root};
use super::workspace::{load_set_images, require_set};

/// One-way managed layout takeover: flatten a directory Image set by workspace user order.
pub async fn take_over_image_set_managed_layout(
    library_id: &str,
    image_set_id: &str,
) -> Result<(), HentaiError> {
    with_library_write(|| async {
        let db = connection()?;
        let txn = db.begin().await.map_err(|e| map_db_err(&e))?;
        let lib = require_mutation_library(&txn, library_id).await?;
        if lib.image_set_managed_layout == 0 {
            return Err(HentaiError::validation("图集托管布局未开启".to_string()));
        }
        let set = require_set(&txn, library_id, image_set_id).await?;
        refuse_root_archive(&txn, library_id, &set.relative_path).await?;

        let mut images = load_set_images(&txn, library_id, image_set_id).await?;
        images.sort_by(|a, b| {
            a.sort_order
                .cmp(&b.sort_order)
                .then_with(|| a.image_set_image_id.cmp(&b.image_set_image_id))
        });

        let set_dir = resolve_under_root(&lib.root_path, &set.relative_path)?;
        std::fs::create_dir_all(&set_dir).map_err(|e| {
            HentaiError::validation(format!("无法创建图集目录: {}: {e}", set.relative_path))
        })?;

        let mut planned = Vec::with_capacity(images.len());
        let mut used_names = std::collections::HashSet::new();
        for (index, row) in images.iter().enumerate() {
            let bytes = read_image_bytes(&lib.root_path, row)?;
            let file_name = managed_file_name(index, row, &used_names);
            used_names.insert(file_name.clone());
            planned.push((row.clone(), bytes, file_name));
        }

        let staging = tempfile::TempDir::new()
            .map_err(|e| HentaiError::validation(format!("无法创建托管布局暂存目录: {e}")))?;
        for (_, bytes, file_name) in &planned {
            std::fs::write(staging.path().join(file_name), bytes).map_err(|e| {
                HentaiError::validation(format!("写入托管布局暂存失败: {file_name}: {e}"))
            })?;
        }

        clear_dir_children(&set_dir)?;
        for (_, _, file_name) in &planned {
            std::fs::copy(staging.path().join(file_name), set_dir.join(file_name)).map_err(
                |e| HentaiError::validation(format!("应用托管布局失败: {file_name}: {e}")),
            )?;
        }

        let id_map: HashMap<String, String> = planned
            .iter()
            .map(|(old, _, file_name)| {
                let carrier = format!("{}/{}", set.relative_path, file_name).replace('\\', "/");
                let new_id = image_set_image_id(library_id, &carrier, "");
                (old.image_set_image_id.clone(), new_id)
            })
            .collect();

        // Drop membership rows first so image PK replacement does not fight FKs; restore after.
        let member_rows = image_set_submission_members::Entity::find()
            .filter(
                image_set_submission_members::Column::ImageSetImageId
                    .is_in(id_map.keys().cloned().collect::<Vec<_>>()),
            )
            .all(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;
        let mut pending_members = Vec::with_capacity(member_rows.len());
        for member in member_rows {
            let new_id = id_map
                .get(&member.image_set_image_id)
                .cloned()
                .unwrap_or_else(|| member.image_set_image_id.clone());
            pending_members.push((member.submission_id.clone(), new_id, member.sort_order));
            image_set_submission_members::Entity::delete_many()
                .filter(image_set_submission_members::Column::SubmissionId.eq(member.submission_id))
                .filter(
                    image_set_submission_members::Column::ImageSetImageId
                        .eq(member.image_set_image_id),
                )
                .exec(&txn)
                .await
                .map_err(|e| map_db_err(&e))?;
        }

        image_set_images::Entity::delete_many()
            .filter(image_set_images::Column::ImageSetId.eq(image_set_id))
            .exec(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;

        for (sort_order, (old, _, file_name)) in planned.into_iter().enumerate() {
            let carrier = format!("{}/{}", set.relative_path, file_name).replace('\\', "/");
            let new_id = image_set_image_id(library_id, &carrier, "");
            let row = image_set_images::ActiveModel {
                image_set_image_id: Set(new_id),
                library_id: Set(library_id.to_string()),
                image_set_id: Set(image_set_id.to_string()),
                carrier_relative_path: Set(carrier),
                member_path: Set(String::new()),
                carrier_kind: Set(CarrierKind::Loose.as_str().to_string()),
                name: Set(file_name),
                sort_order: Set(sort_order as i64),
                excluded: Set(old.excluded),
                width: Set(old.width),
                height: Set(old.height),
            };
            row.insert(&txn).await.map_err(|e| map_db_err(&e))?;
        }

        for (submission_id, image_id, sort_order) in pending_members {
            let row = image_set_submission_members::ActiveModel {
                submission_id: Set(submission_id),
                image_set_image_id: Set(image_id),
                sort_order: Set(sort_order),
            };
            row.insert(&txn).await.map_err(|e| map_db_err(&e))?;
        }

        image_set_carriers::Entity::delete_many()
            .filter(image_set_carriers::Column::ImageSetId.eq(image_set_id))
            .exec(&txn)
            .await
            .map_err(|e| map_db_err(&e))?;

        txn.commit().await.map_err(|e| map_db_err(&e))?;
        crate::revision::notify_committed();
        Ok(())
    })
    .await
}

fn managed_file_name(
    index: usize,
    row: &image_set_images::Model,
    used: &std::collections::HashSet<String>,
) -> String {
    let mut ext = extension_lower(Path::new(&row.name));
    if ext.is_empty() {
        ext = extension_lower(Path::new(&row.member_path));
    }
    if ext.is_empty() {
        ext = extension_lower(Path::new(&row.carrier_relative_path));
    }
    if ext.is_empty() {
        ext = ".jpg".to_string();
    }
    let base = format!("{:04}{ext}", index + 1);
    if !used.contains(&base) {
        return base;
    }
    let stem = format!("{:04}", index + 1);
    let mut n = 1u32;
    loop {
        let candidate = format!("{stem}_{n}{ext}");
        if !used.contains(&candidate) {
            return candidate;
        }
        n = n.saturating_add(1);
    }
}

fn clear_dir_children(dir: &Path) -> Result<(), HentaiError> {
    let entries = std::fs::read_dir(dir)
        .map_err(|e| HentaiError::validation(format!("无法枚举图集目录: {e}")))?;
    for entry in entries {
        let entry = entry.map_err(|e| HentaiError::validation(format!("无法枚举图集目录: {e}")))?;
        let path = entry.path();
        let meta = std::fs::symlink_metadata(&path).map_err(|e| {
            HentaiError::validation(format!("无法读取图集条目: {}: {e}", path.display()))
        })?;
        if meta.file_type().is_symlink() {
            return Err(HentaiError::validation(format!(
                "拒绝删除符号链接: {}",
                path.display()
            )));
        }
        if meta.is_dir() {
            std::fs::remove_dir_all(&path).map_err(|e| {
                HentaiError::validation(format!("清理图集子目录失败: {}: {e}", path.display()))
            })?;
        } else {
            std::fs::remove_file(&path).map_err(|e| {
                HentaiError::validation(format!("清理图集文件失败: {}: {e}", path.display()))
            })?;
        }
    }
    Ok(())
}

fn read_image_bytes(root: &str, row: &image_set_images::Model) -> Result<Vec<u8>, HentaiError> {
    let carrier = resolve_under_root(root, &row.carrier_relative_path)?;
    match row.carrier_kind.as_str() {
        "loose" => std::fs::read(&carrier).map_err(|e| {
            HentaiError::validation(format!("读取图片失败: {}: {e}", row.carrier_relative_path))
        }),
        "zip" => read_zip_member(&carrier, &row.member_path),
        "rar" => read_rar_entry(&carrier, &row.member_path),
        "sevenz" => read_sevenz_entry(&carrier, &row.member_path),
        other => Err(HentaiError::validation(format!("未知图集载体: {other}"))),
    }
}

fn read_zip_member(file: &Path, member_path: &str) -> Result<Vec<u8>, HentaiError> {
    let handle = File::open(file).map_err(|e| map_archive_err("zip 打开失败", e))?;
    let mut archive =
        ZipArchive::new(BufReader::new(handle)).map_err(|e| map_archive_err("zip 解析失败", e))?;
    let raw_name = archive
        .file_names()
        .find(|name| name.replace('\\', "/") == member_path)
        .map(str::to_string)
        .ok_or_else(|| HentaiError::validation(format!("压缩包内无条目: {member_path}")))?;
    let mut entry = archive
        .by_name(&raw_name)
        .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
    let mut buf = Vec::new();
    entry
        .read_to_end(&mut buf)
        .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
    Ok(buf)
}
