use std::path::Path;

use crate::resource::extension_lower;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetDto {
    pub image_set_id: String,
    pub library_id: String,
    /// `/`-separated path under the Library root (first-level folder or archive name).
    pub relative_path: String,
    /// Display name; sync scan source is the folder basename or archive file name.
    pub name: String,
    pub is_root: bool,
    /// Metadata field lock on `name`; sync keeps a locked name.
    pub name_locked: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetImageDto {
    pub image_set_image_id: String,
    pub image_set_id: String,
    pub library_id: String,
    /// Loose file or archive path relative to the Library root.
    pub carrier_relative_path: String,
    /// Empty for loose images; archive entry path otherwise.
    pub member_path: String,
    /// `loose` | `zip` | `rar` | `sevenz`.
    pub carrier_kind: String,
    pub name: String,
    /// Catalog workspace exclude flag (browse list is always `false`).
    pub excluded: bool,
}

/// Facet bucket of the catalog query: matches any bound name (case-insensitive) OR, when
/// `unassigned`, sets without any binding of this facet. Inactive when both are empty/false.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImageSetFacetFilterDto {
    pub any: Vec<String>,
    pub unassigned: bool,
}

/// First-level carrier of an Image set: a directory or an archive directly under the Library root.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageSetCarrierShapeDto {
    Directory,
    RootArchive,
}

/// Catalog query filter; buckets AND-combine. Scoped to one Image set library.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ImageSetFilterDto {
    pub library_id: String,
    pub authors: ImageSetFacetFilterDto,
    pub tags: ImageSetFacetFilterDto,
    pub parodies: ImageSetFacetFilterDto,
    pub characters: ImageSetFacetFilterDto,
    pub carrier_shape: Option<ImageSetCarrierShapeDto>,
    /// Drop sets with zero catalogued images.
    pub require_images: bool,
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum ImageSetSortFieldDto {
    /// Display name, natural order.
    #[default]
    Name,
    ImageCount,
    /// Catalog insertion time.
    CreatedAt,
    /// Relative path, natural order.
    RelativePath,
}

/// Ties fall back to display name ASC, then relative path ASC.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct ImageSetSortOptionDto {
    pub field: ImageSetSortFieldDto,
    pub descending: bool,
}

/// `ByAuthor`: one entry per (matching bound Author, set) — a multi-author set repeats once per
/// group; sets without Authors form a trailing unassigned group. Groups order by Author name.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum ImageSetGroupingDto {
    #[default]
    None,
    ByAuthor,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetAuthorGroupDto {
    pub author_id: i64,
    pub name: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetCatalogItemDto {
    pub image_set: ImageSetDto,
    pub image_count: i64,
    /// Catalog insertion time (epoch ms; 0 for sets catalogued before it was recorded).
    pub created_at: i64,
    pub carrier_shape: ImageSetCarrierShapeDto,
    /// `ByAuthor` group of this entry; `None` for the unassigned group or without grouping.
    pub group_author: Option<ImageSetAuthorGroupDto>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PagedImageSetCatalogDto {
    pub items: Vec<ImageSetCatalogItemDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum CarrierKind {
    Loose,
    Zip,
    Rar,
    SevenZ,
}

impl CarrierKind {
    pub(crate) fn as_str(self) -> &'static str {
        match self {
            Self::Loose => "loose",
            Self::Zip => "zip",
            Self::Rar => "rar",
            Self::SevenZ => "sevenz",
        }
    }

    /// Archive kind by extension (`.zip`/`.cbz`, `.rar`/`.cbr`, `.7z`/`.cb7`). Other extensions yield `None`.
    pub(crate) fn archive_for_path(path: &Path) -> Option<Self> {
        match extension_lower(path).as_str() {
            ".zip" | ".cbz" => Some(Self::Zip),
            ".rar" | ".cbr" => Some(Self::Rar),
            ".7z" | ".cb7" => Some(Self::SevenZ),
            _ => None,
        }
    }
}
