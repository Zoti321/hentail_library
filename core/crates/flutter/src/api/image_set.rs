use hentai_core::{
    list_image_set_images as core_list_images, list_image_sets as core_list_sets,
    load_image_set_page_bytes as core_load_image_set_page_bytes,
    open_image_set_reader as core_open_image_set_reader,
    set_image_set_meta_locks as core_set_meta_locks,
    update_image_set_user_meta as core_update_meta, ImageSetDto as CoreImageSet,
    ImageSetImageDto as CoreImageSetImage, ImageSetReaderSessionDto as CoreImageSetReaderSession,
    SetImageSetMetaLocksDto as CoreSetMetaLocks, UpdateImageSetUserMetaDto as CoreUpdateMeta,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ImageSetDto {
    pub image_set_id: String,
    pub library_id: String,
    pub relative_path: String,
    pub name: String,
    pub is_root: bool,
    pub name_locked: bool,
}

#[derive(Debug, Clone)]
pub struct ImageSetImageDto {
    pub image_set_image_id: String,
    pub image_set_id: String,
    pub library_id: String,
    pub carrier_relative_path: String,
    pub member_path: String,
    pub carrier_kind: String,
    pub name: String,
}

impl From<CoreImageSet> for ImageSetDto {
    fn from(value: CoreImageSet) -> Self {
        Self {
            image_set_id: value.image_set_id,
            library_id: value.library_id,
            relative_path: value.relative_path,
            name: value.name,
            is_root: value.is_root,
            name_locked: value.name_locked,
        }
    }
}

impl From<CoreImageSetImage> for ImageSetImageDto {
    fn from(value: CoreImageSetImage) -> Self {
        Self {
            image_set_image_id: value.image_set_image_id,
            image_set_id: value.image_set_id,
            library_id: value.library_id,
            carrier_relative_path: value.carrier_relative_path,
            member_path: value.member_path,
            carrier_kind: value.carrier_kind,
            name: value.name,
        }
    }
}

pub async fn list_image_sets_frb(library_id: String) -> Result<Vec<ImageSetDto>, HentaiErrorDto> {
    core_list_sets(&library_id)
        .await
        .map(|rows| rows.into_iter().map(ImageSetDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

pub async fn list_image_set_images_frb(
    library_id: String,
    image_set_id: String,
) -> Result<Vec<ImageSetImageDto>, HentaiErrorDto> {
    core_list_images(&library_id, &image_set_id)
        .await
        .map(|rows| rows.into_iter().map(ImageSetImageDto::from).collect())
        .map_err(HentaiErrorDto::from)
}

/// Writes the user name; a written name is auto-locked.
pub async fn update_image_set_name_frb(
    image_set_id: String,
    name: String,
) -> Result<(), HentaiErrorDto> {
    core_update_meta(&image_set_id, CoreUpdateMeta { name: Some(name) })
        .await
        .map_err(HentaiErrorDto::from)
}

/// Sets the name Metadata field lock only; unlocking does not rescan.
pub async fn set_image_set_name_locked_frb(
    image_set_id: String,
    locked: bool,
) -> Result<(), HentaiErrorDto> {
    core_set_meta_locks(&image_set_id, CoreSetMetaLocks { name: Some(locked) })
        .await
        .map_err(HentaiErrorDto::from)
}

#[derive(Debug, Clone)]
pub struct ImageSetReaderSessionDto {
    pub library_id: String,
    pub image_set_id: String,
    pub pages: Vec<ImageSetImageDto>,
    pub start_index: i32,
}

impl From<CoreImageSetReaderSession> for ImageSetReaderSessionDto {
    fn from(value: CoreImageSetReaderSession) -> Self {
        Self {
            library_id: value.library_id,
            image_set_id: value.image_set_id,
            pages: value
                .pages
                .into_iter()
                .map(ImageSetImageDto::from)
                .collect(),
            start_index: value.start_index as i32,
        }
    }
}

/// Opens an Image set Read session in catalog order; `start_index` is 0-based.
pub async fn open_image_set_reader_frb(
    library_id: String,
    image_set_id: String,
    start_index: i32,
) -> Result<ImageSetReaderSessionDto, HentaiErrorDto> {
    let start = usize::try_from(start_index).map_err(|_| {
        HentaiErrorDto::from(hentai_core::HentaiError::reader_invalid_content(format!(
            "页索引无效: {start_index}"
        )))
    })?;
    core_open_image_set_reader(&library_id, &image_set_id, start)
        .await
        .map(ImageSetReaderSessionDto::from)
        .map_err(HentaiErrorDto::from)
}

/// Raw bytes of one page; `image` is a page from the opened session.
pub async fn load_image_set_page_bytes_frb(
    library_id: String,
    image: ImageSetImageDto,
) -> Result<Vec<u8>, HentaiErrorDto> {
    let core_image = CoreImageSetImage {
        image_set_image_id: image.image_set_image_id,
        image_set_id: image.image_set_id,
        library_id: image.library_id,
        carrier_relative_path: image.carrier_relative_path,
        member_path: image.member_path,
        carrier_kind: image.carrier_kind,
        name: image.name,
    };
    core_load_image_set_page_bytes(&library_id, &core_image)
        .await
        .map_err(HentaiErrorDto::from)
}
