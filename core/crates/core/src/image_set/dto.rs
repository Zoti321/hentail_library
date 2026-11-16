use std::path::Path;

use crate::resource::extension_lower;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImageSetDto {
    pub image_set_id: String,
    pub library_id: String,
    /// `/`-separated path under the Library root; empty for the Library root image set.
    pub relative_path: String,
    /// Folder basename; empty for the Library root image set.
    pub name: String,
    pub is_root: bool,
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
