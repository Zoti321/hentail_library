import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:test/test.dart';

const LibraryTabAgeRestrictionSettings _defaultAgeSettings = (
  comics: LibraryAgeRestrictionFilter.unrestricted,
  series: LibraryAgeRestrictionFilter.unrestricted,
);

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
          sortOption: kLibraryDefaultSortOption,
        ),
        isFalse,
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
          sortSettings: _defaultSortSettings,
        ),
        isFalse,
      );
    });
  });
}
