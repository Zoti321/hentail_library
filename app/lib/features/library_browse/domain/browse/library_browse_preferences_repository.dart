import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';
import 'package:hentai_library/features/comic/public/library_comic_browse_rules.dart';
import 'package:hentai_library/features/series/public/library_series_browse_rules.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_series_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';

abstract interface class LibraryBrowsePreferencesRepository {
  Future<LibraryComicBrowsePreferences> loadComicFilters();
  Future<LibrarySeriesBrowsePreferences> loadSeriesFilters();

  Future<void> saveComicAgeRestriction(LibraryAgeRestrictionFilter filter);
  Future<void> saveComicMediaTypes(LibraryMediaTypeFilterSelection selection);
  Future<void> saveComicTags(LibraryMetadataFilterSelection selection);
  Future<void> saveComicAuthors(LibraryMetadataFilterSelection selection);
  Future<void> saveNeedsMetadataOnly(bool enabled);
  Future<void> saveComicGrouping(LibraryComicGrouping grouping);
  Future<void> saveComicSort(LibraryComicSortOption option);
  Future<void> resetComicFilters();

  Future<void> saveSeriesAgeRestriction(LibraryAgeRestrictionFilter filter);
  Future<void> saveSeriesSerializationStatus(
    LibrarySerializationStatusFilter filter,
  );
  Future<void> saveSeriesGrouping(LibrarySeriesGrouping grouping);
  Future<void> saveSeriesSort(LibrarySeriesSortOption option);
  Future<void> resetSeriesFilters();

  Future<LibraryTabPageSizeSettings> loadPageSizes();
  Future<void> savePageSize(LibraryDisplayTarget target, int pageSize);
}
