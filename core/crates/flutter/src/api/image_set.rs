use hentai_core::{
    fetch_image_sets_page as core_fetch_page, get_image_set_facets as core_get_facets,
    list_image_set_images as core_list_images, list_image_sets as core_list_sets,
    load_image_set_page_bytes as core_load_image_set_page_bytes,
    open_image_set_reader as core_open_image_set_reader,
    set_image_set_meta_locks as core_set_meta_locks, update_image_set_facets as core_update_facets,
    update_image_set_user_meta as core_update_meta, ImageSetDto as CoreImageSet,
    ImageSetFacetsDto as CoreFacets, ImageSetImageDto as CoreImageSetImage,
    ImageSetReaderSessionDto as CoreImageSetReaderSession, ImageSetSortFieldDto as CoreSortField,
    SetImageSetMetaLocksDto as CoreSetMetaLocks, UpdateImageSetFacetsDto as CoreUpdateFacets,
    UpdateImageSetUserMetaDto as CoreUpdateMeta,
};

use super::comic::PageRequestDto;
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

/// Facet bucket: any bound name (case-insensitive) OR, when `unassigned`, no binding.
#[derive(Debug, Clone, Default)]
pub struct ImageSetFacetFilterDto {
    pub any: Vec<String>,
    pub unassigned: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageSetCarrierShapeDto {
    Directory,
    RootArchive,
}

/// Catalog query filter for one Image set library; buckets AND-combine.
#[derive(Debug, Clone)]
pub struct ImageSetFilterDto {
    pub library_id: String,
    pub authors: ImageSetFacetFilterDto,
    pub tags: ImageSetFacetFilterDto,
    pub parodies: ImageSetFacetFilterDto,
    pub characters: ImageSetFacetFilterDto,
    pub carrier_shape: Option<ImageSetCarrierShapeDto>,
    pub require_images: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ImageSetSortFieldDto {
    #[default]
    Name,
    ImageCount,
    CreatedAt,
    RelativePath,
}

#[derive(Debug, Clone)]
pub struct ImageSetSortOptionDto {
    pub field: ImageSetSortFieldDto,
    pub descending: bool,
}

/// `ByAuthor` repeats a multi-author set once per matching Author group; unassigned group last.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageSetGroupingDto {
    None,
    ByAuthor,
}

#[derive(Debug, Clone)]
pub struct ImageSetAuthorGroupDto {
    pub author_id: i64,
    pub name: String,
}

#[derive(Debug, Clone)]
pub struct ImageSetCatalogItemDto {
    pub image_set: ImageSetDto,
    pub image_count: i64,
    pub created_at: i64,
    pub carrier_shape: ImageSetCarrierShapeDto,
    pub group_author: Option<ImageSetAuthorGroupDto>,
}

#[derive(Debug, Clone)]
pub struct PagedImageSetCatalogDto {
    pub items: Vec<ImageSetCatalogItemDto>,
    pub total_count: i64,
    pub page: i32,
    pub page_size: i32,
}

impl From<ImageSetFacetFilterDto> for hentai_core::ImageSetFacetFilterDto {
    fn from(value: ImageSetFacetFilterDto) -> Self {
        Self {
            any: value.any,
            unassigned: value.unassigned,
        }
    }
}

impl From<ImageSetCarrierShapeDto> for hentai_core::ImageSetCarrierShapeDto {
    fn from(value: ImageSetCarrierShapeDto) -> Self {
        match value {
            ImageSetCarrierShapeDto::Directory => Self::Directory,
            ImageSetCarrierShapeDto::RootArchive => Self::RootArchive,
        }
    }
}

impl From<hentai_core::ImageSetCarrierShapeDto> for ImageSetCarrierShapeDto {
    fn from(value: hentai_core::ImageSetCarrierShapeDto) -> Self {
        match value {
            hentai_core::ImageSetCarrierShapeDto::Directory => Self::Directory,
            hentai_core::ImageSetCarrierShapeDto::RootArchive => Self::RootArchive,
        }
    }
}

impl From<ImageSetFilterDto> for hentai_core::ImageSetFilterDto {
    fn from(value: ImageSetFilterDto) -> Self {
        Self {
            library_id: value.library_id,
            authors: value.authors.into(),
            tags: value.tags.into(),
            parodies: value.parodies.into(),
            characters: value.characters.into(),
            carrier_shape: value.carrier_shape.map(Into::into),
            require_images: value.require_images,
        }
    }
}

impl From<ImageSetSortOptionDto> for hentai_core::ImageSetSortOptionDto {
    fn from(value: ImageSetSortOptionDto) -> Self {
        Self {
            field: match value.field {
                ImageSetSortFieldDto::Name => CoreSortField::Name,
                ImageSetSortFieldDto::ImageCount => CoreSortField::ImageCount,
                ImageSetSortFieldDto::CreatedAt => CoreSortField::CreatedAt,
                ImageSetSortFieldDto::RelativePath => CoreSortField::RelativePath,
            },
            descending: value.descending,
        }
    }
}

impl From<ImageSetGroupingDto> for hentai_core::ImageSetGroupingDto {
    fn from(value: ImageSetGroupingDto) -> Self {
        match value {
            ImageSetGroupingDto::None => Self::None,
            ImageSetGroupingDto::ByAuthor => Self::ByAuthor,
        }
    }
}

impl From<hentai_core::PagedImageSetCatalogDto> for PagedImageSetCatalogDto {
    fn from(value: hentai_core::PagedImageSetCatalogDto) -> Self {
        Self {
            items: value
                .items
                .into_iter()
                .map(|item| ImageSetCatalogItemDto {
                    image_set: item.image_set.into(),
                    image_count: item.image_count,
                    created_at: item.created_at,
                    carrier_shape: item.carrier_shape.into(),
                    group_author: item.group_author.map(|author| ImageSetAuthorGroupDto {
                        author_id: author.author_id,
                        name: author.name,
                    }),
                })
                .collect(),
            total_count: value.total_count,
            page: value.page,
            page_size: value.page_size,
        }
    }
}

/// One clamped page of the Image set catalog (filter / sort / Author grouping).
pub async fn fetch_image_sets_page_frb(
    request: PageRequestDto,
    filter: ImageSetFilterDto,
    sort: ImageSetSortOptionDto,
    grouping: ImageSetGroupingDto,
) -> Result<PagedImageSetCatalogDto, HentaiErrorDto> {
    core_fetch_page(request.into(), filter.into(), sort.into(), grouping.into())
        .await
        .map(PagedImageSetCatalogDto::from)
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

/// Author / Tag / Parody / Character bindings (each name ASC).
#[derive(Debug, Clone)]
pub struct ImageSetFacetsDto {
    pub authors: Vec<String>,
    pub tags: Vec<String>,
    pub parodies: Vec<String>,
    pub characters: Vec<String>,
}

impl From<CoreFacets> for ImageSetFacetsDto {
    fn from(value: CoreFacets) -> Self {
        Self {
            authors: value.authors,
            tags: value.tags,
            parodies: value.parodies,
            characters: value.characters,
        }
    }
}

/// Replace-all facet patch (`None` = leave unchanged, empty = clear).
#[derive(Debug, Clone, Default)]
pub struct UpdateImageSetFacetsDto {
    pub authors: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub parodies: Option<Vec<String>>,
    pub characters: Option<Vec<String>>,
}

pub async fn get_image_set_facets_frb(
    image_set_id: String,
) -> Result<ImageSetFacetsDto, HentaiErrorDto> {
    core_get_facets(&image_set_id)
        .await
        .map(ImageSetFacetsDto::from)
        .map_err(HentaiErrorDto::from)
}

pub async fn update_image_set_facets_frb(
    image_set_id: String,
    patch: UpdateImageSetFacetsDto,
) -> Result<(), HentaiErrorDto> {
    core_update_facets(
        &image_set_id,
        CoreUpdateFacets {
            authors: patch.authors,
            tags: patch.tags,
            parodies: patch.parodies,
            characters: patch.characters,
        },
    )
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
