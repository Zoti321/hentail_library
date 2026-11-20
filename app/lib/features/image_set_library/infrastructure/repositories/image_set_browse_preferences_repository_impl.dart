import 'package:hentai_library/features/image_set_library/domain/image_set_browse_preferences_repository.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for Image set browse — must not collide with Comic/Series.
const String kImageSetBrowsePageSizeKey = 'image_set_browse_page_size';
const String kImageSetBrowseSortFieldKey = 'image_set_browse_sort_field';
const String kImageSetBrowseSortDescKey = 'image_set_browse_sort_descending';
const String kImageSetBrowseGroupingKey = 'image_set_browse_grouping';
const String kImageSetBrowseRequireImagesKey = 'image_set_browse_require_images';
const String kImageSetBrowseCarrierShapeKey = 'image_set_browse_carrier_shape';
const String kImageSetBrowseAuthorsAnyKey = 'image_set_browse_authors_any';
const String kImageSetBrowseAuthorsUnassignedKey =
    'image_set_browse_authors_unassigned';
const String kImageSetBrowseTagsAnyKey = 'image_set_browse_tags_any';
const String kImageSetBrowseTagsUnassignedKey =
    'image_set_browse_tags_unassigned';
const String kImageSetBrowseParodiesAnyKey = 'image_set_browse_parodies_any';
const String kImageSetBrowseParodiesUnassignedKey =
    'image_set_browse_parodies_unassigned';
const String kImageSetBrowseCharactersAnyKey =
    'image_set_browse_characters_any';
const String kImageSetBrowseCharactersUnassignedKey =
    'image_set_browse_characters_unassigned';

const List<String> kImageSetBrowsePreferenceKeys = <String>[
  kImageSetBrowsePageSizeKey,
  kImageSetBrowseSortFieldKey,
  kImageSetBrowseSortDescKey,
  kImageSetBrowseGroupingKey,
  kImageSetBrowseRequireImagesKey,
  kImageSetBrowseCarrierShapeKey,
  kImageSetBrowseAuthorsAnyKey,
  kImageSetBrowseAuthorsUnassignedKey,
  kImageSetBrowseTagsAnyKey,
  kImageSetBrowseTagsUnassignedKey,
  kImageSetBrowseParodiesAnyKey,
  kImageSetBrowseParodiesUnassignedKey,
  kImageSetBrowseCharactersAnyKey,
  kImageSetBrowseCharactersUnassignedKey,
];

class ImageSetBrowsePreferencesRepositoryImpl
    implements ImageSetBrowsePreferencesRepository {
  const ImageSetBrowsePreferencesRepositoryImpl();

  @override
  Future<ImageSetBrowsePreferences> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return ImageSetBrowsePreferences(
      authors: _readFacet(
        prefs,
        anyKey: kImageSetBrowseAuthorsAnyKey,
        unassignedKey: kImageSetBrowseAuthorsUnassignedKey,
      ),
      tags: _readFacet(
        prefs,
        anyKey: kImageSetBrowseTagsAnyKey,
        unassignedKey: kImageSetBrowseTagsUnassignedKey,
      ),
      parodies: _readFacet(
        prefs,
        anyKey: kImageSetBrowseParodiesAnyKey,
        unassignedKey: kImageSetBrowseParodiesUnassignedKey,
      ),
      characters: _readFacet(
        prefs,
        anyKey: kImageSetBrowseCharactersAnyKey,
        unassignedKey: kImageSetBrowseCharactersUnassignedKey,
      ),
      carrierShape: _readCarrierShape(prefs.getString(kImageSetBrowseCarrierShapeKey)),
      requireImages: prefs.getBool(kImageSetBrowseRequireImagesKey) ?? true,
      sort: ImageSetSortOption(
        field: _readSortField(prefs.getString(kImageSetBrowseSortFieldKey)),
        descending: prefs.getBool(kImageSetBrowseSortDescKey) ?? false,
      ),
      grouping: _readGrouping(prefs.getString(kImageSetBrowseGroupingKey)),
      pageSize: normalizeLibraryPageSize(prefs.getInt(kImageSetBrowsePageSizeKey)),
    );
  }

  @override
  Future<void> save(ImageSetBrowsePreferences preferences) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ImageSetBrowsePreferences normalized = preferences.copyWith(
      pageSize: normalizeLibraryPageSize(preferences.pageSize),
    );
    await prefs.setInt(kImageSetBrowsePageSizeKey, normalized.pageSize);
    await prefs.setString(
      kImageSetBrowseSortFieldKey,
      _sortFieldKey(normalized.sort.field),
    );
    await prefs.setBool(
      kImageSetBrowseSortDescKey,
      normalized.sort.descending,
    );
    await prefs.setString(
      kImageSetBrowseGroupingKey,
      _groupingKey(normalized.grouping),
    );
    await prefs.setBool(
      kImageSetBrowseRequireImagesKey,
      normalized.requireImages,
    );
    if (normalized.carrierShape == null) {
      await prefs.remove(kImageSetBrowseCarrierShapeKey);
    } else {
      await prefs.setString(
        kImageSetBrowseCarrierShapeKey,
        _carrierShapeKey(normalized.carrierShape!),
      );
    }
    await _writeFacet(
      prefs,
      normalized.authors,
      anyKey: kImageSetBrowseAuthorsAnyKey,
      unassignedKey: kImageSetBrowseAuthorsUnassignedKey,
    );
    await _writeFacet(
      prefs,
      normalized.tags,
      anyKey: kImageSetBrowseTagsAnyKey,
      unassignedKey: kImageSetBrowseTagsUnassignedKey,
    );
    await _writeFacet(
      prefs,
      normalized.parodies,
      anyKey: kImageSetBrowseParodiesAnyKey,
      unassignedKey: kImageSetBrowseParodiesUnassignedKey,
    );
    await _writeFacet(
      prefs,
      normalized.characters,
      anyKey: kImageSetBrowseCharactersAnyKey,
      unassignedKey: kImageSetBrowseCharactersUnassignedKey,
    );
  }

  @override
  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final String key in kImageSetBrowsePreferenceKeys) {
      await prefs.remove(key);
    }
  }
}

ImageSetFacetFilter _readFacet(
  SharedPreferences prefs, {
  required String anyKey,
  required String unassignedKey,
}) {
  final List<String> any = prefs.getStringList(anyKey) ?? const <String>[];
  return ImageSetFacetFilter(
    any: any.toSet(),
    unassigned: prefs.getBool(unassignedKey) ?? false,
  );
}

Future<void> _writeFacet(
  SharedPreferences prefs,
  ImageSetFacetFilter filter, {
  required String anyKey,
  required String unassignedKey,
}) async {
  if (!filter.isActive) {
    await prefs.remove(anyKey);
    await prefs.remove(unassignedKey);
    return;
  }
  final List<String> sorted = filter.any.toList()..sort();
  await prefs.setStringList(anyKey, sorted);
  await prefs.setBool(unassignedKey, filter.unassigned);
}

ImageSetSortField _readSortField(String? raw) => switch (raw) {
  'imageCount' => ImageSetSortField.imageCount,
  'createdAt' => ImageSetSortField.createdAt,
  'relativePath' => ImageSetSortField.relativePath,
  _ => ImageSetSortField.name,
};

String _sortFieldKey(ImageSetSortField field) => switch (field) {
  ImageSetSortField.name => 'name',
  ImageSetSortField.imageCount => 'imageCount',
  ImageSetSortField.createdAt => 'createdAt',
  ImageSetSortField.relativePath => 'relativePath',
};

ImageSetGrouping _readGrouping(String? raw) => switch (raw) {
  'byAuthor' => ImageSetGrouping.byAuthor,
  _ => ImageSetGrouping.none,
};

String _groupingKey(ImageSetGrouping grouping) => switch (grouping) {
  ImageSetGrouping.none => 'none',
  ImageSetGrouping.byAuthor => 'byAuthor',
};

ImageSetCarrierShape? _readCarrierShape(String? raw) => switch (raw) {
  'directory' => ImageSetCarrierShape.directory,
  'rootArchive' => ImageSetCarrierShape.rootArchive,
  _ => null,
};

String _carrierShapeKey(ImageSetCarrierShape shape) => switch (shape) {
  ImageSetCarrierShape.directory => 'directory',
  ImageSetCarrierShape.rootArchive => 'rootArchive',
};
