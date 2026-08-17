use std::path::Path;

use crate::error::HentaiError;

use super::access::{local_access, ResourceAccess, ResourceKind};
use super::media::{extension_lower, is_comic_image_extension};

pub fn read_resource_size(path: &Path, resource_type: &str) -> Result<Option<i64>, HentaiError> {
    read_resource_size_with(local_access(), &path.to_string_lossy(), resource_type)
}

pub fn read_resource_size_with(
    access: &dyn ResourceAccess,
    location: &str,
    resource_type: &str,
) -> Result<Option<i64>, HentaiError> {
    let Some(stat) = access.stat(location)? else {
        return Ok(None);
    };
    if resource_type == "dir" {
        return compute_dir_image_files_size(access, location);
    }
    if stat.kind != ResourceKind::File {
        return Ok(None);
    }
    Ok(Some(stat.size as i64))
}

fn compute_dir_image_files_size(
    access: &dyn ResourceAccess,
    dir: &str,
) -> Result<Option<i64>, HentaiError> {
    let mut total = 0i64;
    for entry in access.list(dir)? {
        if entry.kind == ResourceKind::Dir {
            return Ok(None);
        }
        if entry.kind == ResourceKind::File
            && is_comic_image_extension(&extension_lower(Path::new(&entry.name)))
        {
            let Some(stat) = access.stat(&entry.location)? else {
                continue;
            };
            total += stat.size as i64;
        }
    }
    if total <= 0 {
        return Ok(None);
    }
    Ok(Some(total))
}

pub fn read_source_stat(path: &Path, resource_type: &str) -> Result<Option<(i64, i64)>, HentaiError> {
    read_source_stat_with(local_access(), &path.to_string_lossy(), resource_type)
}

pub fn read_source_stat_with(
    access: &dyn ResourceAccess,
    location: &str,
    resource_type: &str,
) -> Result<Option<(i64, i64)>, HentaiError> {
    let Some(stat) = access.stat(location)? else {
        return Ok(None);
    };
    let size = read_resource_size_with(access, location, resource_type)?.unwrap_or(0);
    Ok(Some((stat.modified_ms, size)))
}
