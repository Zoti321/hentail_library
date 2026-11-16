use std::fs::File;
use std::io::BufReader;
use std::path::Path;

use zip::ZipArchive;

use crate::error::HentaiError;
use crate::formats::{
    is_comic_image_name, list_rar_image_names, list_sevenz_image_names, map_archive_err,
    sort_archive_entry_names,
};

use super::dto::CarrierKind;

/// Image member paths (`/`-separated, natural order) of one archive carrier.
///
/// Any error means the carrier is unlistable; callers keep prior records for it.
pub(crate) fn list_archive_image_members(
    path: &Path,
    kind: CarrierKind,
) -> Result<Vec<String>, HentaiError> {
    let names = match kind {
        CarrierKind::Zip => list_zip_image_names(path)?,
        CarrierKind::Rar => list_rar_image_names(path)?,
        CarrierKind::SevenZ => list_sevenz_image_names(path)?,
        CarrierKind::Loose => return Err(HentaiError::validation("散落图片不是压缩包")),
    };
    Ok(names.into_iter().map(|n| n.replace('\\', "/")).collect())
}

fn list_zip_image_names(path: &Path) -> Result<Vec<String>, HentaiError> {
    let file = File::open(path).map_err(|e| map_archive_err("zip 打开失败", e))?;
    let mut archive =
        ZipArchive::new(BufReader::new(file)).map_err(|e| map_archive_err("zip 解析失败", e))?;
    let mut names = Vec::new();
    for index in 0..archive.len() {
        let entry = archive
            .by_index(index)
            .map_err(|e| map_archive_err("zip 条目读取失败", e))?;
        if entry.encrypted() {
            return Err(HentaiError::validation("zip 含加密条目，无法列出"));
        }
        if entry.is_dir() {
            continue;
        }
        let name = entry.name().to_string();
        if is_comic_image_name(&name) {
            names.push(name);
        }
    }
    Ok(sort_archive_entry_names(names))
}
