import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_settings.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _ComicsSortRevision extends Notifier<int> {
  @override
  int build() => 0;
}

final _comicsSortRevisionProvider = NotifierProvider<_ComicsSortRevision, int>(
  _ComicsSortRevision.new,
);

class _FakeComicAggregateNotifier extends ComicAggregateNotifier {
  @override
  ComicAggregateState build() {
    return const ComicAggregateState(
      changeGeneration: 1,
      hasReceivedFirstChange: true,
    );
  }
}

class _FakeComicRepo implements ComicRepository {
  @override
  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
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
  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: <Override>[
        allSeriesProvider.overrideWith((Ref ref) async => <Series>[]),
        comicAggregateProvider.overrideWith(_FakeComicAggregateNotifier.new),
        comicRepoProvider.overrideWith((Ref ref) => _FakeComicRepo()),
        seriesRepoProvider.overrideWith((Ref ref) => _FakeSeriesRepo()),
        libraryComicsTabSortOptionProvider.overrideWith((Ref ref) {
          final int revision = ref.watch(_comicsSortRevisionProvider);
          return revision == 0
              ? kLibraryDefaultSortOption
              : LibraryComicSortOption(descending: true);
        }),
      ],
    );
  }

  test('page index resets when comics sort changes', () async {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

    await container.read(libraryComicsCatalogControllerProvider.future);
    final LibraryComicsCatalogController controller = container.read(
      libraryComicsCatalogControllerProvider.notifier,
    );
    controller.setPage(4);
    expect(controller.pageIndex, 4);
    await container.read(libraryComicsCatalogControllerProvider.future);

    container.read(_comicsSortRevisionProvider.notifier).state = 1;
    await container.read(libraryComicsCatalogControllerProvider.future);
    expect(
      container.read(libraryComicsCatalogControllerProvider.notifier).pageIndex,
      1,
    );
  });

  test('display target change does not reset comics page index', () async {
    final ProviderContainer container = createContainer();
    addTearDown(container.dispose);

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

      await container.read(libraryComicsCatalogControllerProvider.future);
      container
          .read(libraryComicsCatalogControllerProvider.notifier)
          .setPage(2);
      await container.read(libraryComicsCatalogControllerProvider.future);
      await expectLater(() async {
        container.read(_comicsSortRevisionProvider.notifier).state = 1;
        await container.read(libraryComicsCatalogControllerProvider.future);
      }, returnsNormally);
      expect(
        container
            .read(libraryComicsCatalogControllerProvider.notifier)
            .pageIndex,
        1,
      );
    },
  );
}
