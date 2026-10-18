import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/library/library_comic_filter.dart';
import 'package:hentai_library/shared/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/shared/domain/library/library_series_projection.dart';
import 'package:hentai_library/shared/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/repositories/comic_repository.dart';
import 'package:hentai_library/shared/domain/repositories/series_repository.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fakes/author_repository_test_fakes.dart';
import '../../../support/fakes/revision_throttle_test_fakes.dart';

class _FakeLibraryRevision extends LibraryRevisionNotifier {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

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
      totalCount: 0,
    );
  }

  @override
  Future<int> countAll() async => 0;

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
      totalCount: 0,
    );
  }

  @override
  Future<int> countAll() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: <Override>[
        ...sharedLibraryStateOverrides(),
        ...bootstrapCompositionOverrides(),
        ...idleRevisionThrottleOverrides(),
        libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
        authorRepoProvider.overrideWithValue(const EmptyAuthorRepository()),
        comicRepoProvider.overrideWith((Ref ref) => _FakeComicRepo()),
        seriesRepoProvider.overrideWith((Ref ref) => _FakeSeriesRepo()),
      ],
    );
  }

  test('page index resets when comics sort changes', () async {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    await container.read(libraryComicFiltersProvider.future);
    await container.read(libraryComicsCatalogControllerProvider.future);
    final LibraryComicsCatalogController controller = container.read(
      libraryComicsCatalogControllerProvider.notifier,
    );
    controller.setPage(4);
    expect(controller.pageIndex, 4);
    await container.read(libraryComicsCatalogControllerProvider.future);

    await container
        .read(libraryComicFiltersProvider.notifier)
        .setSortField(LibraryComicSortField.createdAt);
    await container.read(libraryComicsCatalogControllerProvider.future);
    expect(
      container.read(libraryComicsCatalogControllerProvider.notifier).pageIndex,
      1,
    );
  });

  test('display target change does not reset comics page index', () async {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    await container.read(libraryComicFiltersProvider.future);
    await container.read(libraryComicsCatalogControllerProvider.future);
    container.read(libraryComicsCatalogControllerProvider.notifier).setPage(4);
    await container.read(libraryComicsCatalogControllerProvider.future);
    container
        .read(libraryQueryIntentProvider.notifier)
        .setDisplayTarget(LibraryDisplayTarget.series);
    await container.read(libraryComicsCatalogControllerProvider.future);
    expect(
      container.read(libraryComicsCatalogControllerProvider.notifier).pageIndex,
      4,
    );
  });

  test(
    'query key change does not mutate page index during provider read',
    () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      await container.read(libraryComicFiltersProvider.future);
      await container.read(libraryComicsCatalogControllerProvider.future);
      container
          .read(libraryComicsCatalogControllerProvider.notifier)
          .setPage(2);
      await container.read(libraryComicsCatalogControllerProvider.future);

      await container
          .read(libraryComicFiltersProvider.notifier)
          .setSortField(LibraryComicSortField.createdAt);
      // 变更 query key 后读取目录不应在 provider rebuild 期间抛错。
      await expectLater(
        container.read(libraryComicsCatalogControllerProvider.future),
        completes,
      );
      expect(
        container
            .read(libraryComicsCatalogControllerProvider.notifier)
            .pageIndex,
        1,
      );
    },
  );
}
