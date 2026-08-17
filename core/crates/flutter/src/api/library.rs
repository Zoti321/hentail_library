use hentai_core::{
    create_local_library as core_create_local, create_remote_library as core_create_remote,
    delete_library as core_delete, get_current_library_id as core_get_current,
    list_libraries as core_list, set_all_libraries_scan_on_startup as core_set_all_scan_on_startup,
    set_current_library_id as core_set_current,
    update_library_format_groups as core_update_formats,
    update_library_settings as core_update_settings,
    update_library_sidebar_layout as core_update_sidebar,
    update_local_library_root as core_update_local_root,
    update_remote_library as core_update_remote, FormatGroup as CoreFormatGroup,
    LibraryDto as CoreLibrary, LibrarySidebarPlacement as CoreSidebarPlacement,
    ScanInterval as CoreScanInterval,
};

use super::init::HentaiErrorDto;
use super::sync::FormatGroupDto;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ScanIntervalDto {
    Disabled,
    Hourly,
    Every6Hours,
    Every12Hours,
    Daily,
    Weekly,
}

#[derive(Debug, Clone)]
pub struct LibraryDto {
    pub library_id: String,
    pub kind: String,
    pub root_path: String,
    pub name: String,
    pub enabled_format_groups: Vec<FormatGroupDto>,
    pub created_at: i64,
    pub username: String,
    pub allow_http: bool,
    pub scan_on_startup: bool,
    pub scan_interval: ScanIntervalDto,
    pub pinned: bool,
    pub sidebar_order: i32,
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
            username: value.username,
            allow_http: value.allow_http,
            scan_on_startup: value.scan_on_startup,
            scan_interval: map_scan_interval(value.scan_interval),
            pinned: value.pinned,
            sidebar_order: value.sidebar_order,
        }
    }
}

#[derive(Debug, Clone)]
pub struct LibrarySidebarPlacementDto {
    pub library_id: String,
    pub pinned: bool,
    pub sidebar_order: i32,
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

fn map_scan_interval(interval: CoreScanInterval) -> ScanIntervalDto {
    match interval {
        CoreScanInterval::Disabled => ScanIntervalDto::Disabled,
        CoreScanInterval::Hourly => ScanIntervalDto::Hourly,
        CoreScanInterval::Every6Hours => ScanIntervalDto::Every6Hours,
        CoreScanInterval::Every12Hours => ScanIntervalDto::Every12Hours,
        CoreScanInterval::Daily => ScanIntervalDto::Daily,
        CoreScanInterval::Weekly => ScanIntervalDto::Weekly,
    }
}

fn map_scan_interval_core(interval: ScanIntervalDto) -> CoreScanInterval {
    match interval {
        ScanIntervalDto::Disabled => CoreScanInterval::Disabled,
        ScanIntervalDto::Hourly => CoreScanInterval::Hourly,
        ScanIntervalDto::Every6Hours => CoreScanInterval::Every6Hours,
        ScanIntervalDto::Every12Hours => CoreScanInterval::Every12Hours,
        ScanIntervalDto::Daily => CoreScanInterval::Daily,
        ScanIntervalDto::Weekly => CoreScanInterval::Weekly,
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_libraries_frb() -> Result<Vec<LibraryDto>, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_list())
        .map(|rows| rows.into_iter().map(LibraryDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_local_library_frb(
    root_path: String,
    name: Option<String>,
) -> Result<LibraryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_create_local(&root_path, name.as_deref()))
        .map(LibraryDto::from)
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_remote_library_frb(
    root_url: String,
    username: String,
    allow_http: bool,
    name: Option<String>,
) -> Result<LibraryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_create_remote(
        &root_url,
        &username,
        allow_http,
        name.as_deref(),
    ))
    .map(LibraryDto::from)
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_remote_library_frb(
    library_id: String,
    root_url: String,
    username: String,
    allow_http: bool,
) -> Result<LibraryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_update_remote(
        &library_id,
        &root_url,
        &username,
        allow_http,
    ))
    .map(LibraryDto::from)
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_local_library_root_frb(
    library_id: String,
    root_path: String,
) -> Result<LibraryDto, HentaiErrorDto> {
    hentai_core::runtime::block_on(core_update_local_root(&library_id, &root_path))
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

#[flutter_rust_bridge::frb(sync)]
pub fn update_library_settings_frb(
    library_id: String,
    name: String,
    groups: Vec<FormatGroupDto>,
    scan_on_startup: bool,
    scan_interval: ScanIntervalDto,
) -> Result<LibraryDto, HentaiErrorDto> {
    let core_groups = groups.into_iter().map(map_format_group_core).collect();
    hentai_core::runtime::block_on(core_update_settings(
        &library_id,
        &name,
        core_groups,
        scan_on_startup,
        map_scan_interval_core(scan_interval),
    ))
    .map(LibraryDto::from)
    .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_all_libraries_scan_on_startup_frb(enabled: bool) -> Result<(), HentaiErrorDto> {
    hentai_core::runtime::block_on(core_set_all_scan_on_startup(enabled))
        .map_err(HentaiErrorDto::from)
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_library_sidebar_layout_frb(
    placements: Vec<LibrarySidebarPlacementDto>,
) -> Result<Vec<LibraryDto>, HentaiErrorDto> {
    let core_placements = placements
        .into_iter()
        .map(|p| CoreSidebarPlacement {
            library_id: p.library_id,
            pinned: p.pinned,
            sidebar_order: p.sidebar_order,
        })
        .collect();
    hentai_core::runtime::block_on(core_update_sidebar(core_placements))
        .map(|rows| rows.into_iter().map(LibraryDto::from).collect())
        .map_err(HentaiErrorDto::from)
}
