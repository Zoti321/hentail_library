import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_series_browse_preferences.dart';
import 'package:hentai_library/features/comic/public/contracts.dart';
import 'package:hentai_library/features/series/public/contracts.dart';
import 'package:hentai_library/features/comic_metadata/public/contracts.dart';
import 'package:hentai_library/features/library_browse/domain/browse/author_filter_preference_migration.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_tri_state_pick.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_needs_metadata_only.dart';

import 'package:shared_preferences/shared_preferences.dart';

part 'library_browse_preferences_storage.dart';
part 'library_browse_author_filter_migration.dart';

class LibraryBrowsePreferencesRepositoryImpl
    implements LibraryBrowsePreferencesRepository {
  const LibraryBrowsePreferencesRepositoryImpl({required this._authors});

  final AuthorRepository _authors;

  @override
  Future<LibraryComicBrowsePreferences> loadComicFilters() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacyLibraryAgeRestriction(prefs);
    await migrateLegacyLibraryComicGrouping(prefs);

    final LibraryMetadataFilterSelection authorFilter = await _loadAuthorFilter(
      prefs,
      _authors,
    );

    return LibraryComicBrowsePreferences(
      ageRestriction: LibraryAgeRestrictionFilter.fromStorage(
        prefs.getString(_ageStorageKey),
      ),
      mediaTypeFilter: LibraryMediaTypeFilterSelection.fromStorage(
        prefs.getStringList(_mediaTypeStorageKey),
      ),
      tagFilter: LibraryMetadataFilterSelection.fromStorage(
        includeNames: prefs.getStringList(_tagIncludeStorageKey),
        excludeNames: prefs.getStringList(_tagExcludeStorageKey),
        includeModeName: prefs.getString(_tagIncludeModeStorageKey),
      ),
      authorFilter: authorFilter,
      needsMetadataOnly: LibraryNeedsMetadataOnly.fromStorage(
        prefs.getBool(LibraryNeedsMetadataOnly.storageKey),
      ),
      grouping: LibraryComicGrouping.fromStorage(
        prefs.getString(LibraryComicGrouping.storageKey),
      ),
      sortOption: _decodeComicSortOption(prefs.getString(_sortStorageKey)),
    );
  }

  @override
  Future<LibrarySeriesBrowsePreferences> loadSeriesFilters() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await migrateLegacyLibraryAgeRestriction(prefs);
    return LibrarySeriesBrowsePreferences(
      ageRestriction: LibraryAgeRestrictionFilter.fromStorage(
        prefs.getString(kLibrarySeriesAgeRestrictionStorageKey),
      ),
      serializationStatusFilter: LibrarySerializationStatusFilter.fromStorage(
        prefs.getString(LibrarySerializationStatusFilter.storageKey),
      ),
      grouping: LibrarySeriesGrouping.fromStorage(
        prefs.getString(LibrarySeriesGrouping.storageKey),
      ),
      sortOption: decodeLibrarySeriesSortOption(
        prefs.getString('library_sort_series'),
      ),
    );
  }

  @override
  Future<void> saveComicAgeRestriction(
    LibraryAgeRestrictionFilter filter,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (filter == LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.remove(_ageStorageKey);
    } else {
      await prefs.setString(_ageStorageKey, filter.name);
    }
  }

  @override
  Future<void> saveComicMediaTypes(
    LibraryMediaTypeFilterSelection updated,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (updated.selected.isEmpty) {
      await prefs.remove(_mediaTypeStorageKey);
    } else {
      await prefs.setStringList(_mediaTypeStorageKey, updated.toStorage());
    }
  }

  @override
  Future<void> saveNeedsMetadataOnly(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (enabled == LibraryNeedsMetadataOnly.defaultValue) {
      await prefs.remove(LibraryNeedsMetadataOnly.storageKey);
    } else {
      await prefs.setBool(LibraryNeedsMetadataOnly.storageKey, enabled);
    }
  }

  @override
  Future<void> saveComicGrouping(LibraryComicGrouping grouping) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (grouping == LibraryComicGrouping.defaultValue) {
      await prefs.remove(LibraryComicGrouping.storageKey);
    } else {
      await prefs.setString(LibraryComicGrouping.storageKey, grouping.name);
    }
  }

  @override
  Future<void> saveComicSort(LibraryComicSortOption next) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_isDefaultComicSort(next)) {
      await prefs.remove(_sortStorageKey);
    } else {
      await prefs.setString(_sortStorageKey, _encodeComicSortOption(next));
    }
  }

  @override
  Future<void> resetComicFilters() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ageStorageKey);
    await prefs.remove(_mediaTypeStorageKey);
    await prefs.remove(_tagIncludeStorageKey);
    await prefs.remove(_tagExcludeStorageKey);
    await prefs.remove(_tagIncludeModeStorageKey);
    await prefs.remove(_authorIncludeStorageKey);
    await prefs.remove(_authorExcludeStorageKey);
    await prefs.remove(_authorIncludeModeStorageKey);
    await prefs.remove(_sortStorageKey);
    await prefs.remove(LibraryNeedsMetadataOnly.storageKey);
    await prefs.remove(LibraryComicGrouping.storageKey);
    await prefs.remove(LibraryComicGrouping.legacyExpandBySeriesStorageKey);
  }

  @override
  Future<void> saveComicTags(LibraryMetadataFilterSelection selection) async {
    await _writeMetadataSelection(
      await SharedPreferences.getInstance(),
      selection,
      keys: _tagStorageKeys,
    );
  }

  @override
  Future<void> saveComicAuthors(
    LibraryMetadataFilterSelection selection,
  ) async {
    await _writeMetadataSelection(
      await SharedPreferences.getInstance(),
      selection,
      keys: _authorStorageKeys,
    );
  }

  @override
  Future<void> saveSeriesAgeRestriction(
    LibraryAgeRestrictionFilter filter,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (filter == LibraryAgeRestrictionFilter.unrestricted) {
      await prefs.remove(kLibrarySeriesAgeRestrictionStorageKey);
    } else {
      await prefs.setString(
        kLibrarySeriesAgeRestrictionStorageKey,
        filter.name,
      );
    }
  }

  @override
  Future<void> saveSeriesSerializationStatus(
    LibrarySerializationStatusFilter filter,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (filter == LibrarySerializationStatusFilter.unrestricted) {
      await prefs.remove(LibrarySerializationStatusFilter.storageKey);
    } else {
      await prefs.setString(
        LibrarySerializationStatusFilter.storageKey,
        filter.name,
      );
    }
  }

  @override
  Future<void> saveSeriesGrouping(LibrarySeriesGrouping grouping) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (grouping == LibrarySeriesGrouping.defaultValue) {
      await prefs.remove(LibrarySeriesGrouping.storageKey);
    } else {
      await prefs.setString(LibrarySeriesGrouping.storageKey, grouping.name);
    }
  }

  @override
  Future<void> saveSeriesSort(LibrarySeriesSortOption next) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (next == kLibraryDefaultSeriesSortOption) {
      await prefs.remove('library_sort_series');
    } else {
      await prefs.setString(
        'library_sort_series',
        encodeLibrarySeriesSortOption(next),
      );
    }
  }

  @override
  Future<void> resetSeriesFilters() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(kLibrarySeriesAgeRestrictionStorageKey);
    await prefs.remove(LibrarySerializationStatusFilter.storageKey);
    await prefs.remove(LibrarySeriesGrouping.storageKey);
    await prefs.remove('library_sort_series');
  }

  @override
  Future<LibraryTabPageSizeSettings> loadPageSizes() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      comics: normalizeLibraryPageSize(
        prefs.getInt('library_page_size_comics'),
      ),
      series: normalizeLibraryPageSize(
        prefs.getInt('library_page_size_series'),
      ),
    );
  }

  @override
  Future<void> savePageSize(LibraryDisplayTarget target, int pageSize) async {
    final normalized = normalizeLibraryPageSize(pageSize);
    final prefs = await SharedPreferences.getInstance();
    final key = switch (target) {
      LibraryDisplayTarget.comics => 'library_page_size_comics',
      LibraryDisplayTarget.series => 'library_page_size_series',
    };
    if (normalized == kDefaultPageSize) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, normalized);
    }
  }
}
