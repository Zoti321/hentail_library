import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/src/rust/api/image_set.dart' as rust;

rust.ImageSetFacetFilterDto imageSetFacetFilterToFrb(ImageSetFacetFilter filter) =>
    rust.ImageSetFacetFilterDto(
      any: filter.any.toList()..sort(),
      unassigned: filter.unassigned,
    );

rust.ImageSetCarrierShapeDto? imageSetCarrierShapeToFrb(
  ImageSetCarrierShape? shape,
) => switch (shape) {
  null => null,
  ImageSetCarrierShape.directory => rust.ImageSetCarrierShapeDto.directory,
  ImageSetCarrierShape.rootArchive => rust.ImageSetCarrierShapeDto.rootArchive,
};

ImageSetCarrierShape imageSetCarrierShapeFromFrb(
  rust.ImageSetCarrierShapeDto shape,
) => switch (shape) {
  rust.ImageSetCarrierShapeDto.directory => ImageSetCarrierShape.directory,
  rust.ImageSetCarrierShapeDto.rootArchive => ImageSetCarrierShape.rootArchive,
};

rust.ImageSetSortOptionDto imageSetSortToFrb(ImageSetSortOption sort) =>
    rust.ImageSetSortOptionDto(
      field: switch (sort.field) {
        ImageSetSortField.name => rust.ImageSetSortFieldDto.name,
        ImageSetSortField.imageCount => rust.ImageSetSortFieldDto.imageCount,
        ImageSetSortField.createdAt => rust.ImageSetSortFieldDto.createdAt,
        ImageSetSortField.relativePath =>
          rust.ImageSetSortFieldDto.relativePath,
      },
      descending: sort.descending,
    );

rust.ImageSetGroupingDto imageSetGroupingToFrb(ImageSetGrouping grouping) =>
    switch (grouping) {
      ImageSetGrouping.none => rust.ImageSetGroupingDto.none,
      ImageSetGrouping.byAuthor => rust.ImageSetGroupingDto.byAuthor,
    };

rust.ImageSetFilterDto imageSetFilterToFrb({
  required String libraryId,
  required ImageSetBrowsePreferences preferences,
}) => rust.ImageSetFilterDto(
  libraryId: libraryId,
  authors: imageSetFacetFilterToFrb(preferences.authors),
  tags: imageSetFacetFilterToFrb(preferences.tags),
  parodies: imageSetFacetFilterToFrb(preferences.parodies),
  characters: imageSetFacetFilterToFrb(preferences.characters),
  carrierShape: imageSetCarrierShapeToFrb(preferences.carrierShape),
  requireImages: preferences.requireImages,
);

ImageSetCatalogItem imageSetCatalogItemFromFrb(rust.ImageSetCatalogItemDto dto) =>
    ImageSetCatalogItem(
      imageSet: imageSetFromFrb(dto.imageSet),
      imageCount: dto.imageCount.toInt(),
      createdAt: dto.createdAt.toInt(),
      carrierShape: imageSetCarrierShapeFromFrb(dto.carrierShape),
      groupAuthorName: dto.groupAuthor?.name,
    );

PagedImageSetCatalog pagedImageSetCatalogFromFrb(
  rust.PagedImageSetCatalogDto dto,
) => PagedImageSetCatalog(
  items: dto.items.map(imageSetCatalogItemFromFrb).toList(),
  totalCount: dto.totalCount.toInt(),
  page: dto.page,
  pageSize: dto.pageSize,
);

ImageSet imageSetFromFrb(rust.ImageSetDto dto) => ImageSet(
  imageSetId: dto.imageSetId,
  libraryId: dto.libraryId,
  relativePath: dto.relativePath,
  name: dto.name,
  isRoot: dto.isRoot,
  nameLocked: dto.nameLocked,
);

ImageSetFacets imageSetFacetsFromFrb(rust.ImageSetFacetsDto dto) =>
    ImageSetFacets(
      authors: List<String>.from(dto.authors),
      tags: List<String>.from(dto.tags),
      parodies: List<String>.from(dto.parodies),
      characters: List<String>.from(dto.characters),
    );

ImageSetImage imageSetImageFromFrb(rust.ImageSetImageDto dto) => ImageSetImage(
  imageSetImageId: dto.imageSetImageId,
  imageSetId: dto.imageSetId,
  libraryId: dto.libraryId,
  carrierRelativePath: dto.carrierRelativePath,
  memberPath: dto.memberPath,
  carrierKind: dto.carrierKind,
  name: dto.name,
  excluded: dto.excluded,
);

rust.ImageSetImageDto imageSetImageToFrb(ImageSetImage image) =>
    rust.ImageSetImageDto(
      imageSetImageId: image.imageSetImageId,
      imageSetId: image.imageSetId,
      libraryId: image.libraryId,
      carrierRelativePath: image.carrierRelativePath,
      memberPath: image.memberPath,
      carrierKind: image.carrierKind,
      name: image.name,
      excluded: image.excluded,
    );

ImageSetLibraryGates imageSetLibraryGatesFromFrb(
  rust.ImageSetLibraryGatesDto dto,
) => ImageSetLibraryGates(
  resourceMutation: dto.resourceMutation,
  managedLayout: dto.managedLayout,
);

ImageSetSubmission imageSetSubmissionFromFrb(rust.ImageSetSubmissionDto dto) =>
    ImageSetSubmission(
      submissionId: dto.submissionId,
      libraryId: dto.libraryId,
      imageSetId: dto.imageSetId,
      name: dto.name,
      memberImageIds: List<String>.from(dto.memberImageIds),
    );
