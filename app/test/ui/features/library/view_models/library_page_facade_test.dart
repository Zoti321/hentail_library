import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/library_age_restriction_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_facade_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_sort_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fakes/revision_throttle_test_fakes.dart';

class _FakeLibraryRevision extends LibraryRevisionNotifier {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

/// 固定 250 条记录：默认 page size 50 下共 5 页。
class _FakeComicRepo implements ComicRepository {
  @override
  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required bool expandBySeries,
    required LibraryComicSortOption sortOption,
  }) async {
    return PagedResult<Comic>(
      items: const <Comic>[],
      page: request.page,
      pageSize: request.pageSize,
      totalCount: 250,
    );
  }

  @override
  Future<int> countAll() async => 250;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSeriesRepo implements SeriesRepository {
  @override
  Future<PagedResult<Series>> fetchPage({
    required PageRequest request,
    required LibrarySeriesFilter filter,
    required LibrarySeriesSortOption sortOption,
  }) async {
    return PagedResult<Series>(
      items: const <Series>[],
      page: request.page,
      pageSize: request.pageSize,
      totalCount: 250,
    );
  }

  @override
  Future<int> countAll() async => 250;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...idleRevisionThrottleOverrides(),
        libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
        comicRepoProvider.overrideWith((Ref ref) => _FakeComicRepo()),
        seriesRepoProvider.overrideWith((Ref ref) => _FakeSeriesRepo()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(libraryPageFacadeProvider, (_, _) {});
    return container;
  }

  /// Mounting the container moves Riverpod's refresh scheduling onto frames,
  /// so fake-clock tests leave no pending zero-duration timers behind.
  Future<ProviderContainer> pumpContainer(WidgetTester tester) async {
    final ProviderContainer container = createContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SizedBox.shrink(),
      ),
    );
    return container;
  }

  test('selectDisplayTarget switches the visible tab', () {
    final ProviderContainer container = createContainer();
    expect(
      container.read(libraryPageFacadeProvider).displayTarget,
      LibraryDisplayTarget.comics,
    );

    container
        .read(libraryPageFacadeProvider.notifier)
        .selectDisplayTarget(LibraryDisplayTarget.series);

    expect(
      container.read(libraryPageFacadeProvider).displayTarget,
      LibraryDisplayTarget.series,
    );
  });

  testWidgets('setKeyword applies after the debounce window', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpContainer(tester);
    final LibraryPageFacadeNotifier facade = container.read(
      libraryPageFacadeProvider.notifier,
    );

    facade.setKeyword('first');
    facade.setKeyword('  second ');
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(libraryPageFacadeProvider).keyword, '');

    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(libraryPageFacadeProvider).keyword, '  second ');
  });

  testWidgets(
    'resetFilters restores the active tab filters and can clear keyword',
    (WidgetTester tester) async {
      final ProviderContainer container = await pumpContainer(tester);
      final LibraryPageFacadeNotifier facade = container.read(
        libraryPageFacadeProvider.notifier,
      );
      await container.read(libraryAgeRestrictionFilterProvider.future);
      await container.read(libraryTabSortProvider.future);
      await container
          .read(libraryAgeRestrictionFilterProvider.notifier)
          .setFilter(
            LibraryDisplayTarget.comics,
            LibraryAgeRestrictionFilter.r18Only,
          );
      facade.setKeyword('kw');
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        container.read(libraryPageFacadeProvider).isFilterSortCustomized,
        true,
      );

      await facade.resetFilters();
      expect(
        container.read(libraryPageFacadeProvider).isFilterSortCustomized,
        false,
      );
      expect(container.read(libraryPageFacadeProvider).keyword, 'kw');

      await facade.resetFilters(clearKeyword: true);
      expect(container.read(libraryPageFacadeProvider).keyword, '');
    },
  );

  test('resetFilters only touches the active tab', () async {
    final ProviderContainer container = createContainer();
    await container.read(libraryAgeRestrictionFilterProvider.future);
    await container.read(libraryTabSortProvider.future);
    await container
        .read(libraryAgeRestrictionFilterProvider.notifier)
        .setFilter(
          LibraryDisplayTarget.comics,
          LibraryAgeRestrictionFilter.r18Only,
        );
    final LibraryPageFacadeNotifier facade = container.read(
      libraryPageFacadeProvider.notifier,
    );

    facade.selectDisplayTarget(LibraryDisplayTarget.series);
    await facade.resetFilters();

    expect(
      (await container.read(libraryAgeRestrictionFilterProvider.future)).comics,
      LibraryAgeRestrictionFilter.r18Only,
    );
  });

  test('jumpPage moves the requested tab within its page range', () async {
    final ProviderContainer container = createContainer();
    final LibraryPageFacadeNotifier facade = container.read(
      libraryPageFacadeProvider.notifier,
    );
    Future<int?> comicsPageAfter(LibraryPageJump jump) async {
      facade.jumpPage(LibraryDisplayTarget.comics, jump);
      await container.read(libraryComicsCatalogControllerProvider.future);
      return container.read(libraryPageFacadeProvider).comicsPage;
    }

    await container.read(libraryComicsCatalogControllerProvider.future);
    expect(container.read(libraryPageFacadeProvider).comicsPage, 1);

    expect(await comicsPageAfter(LibraryPageJump.next), 2);
    expect(await comicsPageAfter(LibraryPageJump.last), 5);
    expect(await comicsPageAfter(LibraryPageJump.next), 5);
    expect(await comicsPageAfter(LibraryPageJump.previous), 4);
    expect(await comicsPageAfter(LibraryPageJump.first), 1);
  });

  test('jumpPage on series leaves the comics page alone', () async {
    final ProviderContainer container = createContainer();
    await container.read(libraryComicsCatalogControllerProvider.future);
    await container.read(librarySeriesCatalogControllerProvider.future);

    container
        .read(libraryPageFacadeProvider.notifier)
        .jumpPage(LibraryDisplayTarget.series, LibraryPageJump.next);
    await container.read(librarySeriesCatalogControllerProvider.future);

    final LibraryPageFacadeState state = container.read(
      libraryPageFacadeProvider,
    );
    expect(state.seriesPage, 2);
    expect(state.comicsPage, 1);
  });

  test('setPageSize applies to the active tab only', () async {
    final ProviderContainer container = createContainer();
    await container.read(libraryTabPageSizeProvider.future);
    final LibraryPageFacadeNotifier facade = container.read(
      libraryPageFacadeProvider.notifier,
    );

    facade.selectDisplayTarget(LibraryDisplayTarget.series);
    await facade.setPageSize(100);

    final LibraryPageFacadeState state = container.read(
      libraryPageFacadeProvider,
    );
    expect(state.seriesPageSize, 100);
    expect(state.comicsPageSize, 50);
  });

  group('libraryPageShouldScrollToTop', () {
    const LibraryPageFacadeState base = (
      displayTarget: LibraryDisplayTarget.comics,
      keyword: '',
      isFilterSortCustomized: false,
      comicsPage: 1,
      seriesPage: 1,
      comicsPageSize: 50,
      seriesPageSize: 50,
    );
    LibraryPageFacadeState copy({
      LibraryDisplayTarget displayTarget = LibraryDisplayTarget.comics,
      String keyword = '',
      bool isFilterSortCustomized = false,
      int? comicsPage = 1,
      int? seriesPage = 1,
      int comicsPageSize = 50,
      int seriesPageSize = 50,
    }) {
      return (
        displayTarget: displayTarget,
        keyword: keyword,
        isFilterSortCustomized: isFilterSortCustomized,
        comicsPage: comicsPage,
        seriesPage: seriesPage,
        comicsPageSize: comicsPageSize,
        seriesPageSize: seriesPageSize,
      );
    }

    test('first emission does not scroll', () {
      expect(libraryPageShouldScrollToTop(null, base), false);
    });

    test('tab switch scrolls', () {
      expect(
        libraryPageShouldScrollToTop(
          base,
          copy(displayTarget: LibraryDisplayTarget.series),
        ),
        true,
      );
    });

    test('page turn on either tab scrolls', () {
      expect(libraryPageShouldScrollToTop(base, copy(comicsPage: 2)), true);
      expect(libraryPageShouldScrollToTop(base, copy(seriesPage: 3)), true);
    });

    test('catalog first load or reload gap does not scroll', () {
      expect(libraryPageShouldScrollToTop(copy(comicsPage: null), base), false);
      expect(libraryPageShouldScrollToTop(base, copy(seriesPage: null)), false);
    });

    test('page size change scrolls', () {
      expect(
        libraryPageShouldScrollToTop(base, copy(seriesPageSize: 100)),
        true,
      );
    });

    test('keyword or filter customization alone does not scroll', () {
      expect(
        libraryPageShouldScrollToTop(
          base,
          copy(keyword: 'x', isFilterSortCustomized: true),
        ),
        false,
      );
    });
  });
}
