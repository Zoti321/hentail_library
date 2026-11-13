import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_comic_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_series_browse_preferences.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_page_size_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/library_browse_preferences_provider.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';

void main() {
  late _Preferences preferences;
  late ProviderContainer container;

  setUp(() {
    preferences = _Preferences();
    container = ProviderContainer(
      overrides: [
        libraryBrowsePreferencesRepositoryProvider.overrideWithValue(
          preferences,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'loads both tabs and page sizes through the injected repository',
    () async {
      expect(
        await container.read(libraryComicFiltersProvider.future),
        preferences.comics,
      );
      expect(
        await container.read(librarySeriesFiltersProvider.future),
        preferences.series,
      );
      expect(await container.read(libraryTabPageSizeProvider.future), (
        comics: 20,
        series: 100,
      ));
      expect(preferences.calls, [
        'load comics',
        'load series',
        'load page sizes',
      ]);
    },
  );

  test(
    'age selection stays optimistic and propagates persistence failure',
    () async {
      await container.read(libraryComicFiltersProvider.future);
      final notifier = container.read(libraryComicFiltersProvider.notifier);
      final gate = Completer<void>();
      preferences.pendingWrite = gate.future;

      final write = notifier.setAgeRestriction(
        LibraryAgeRestrictionFilter.r18Only,
      );
      final failure = expectLater(write, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(libraryComicFiltersProvider).requireValue.ageRestriction,
        LibraryAgeRestrictionFilter.r18Only,
      );
      gate.completeError(StateError('storage unavailable'));
      await failure;
      expect(preferences.calls, ['load comics', 'comic age r18Only']);
    },
  );

  test(
    'session-only filters never write and failed reset preserves them',
    () async {
      await container.read(libraryComicFiltersProvider.future);
      final notifier = container.read(libraryComicFiltersProvider.notifier);
      await notifier.toggleIncludeSet(LibraryIncludeSetKind.language, 'zh');
      await notifier.toggleParody('original');
      await notifier.toggleCharacter('character');
      expect(preferences.calls, ['load comics']);

      preferences.failReset = true;
      await expectLater(notifier.resetAll(), throwsStateError);
      expect(
        container.read(libraryComicFiltersProvider).requireValue.languageFilter,
        {'zh'},
      );
      preferences.failReset = false;
      await notifier.resetAll();
      expect(
        container.read(libraryComicFiltersProvider).requireValue,
        LibraryComicBrowsePreferences.defaults,
      );
    },
  );

  test(
    'page-size changes normalize before publishing and persisting',
    () async {
      await container.read(libraryTabPageSizeProvider.future);
      await container
          .read(libraryTabPageSizeProvider.notifier)
          .setPageSize(LibraryDisplayTarget.comics, 500);
      expect(container.read(libraryTabPageSizeProvider).requireValue, (
        comics: 200,
        series: 100,
      ));
      expect(preferences.calls, ['load page sizes', 'page size comics 200']);
    },
  );
}

class _Preferences implements LibraryBrowsePreferencesRepository {
  final comics = LibraryComicBrowsePreferences.defaults;
  final series = LibrarySeriesBrowsePreferences.defaults;
  final calls = <String>[];
  Future<void>? pendingWrite;
  bool failReset = false;

  @override
  Future<LibraryComicBrowsePreferences> loadComicFilters() async {
    calls.add('load comics');
    return comics;
  }

  @override
  Future<LibrarySeriesBrowsePreferences> loadSeriesFilters() async {
    calls.add('load series');
    return series;
  }

  @override
  Future<LibraryTabPageSizeSettings> loadPageSizes() async {
    calls.add('load page sizes');
    return (comics: 20, series: 100);
  }

  @override
  Future<void> saveComicAgeRestriction(
    LibraryAgeRestrictionFilter filter,
  ) async {
    calls.add('comic age ${filter.name}');
    await pendingWrite;
  }

  @override
  Future<void> resetComicFilters() async {
    calls.add('reset comics');
    if (failReset) throw StateError('storage unavailable');
  }

  @override
  Future<void> savePageSize(LibraryDisplayTarget target, int pageSize) async {
    calls.add('page size ${target.name} $pageSize');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
