import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_serialization_status_filter.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:test/test.dart';

const LibraryTabAgeRestrictionSettings _defaultAgeSettings = (
  comics: LibraryAgeRestrictionFilter.unrestricted,
  series: LibraryAgeRestrictionFilter.unrestricted,
);

const LibraryMetadataFilterSelection _emptyTagFilter =
    LibraryMetadataFilterSelection();

const LibraryMetadataFilterSelection _emptyAuthorFilter =
    LibraryMetadataFilterSelection();

final LibraryTabSortSettings _defaultSortSettings = (
  comics: kLibraryDefaultSortOption,
  series: LibrarySeriesSortOption(),
);

void main() {
  group('isLibraryComicFilterSortCustomized', () {
    test('media type filter counts as customized', () {
      expect(
        isLibraryComicFilterSortCustomized(
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          mediaTypeFilter: const LibraryMediaTypeFilterSelection({
            LibraryMediaTypeFilterOption.pdf,
          }),
          tagFilter: _emptyTagFilter,
          authorFilter: _emptyAuthorFilter,
          languageFilter: const <String>{},
          parodyFilter: const <String>{},
          characterFilter: const <String>{},
          sortOption: kLibraryDefaultSortOption,
        ),
        isTrue,
      );
    });

    test('tag filter counts as customized', () {
      expect(
        isLibraryComicFilterSortCustomized(
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
          tagFilter: LibraryMetadataFilterSelection(
            picks: <String, LibraryTriStatePick>{
              '百合': LibraryTriStatePick.include,
            },
          ),
          authorFilter: _emptyAuthorFilter,
          languageFilter: const <String>{},
          parodyFilter: const <String>{},
          characterFilter: const <String>{},
          sortOption: kLibraryDefaultSortOption,
        ),
        isTrue,
      );
    });

    test('default settings are not customized', () {
      expect(
        isLibraryComicFilterSortCustomized(
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
          tagFilter: _emptyTagFilter,
          authorFilter: _emptyAuthorFilter,
          languageFilter: const <String>{},
          parodyFilter: const <String>{},
          characterFilter: const <String>{},
          sortOption: kLibraryDefaultSortOption,
        ),
        isFalse,
      );
    });
  });

  group('isLibrarySeriesFilterSortCustomized', () {
    test('default settings are not customized', () {
      expect(
        isLibrarySeriesFilterSortCustomized(
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          serializationStatusFilter:
              LibrarySerializationStatusFilter.unrestricted,
          sortOption: kLibraryDefaultSeriesSortOption,
        ),
        isFalse,
      );
    });

    test('serialization status filter counts as customized', () {
      expect(
        isLibrarySeriesFilterSortCustomized(
          ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
          serializationStatusFilter: LibrarySerializationStatusFilter.ongoing,
          sortOption: kLibraryDefaultSeriesSortOption,
        ),
        isTrue,
      );
    });
  });

  group('isLibraryFilterSortCustomizedForTarget', () {
    test('series target ignores comics media type filter', () {
      expect(
        isLibraryFilterSortCustomizedForTarget(
          target: LibraryDisplayTarget.series,
          ageSettings: _defaultAgeSettings,
          mediaTypeFilter: const LibraryMediaTypeFilterSelection({
            LibraryMediaTypeFilterOption.pdf,
          }),
          tagFilter: _emptyTagFilter,
          authorFilter: _emptyAuthorFilter,
          languageFilter: const <String>{},
          parodyFilter: const <String>{},
          characterFilter: const <String>{},
          serializationStatusFilter:
              LibrarySerializationStatusFilter.unrestricted,
          sortSettings: _defaultSortSettings,
        ),
        isFalse,
      );
    });

    test('series target counts serialization status filter', () {
      expect(
        isLibraryFilterSortCustomizedForTarget(
          target: LibraryDisplayTarget.series,
          ageSettings: _defaultAgeSettings,
          mediaTypeFilter: const LibraryMediaTypeFilterSelection(),
          tagFilter: _emptyTagFilter,
          authorFilter: _emptyAuthorFilter,
          languageFilter: const <String>{},
          parodyFilter: const <String>{},
          characterFilter: const <String>{},
          serializationStatusFilter: LibrarySerializationStatusFilter.ended,
          sortSettings: _defaultSortSettings,
        ),
        isTrue,
      );
    });
  });
}
