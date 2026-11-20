import 'dart:typed_data';

import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';

/// Fixture catalog for Image set browse Lab (no FRB).
abstract final class Md3eImageSetBrowsePreviewData {
  Md3eImageSetBrowsePreviewData._();

  static const String libraryId = 'lab-image-set';
  static const String displayName = 'Image set Lab';

  static const ImageSet root = ImageSet(
    imageSetId: 'root',
    libraryId: libraryId,
    relativePath: '',
    name: 'legacy-root',
    isRoot: true,
  );

  static const ImageSet alpha = ImageSet(
    imageSetId: 'alpha',
    libraryId: libraryId,
    relativePath: 'alpha',
    name: 'Alpha Set',
    isRoot: false,
  );

  static const ImageSet beta = ImageSet(
    imageSetId: 'beta',
    libraryId: libraryId,
    relativePath: 'beta.zip',
    name: 'Beta Archive',
    isRoot: false,
  );

  static const List<ImageSetCatalogItem> populatedItems = <ImageSetCatalogItem>[
    ImageSetCatalogItem(
      imageSet: root,
      imageCount: 0,
      createdAt: 0,
      carrierShape: ImageSetCarrierShape.directory,
    ),
    ImageSetCatalogItem(
      imageSet: alpha,
      imageCount: 2,
      createdAt: 1,
      carrierShape: ImageSetCarrierShape.directory,
    ),
    ImageSetCatalogItem(
      imageSet: beta,
      imageCount: 1,
      createdAt: 2,
      carrierShape: ImageSetCarrierShape.rootArchive,
    ),
  ];

  static const List<ImageSetImage> alphaImages = <ImageSetImage>[
    ImageSetImage(
      imageSetImageId: 'a1',
      imageSetId: 'alpha',
      libraryId: libraryId,
      carrierRelativePath: 'alpha/1.png',
      memberPath: '',
      carrierKind: 'loose',
      name: '1.png',
    ),
    ImageSetImage(
      imageSetImageId: 'a2',
      imageSetId: 'alpha',
      libraryId: libraryId,
      carrierRelativePath: 'alpha/2.png',
      memberPath: '',
      carrierKind: 'loose',
      name: '2.png',
    ),
  ];

  static const ImageSetFacets alphaFacets = ImageSetFacets(
    authors: <String>['Lab Author'],
    tags: <String>['lab-tag'],
    parodies: <String>['Lab Parody'],
    characters: <String>['Lab Character'],
  );

  static const ImageSetBrowsePreferences activeFilters = ImageSetBrowsePreferences(
    authors: ImageSetFacetFilter(any: <String>{'Lab Author'}),
    tags: ImageSetFacetFilter(any: <String>{'lab-tag'}),
    carrierShape: ImageSetCarrierShape.directory,
    sort: ImageSetSortOption(field: ImageSetSortField.imageCount),
  );

  /// Minimal valid 1×1 PNG for cover/page-bytes previews.
  static final Uint8List png1x1 = Uint8List.fromList(<int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
    0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);
}
