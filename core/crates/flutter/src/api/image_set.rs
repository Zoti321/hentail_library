use hentai_core::{
    list_image_set_images as core_list_images, list_image_sets as core_list_sets,
    ImageSetDto as CoreImageSet, ImageSetImageDto as CoreImageSetImage,
};

use super::init::HentaiErrorDto;

#[derive(Debug, Clone)]
pub struct ImageSetDto {
    pub image_set_id: String,
    pub library_id: String,
    pub relative_path: String,
    pub name: String,
    pub is_root: bool,
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
