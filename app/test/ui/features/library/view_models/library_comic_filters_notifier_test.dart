import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_expand_by_series.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_needs_metadata_only.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fakes/author_repository_test_fakes.dart';

ProviderContainer createContainer() {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      authorRepoProvider.overrideWithValue(const EmptyAuthorRepository()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'selecting readAt for the first time defaults to descending, then toggles',
    () async {
      final ProviderContainer container = createContainer();
      await container.read(libraryComicFiltersProvider.future);

      await container
          .read(libraryComicFiltersProvider.notifier)
          .setSortField(LibraryComicSortField.readAt);

      LibraryComicSortOption sort = (await container.read(
        libraryComicFiltersProvider.future,
      )).sortOption;
      expect(sort.field, LibraryComicSortField.readAt);
      expect(sort.descending, isTrue);

      await container
          .read(libraryComicFiltersProvider.notifier)
          .setSortField(LibraryComicSortField.readAt);

      sort = (await container.read(
        libraryComicFiltersProvider.future,
      )).sortOption;
      expect(sort.field, LibraryComicSortField.readAt);
      expect(sort.descending, isFalse);
    },
  );

  test(
    'selecting a non-readAt field for the first time still defaults to ascending',
    () async {
      final ProviderContainer container = createContainer();
      await container.read(libraryComicFiltersProvider.future);

      await container
          .read(libraryComicFiltersProvider.notifier)
          .setSortField(LibraryComicSortField.createdAt);

      final LibraryComicSortOption sort = (await container.read(
        libraryComicFiltersProvider.future,
      )).sortOption;
      expect(sort.field, LibraryComicSortField.createdAt);
      expect(sort.descending, isFalse);
    },
  );

  test('resetAll restores every comics filter and sort to defaults', () async {
    final ProviderContainer container = createContainer();
    await container.read(libraryComicFiltersProvider.future);
    final LibraryComicFiltersNotifier notifier = container.read(
      libraryComicFiltersProvider.notifier,
    );

    await notifier.setAgeRestriction(LibraryAgeRestrictionFilter.r18Only);
    await notifier.toggleMediaType(LibraryMediaTypeFilterOption.pdf);
    await notifier.toggleTag('glasses');
    await notifier.toggleAuthor('1');
    await notifier.toggleIncludeSet(LibraryIncludeSetKind.language, 'zh');
    await notifier.toggleIncludeSet(LibraryIncludeSetKind.parody, 'p');
    await notifier.toggleIncludeSet(LibraryIncludeSetKind.character, 'c');
    await notifier.setNeedsMetadataOnly(true);
    await notifier.setExpandBySeries(false);
    await notifier.setSortField(LibraryComicSortField.createdAt);

    await notifier.resetAll();

    final LibraryComicFiltersState state = await container.read(
      libraryComicFiltersProvider.future,
    );
    expect(state.ageRestriction, LibraryAgeRestrictionFilter.unrestricted);
    expect(state.mediaTypeFilter.isActive, isFalse);
    expect(state.tagFilter.isActive, isFalse);
    expect(state.authorFilter.isActive, isFalse);
    expect(state.languageFilter, isEmpty);
    expect(state.parodyFilter, isEmpty);
    expect(state.characterFilter, isEmpty);
    expect(state.needsMetadataOnly, LibraryNeedsMetadataOnly.defaultValue);
    expect(state.expandBySeries, LibraryExpandBySeries.defaultValue);
    expect(state.sortOption.field, kLibraryDefaultSortOption.field);
    expect(state.sortOption.descending, kLibraryDefaultSortOption.descending);
  });

  test('preferences persist across containers', () async {
    final ProviderContainer first = createContainer();
    await first.read(libraryComicFiltersProvider.future);
    final LibraryComicFiltersNotifier notifier = first.read(
      libraryComicFiltersProvider.notifier,
    );
    await notifier.setAgeRestriction(LibraryAgeRestrictionFilter.allAges);
    await notifier.toggleMediaType(LibraryMediaTypeFilterOption.epub);
    await notifier.setNeedsMetadataOnly(true);
    await notifier.setExpandBySeries(false);
    await notifier.setSortField(LibraryComicSortField.fileSize);
    first.dispose();

    final ProviderContainer second = createContainer();
    final LibraryComicFiltersState state = await second.read(
      libraryComicFiltersProvider.future,
    );
    expect(state.ageRestriction, LibraryAgeRestrictionFilter.allAges);
    expect(state.mediaTypeFilter.selected, <LibraryMediaTypeFilterOption>{
      LibraryMediaTypeFilterOption.epub,
    });
    expect(state.needsMetadataOnly, isTrue);
    expect(state.expandBySeries, isFalse);
    expect(state.sortOption.field, LibraryComicSortField.fileSize);
  });

  test('session include-sets do not persist across containers', () async {
    final ProviderContainer first = createContainer();
    await first.read(libraryComicFiltersProvider.future);
    await first
        .read(libraryComicFiltersProvider.notifier)
        .toggleIncludeSet(LibraryIncludeSetKind.language, 'zh');
    first.dispose();

    final ProviderContainer second = createContainer();
    final LibraryComicFiltersState state = await second.read(
      libraryComicFiltersProvider.future,
    );
    expect(state.languageFilter, isEmpty);
  });

  test('derived query filter and isCustomized reflect current state', () async {
    final ProviderContainer container = createContainer();
    await container.read(libraryComicFiltersProvider.future);
    expect(container.read(libraryComicFiltersIsCustomizedProvider), isFalse);

    await container
        .read(libraryComicFiltersProvider.notifier)
        .setAgeRestriction(LibraryAgeRestrictionFilter.r18Only);

    expect(container.read(libraryComicFiltersIsCustomizedProvider), isTrue);
    final LibraryComicFilter filter = container.read(
      libraryComicFilterQueryProvider,
    );
    expect(filter.showR18, isTrue);
    expect(filter.contentRatings, <ContentRating>{ContentRating.r18});
  });

  test(
    'tag and author tri-state toggles survive to the query filter',
    () async {
      final ProviderContainer container = createContainer();
      await container.read(libraryComicFiltersProvider.future);
      final LibraryComicFiltersNotifier notifier = container.read(
        libraryComicFiltersProvider.notifier,
      );
      await notifier.toggleTag('glasses');
      await notifier.setTagIncludeMode(LibraryMetadataIncludeMode.all);
      await notifier.toggleAuthor('42');

      final LibraryComicFiltersState state = await container.read(
        libraryComicFiltersProvider.future,
      );
      expect(
        state.tagFilter.pickStateFor('glasses'),
        LibraryTriStatePick.include,
      );
      expect(state.tagFilter.includeMode, LibraryMetadataIncludeMode.all);
      expect(state.authorFilter.includeNames(), <String>{'42'});
    },
  );
}
