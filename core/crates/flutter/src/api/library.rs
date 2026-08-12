use hentai_core::{
    create_local_library as core_create, delete_library as core_delete,
    get_current_library_id as core_get_current, list_libraries as core_list,
    set_current_library_id as core_set_current,
    update_library_format_groups as core_update_formats, FormatGroup as CoreFormatGroup,
    LibraryDto as CoreLibrary,
};

use super::init::HentaiErrorDto;
use super::sync::FormatGroupDto;

#[derive(Debug, Clone)]
pub struct LibraryDto {
    pub library_id: String,
    pub kind: String,
    pub root_path: String,
    pub name: String,
    pub enabled_format_groups: Vec<FormatGroupDto>,
    pub created_at: i64,
}

impl From<CoreLibrary> for LibraryDto {
    fn from(value: CoreLibrary) -> Self {
        Self {
            library_id: value.library_id,
            kind: value.kind,
            root_path: value.root_path,
            name: value.name,
            enabled_format_groups: value
                .enabled_format_groups
                .into_iter()
                .map(map_format_group)
                .collect(),
            created_at: value.created_at,
        }
    }
}

fn map_format_group(group: CoreFormatGroup) -> FormatGroupDto {
    match group {
        CoreFormatGroup::Folder => FormatGroupDto::Folder,
        CoreFormatGroup::Pdf => FormatGroupDto::Pdf,
        CoreFormatGroup::Epub => FormatGroupDto::Epub,
        CoreFormatGroup::Archive => FormatGroupDto::Archive,
    }
}

fn map_format_group_core(group: FormatGroupDto) -> CoreFormatGroup {
    match group {
        FormatGroupDto::Folder => CoreFormatGroup::Folder,
        FormatGroupDto::Pdf => CoreFormatGroup::Pdf,
        FormatGroupDto::Epub => CoreFormatGroup::Epub,
        FormatGroupDto::Archive => CoreFormatGroup::Archive,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_libraries_frb() -> Result<Vec<LibraryDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_list())
        .map(|rows| rows.into_iter().map(LibraryDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_local_library_frb(root_path: String) -> Result<LibraryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_create(&root_path))
        .map(LibraryDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_library_frb(library_id: String) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_delete(&library_id)).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_current_library_id_frb() -> Result<Option<String>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_get_current()).map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_current_library_id_frb(library_id: Option<String>) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_set_current(library_id.as_deref()))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_library_format_groups_frb(
    library_id: String,
    groups: Vec<FormatGroupDto>,
) -> Result<LibraryDto, HentaiErrorDto> {
    let core_groups = groups.into_iter().map(map_format_group_core).collect();
    hentai_core::runtime::block_on(core_update_formats(&library_id, core_groups))
        .map(LibraryDto::from)
        .map_err(HentaiErrorDto::from)
}
