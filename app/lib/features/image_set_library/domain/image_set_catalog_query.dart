import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';

/// Facet bucket for Image set catalog query (matches Core: any names + unassigned).
class ImageSetFacetFilter {
  const ImageSetFacetFilter({
    this.any = const <String>{},
    this.unassigned = false,
  });

  final Set<String> any;
  final bool unassigned;

  bool get isActive => unassigned || any.isNotEmpty;

  ImageSetFacetFilter copyWith({Set<String>? any, bool? unassigned}) =>
      ImageSetFacetFilter(
        any: any ?? this.any,
        unassigned: unassigned ?? this.unassigned,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageSetFacetFilter &&
          other.unassigned == unassigned &&
          other.any.length == any.length &&
          other.any.containsAll(any);

  @override
  int get hashCode => Object.hash(unassigned, Object.hashAll(any));
}

enum ImageSetCarrierShape { directory, rootArchive }

enum ImageSetSortField { name, imageCount, createdAt, relativePath }

class ImageSetSortOption {
  const ImageSetSortOption({
    this.field = ImageSetSortField.name,
    this.descending = false,
  });

  final ImageSetSortField field;
  final bool descending;

  ImageSetSortOption copyWith({ImageSetSortField? field, bool? descending}) =>
      ImageSetSortOption(
        field: field ?? this.field,
        descending: descending ?? this.descending,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageSetSortOption &&
          other.field == field &&
          other.descending == descending;

  @override
  int get hashCode => Object.hash(field, descending);
}

enum ImageSetGrouping { none, byAuthor }

/// Persisted Image set library browse preferences (filter + sort + grouping + page size).
class ImageSetBrowsePreferences {
  const ImageSetBrowsePreferences({
    this.authors = const ImageSetFacetFilter(),
    this.tags = const ImageSetFacetFilter(),
    this.parodies = const ImageSetFacetFilter(),
    this.characters = const ImageSetFacetFilter(),
    this.carrierShape,
    this.requireImages = true,
    this.sort = const ImageSetSortOption(),
    this.grouping = ImageSetGrouping.none,
    this.pageSize = kDefaultPageSize,
  });

  static const ImageSetBrowsePreferences defaults = ImageSetBrowsePreferences();

  final ImageSetFacetFilter authors;
  final ImageSetFacetFilter tags;
  final ImageSetFacetFilter parodies;
  final ImageSetFacetFilter characters;
  final ImageSetCarrierShape? carrierShape;
  final bool requireImages;
  final ImageSetSortOption sort;
  final ImageSetGrouping grouping;
  final int pageSize;

  bool get hasActiveFilters =>
      authors.isActive ||
      tags.isActive ||
      parodies.isActive ||
      characters.isActive ||
      carrierShape != null ||
      !requireImages ||
      sort != const ImageSetSortOption() ||
      grouping != ImageSetGrouping.none;

  ImageSetBrowsePreferences copyWith({
    ImageSetFacetFilter? authors,
    ImageSetFacetFilter? tags,
    ImageSetFacetFilter? parodies,
    ImageSetFacetFilter? characters,
    ImageSetCarrierShape? carrierShape,
    bool clearCarrierShape = false,
    bool? requireImages,
    ImageSetSortOption? sort,
    ImageSetGrouping? grouping,
    int? pageSize,
  }) => ImageSetBrowsePreferences(
    authors: authors ?? this.authors,
    tags: tags ?? this.tags,
    parodies: parodies ?? this.parodies,
    characters: characters ?? this.characters,
    carrierShape: clearCarrierShape
        ? null
        : (carrierShape ?? this.carrierShape),
    requireImages: requireImages ?? this.requireImages,
    sort: sort ?? this.sort,
    grouping: grouping ?? this.grouping,
    pageSize: pageSize ?? this.pageSize,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageSetBrowsePreferences &&
          other.authors == authors &&
          other.tags == tags &&
          other.parodies == parodies &&
          other.characters == characters &&
          other.carrierShape == carrierShape &&
          other.requireImages == requireImages &&
          other.sort == sort &&
          other.grouping == grouping &&
          other.pageSize == pageSize;

  @override
  int get hashCode => Object.hash(
    authors,
    tags,
    parodies,
    characters,
    carrierShape,
    requireImages,
    sort,
    grouping,
    pageSize,
  );
}

class ImageSetCatalogItem {
  const ImageSetCatalogItem({
    required this.imageSet,
    required this.imageCount,
    required this.createdAt,
    required this.carrierShape,
    this.groupAuthorName,
  });

  final ImageSet imageSet;
  final int imageCount;
  final int createdAt;
  final ImageSetCarrierShape carrierShape;
  final String? groupAuthorName;
}

class PagedImageSetCatalog {
  const PagedImageSetCatalog({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<ImageSetCatalogItem> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages =>
      pageSize <= 0 ? 0 : ((totalCount + pageSize - 1) ~/ pageSize);
}
