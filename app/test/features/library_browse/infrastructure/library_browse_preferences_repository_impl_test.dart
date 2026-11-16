import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic/public/contracts.dart';
import 'package:hentai_library/features/series/public/contracts.dart';
import 'package:hentai_library/features/comic_metadata/public/contracts.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_series_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_media_type_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/infrastructure/library_browse_preferences_repository_impl.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fakes/author_repository_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LibraryBrowsePreferencesRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({'unrelated_setting': true});
    repository = const LibraryBrowsePreferencesRepositoryImpl(
      authors: EmptyAuthorRepository(),
    );
  });

  test(
    'round-trips persistent comic dimensions and clears only comic keys',
    () async {
      await repository.saveComicAgeRestriction(
        LibraryAgeRestrictionFilter.r18Only,
      );
      await repository.saveComicMediaTypes(
        const LibraryMediaTypeFilterSelection({
          LibraryMediaTypeFilterOption.pdf,
        }),
      );
      final tags = const LibraryMetadataFilterSelection().withToggled('tag');
      final authors = const LibraryMetadataFilterSelection().withToggled('7');
      await repository.saveComicTags(tags);
      await repository.saveComicAuthors(authors);
      await repository.saveNeedsMetadataOnly(true);
      await repository.saveComicGrouping(LibraryComicGrouping.none);
      await repository.saveComicSort(
        LibraryComicSortOption(
          field: LibraryComicSortField.readAt,
          descending: true,
        ),
      );
      await repository.saveSeriesAgeRestriction(
        LibraryAgeRestrictionFilter.allAges,
      );

      final loaded = await repository.loadComicFilters();
      expect(loaded.ageRestriction, LibraryAgeRestrictionFilter.r18Only);
      expect(loaded.mediaTypeFilter.selected, {
        LibraryMediaTypeFilterOption.pdf,
      });
      expect(loaded.tagFilter, tags);
      expect(loaded.authorFilter, authors);
      expect(loaded.needsMetadataOnly, isTrue);
      expect(loaded.grouping, LibraryComicGrouping.none);
      expect(loaded.sortOption.field, LibraryComicSortField.readAt);
      expect(loaded.sortOption.descending, isTrue);
      expect(loaded.languageFilter, isEmpty);
      expect(loaded.parodyFilter.isActive, isFalse);
      expect(loaded.characterFilter.isActive, isFalse);

      await repository.resetComicFilters();
      expect(
        await repository.loadComicFilters(),
        LibraryComicBrowsePreferences.defaults,
      );
      expect(
        (await repository.loadSeriesFilters()).ageRestriction,
        LibraryAgeRestrictionFilter.allAges,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('unrelated_setting'), isTrue);
      expect(prefs.getKeys(), {
        'unrelated_setting',
        kLibrarySeriesAgeRestrictionStorageKey,
      });
    },
  );

  test('round-trips series dimensions without touching comics', () async {
    await repository.saveSeriesAgeRestriction(
      LibraryAgeRestrictionFilter.r18Only,
    );
    await repository.saveSeriesSerializationStatus(
      LibrarySerializationStatusFilter.ongoing,
    );
    await repository.saveSeriesGrouping(
      LibrarySeriesGrouping.bySerializationStatus,
    );
    await repository.saveSeriesSort(
      LibrarySeriesSortOption(
        field: LibrarySeriesSortField.comicCount,
        descending: true,
      ),
    );
    final loaded = await repository.loadSeriesFilters();
    expect(loaded.ageRestriction, LibraryAgeRestrictionFilter.r18Only);
    expect(
      loaded.serializationStatusFilter,
      LibrarySerializationStatusFilter.ongoing,
    );
    expect(loaded.grouping, LibrarySeriesGrouping.bySerializationStatus);
    expect(loaded.sortOption.field, LibrarySeriesSortField.comicCount);
    expect(loaded.sortOption.descending, isTrue);
    await repository.resetSeriesFilters();
    expect(
      await repository.loadSeriesFilters(),
      LibrarySeriesBrowsePreferences.defaults,
    );
    expect((await SharedPreferences.getInstance()).getKeys(), {
      'unrelated_setting',
    });
  });

  test(
    'legacy author names migrate once and current IDs survive missing authors',
    () async {
      SharedPreferences.setMockInitialValues({
        'library_author_filter_include': ['known', 'missing'],
        'library_author_filter_exclude': ['excluded'],
      });
      final withAuthors = LibraryBrowsePreferencesRepositoryImpl(
        authors: _Authors(),
      );
      final migrated = await withAuthors.loadComicFilters();
      expect(migrated.authorFilter.includeNames(), ['7']);
      expect(migrated.authorFilter.excludeNames(), ['8']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('library_author_filter_include'), isFalse);
      expect(prefs.containsKey('library_author_filter_exclude'), isFalse);
      expect(
        (await repository.loadComicFilters()).authorFilter,
        migrated.authorFilter,
      );
    },
  );

  test('page sizes normalize legacy and invalid values and default removes only its key', () async {
    SharedPreferences.setMockInitialValues({
      'library_page_size_comics': 500,
      'library_page_size_series': -1,
      'unrelated_setting': true,
    });
    expect(await repository.loadPageSizes(), (
      comics: 200,
      series: kDefaultPageSize,
    ));
    await repository.savePageSize(LibraryDisplayTarget.series, 100);
    await repository.savePageSize(
      LibraryDisplayTarget.comics,
      kDefaultPageSize,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('library_page_size_comics'), isFalse);
    expect(prefs.getInt('library_page_size_series'), 100);
    expect(prefs.getBool('unrelated_setting'), isTrue);
  });
}

class _Authors extends EmptyAuthorRepository {
  @override
  Future<List<Author>> listAll() async => [
    Author(id: 7, name: 'known'),
    Author(id: 8, name: 'excluded'),
  ];
}
