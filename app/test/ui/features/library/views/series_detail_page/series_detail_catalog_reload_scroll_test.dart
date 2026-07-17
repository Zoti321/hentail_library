import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_state.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;

/// Mirrors [SeriesDetail._buildComicsSection]'s AsyncValue.when usage.
class _SeriesDetailCatalogWhenHarness extends StatelessWidget {
  const _SeriesDetailCatalogWhenHarness({
    required this.catalogAsync,
    required this.scrollController,
    this.skipLoadingOnReload = false,
  });

  final AsyncValue<SeriesDetailComicsCatalogState> catalogAsync;
  final ScrollController scrollController;
  final bool skipLoadingOnReload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: catalogAsync.when(
        skipLoadingOnReload: skipLoadingOnReload,
        data: (SeriesDetailComicsCatalogState catalog) {
          return Column(
            children: <Widget>[
              for (final Comic comic in catalog.items)
                SizedBox(height: 120, child: Text(comic.title)),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object error, StackTrace _) => Text('$error'),
      ),
    );
  }
}

class _ControllableLibraryRevision extends LibraryRevision {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }

  void bump() {
    state = state.copyWith(revision: state.revision + 1, streamError: null);
  }
}

class _DelayedSeriesRepo implements SeriesRepository {
  _DelayedSeriesRepo(this.comics);

  final List<Comic> comics;
  final Completer<void> gate = Completer<void>();
  int fetchCount = 0;

  @override
  Future<PagedResult<Comic>> fetchComicsPage({
    required String seriesId,
    required PageRequest request,
  }) async {
    fetchCount++;
    if (fetchCount > 1) {
      await gate.future;
    }
    return PagedResult<Comic>(
      items: comics,
      page: request.page,
      pageSize: request.pageSize,
      totalCount: comics.length,
    );
  }

  @override
  Future<SeriesComicsMetadata> fetchComicsMetadata(String seriesId) async {
    return const SeriesComicsMetadata(
      authors: <String>[],
      tags: <String>[],
      hasR18: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic(int index) {
  return Comic(
    comicId: 'comic-$index',
    path: '/comics/$index',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: DateTime.utc(2024),
    lastUpdatedAt: DateTime.utc(2024),
    title: 'Comic $index',
    pageCount: 10,
  );
}

SeriesDetailComicsCatalogState _catalogState(List<Comic> comics) {
  return SeriesDetailComicsCatalogState(
    items: comics,
    pagination: LibraryPagination(
      page: 1,
      totalPages: 1,
      totalCount: comics.length,
      isLoading: false,
    ),
  );
}

/// Same reloading shape Riverpod emits after dependency invalidation.
AsyncValue<T> _asyncReloadingWithPrevious<T>(T previous) {
  return AsyncLoading<T>()
  // ignore: invalid_use_of_internal_member
  .copyWithPrevious(AsyncData<T>(previous), isRefresh: false);
}

void main() {
  test(
    'dependency reload makes catalog AsyncValue isReloading with previous value',
    () async {
      final List<Comic> comics = List<Comic>.generate(8, _comic);
      final _DelayedSeriesRepo repo = _DelayedSeriesRepo(comics);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionProvider.overrideWith(
            _ControllableLibraryRevision.new,
          ),
          seriesRepoProvider.overrideWith((Ref ref) => repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(
        seriesDetailComicsCatalogControllerProvider('series-1').future,
      );
      expect(repo.fetchCount, 1);

      final _ControllableLibraryRevision revision =
          container.read(libraryRevisionProvider.notifier)
              as _ControllableLibraryRevision;
      revision.bump();
      await Future<void>.delayed(Duration.zero);

      final AsyncValue<SeriesDetailComicsCatalogState> midReload = container
          .read(seriesDetailComicsCatalogControllerProvider('series-1'));
      expect(midReload.isLoading, isTrue);
      expect(midReload.hasValue, isTrue);
      expect(midReload.isReloading, isTrue);
      expect(midReload.value?.items.length, comics.length);

      // Same when() call as SeriesDetail before fix → drops to loading branch.
      final String branch = midReload.when(
        data: (_) => 'data',
        loading: () => 'loading',
        error: (Object error, StackTrace stackTrace) => 'error',
      );
      expect(branch, 'loading');

      repo.gate.complete();
      await container.read(
        seriesDetailComicsCatalogControllerProvider('series-1').future,
      );
    },
  );

  testWidgets(
    'catalog reload without skipLoadingOnReload clamps scroll to top',
    (WidgetTester tester) async {
      final List<Comic> comics = List<Comic>.generate(20, _comic);
      final SeriesDetailComicsCatalogState catalog = _catalogState(comics);
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final ValueNotifier<AsyncValue<SeriesDetailComicsCatalogState>>
      catalogAsync = ValueNotifier<AsyncValue<SeriesDetailComicsCatalogState>>(
        AsyncData<SeriesDetailComicsCatalogState>(catalog),
      );
      addTearDown(catalogAsync.dispose);

      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:
                ValueListenableBuilder<
                  AsyncValue<SeriesDetailComicsCatalogState>
                >(
                  valueListenable: catalogAsync,
                  builder:
                      (
                        BuildContext context,
                        AsyncValue<SeriesDetailComicsCatalogState> async,
                        Widget? _,
                      ) {
                        return _SeriesDetailCatalogWhenHarness(
                          catalogAsync: async,
                          scrollController: scrollController,
                        );
                      },
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scrollController.position.maxScrollExtent, greaterThan(200));
      scrollController.jumpTo(240);
      await tester.pump();
      expect(scrollController.offset, 240);

      catalogAsync.value = _asyncReloadingWithPrevious(catalog);
      await tester.pump();

      expect(scrollController.offset, 0);
    },
  );

  testWidgets(
    'catalog reload with skipLoadingOnReload preserves scroll offset',
    (WidgetTester tester) async {
      final List<Comic> comics = List<Comic>.generate(20, _comic);
      final SeriesDetailComicsCatalogState catalog = _catalogState(comics);
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final ValueNotifier<AsyncValue<SeriesDetailComicsCatalogState>>
      catalogAsync = ValueNotifier<AsyncValue<SeriesDetailComicsCatalogState>>(
        AsyncData<SeriesDetailComicsCatalogState>(catalog),
      );
      addTearDown(catalogAsync.dispose);

      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body:
                ValueListenableBuilder<
                  AsyncValue<SeriesDetailComicsCatalogState>
                >(
                  valueListenable: catalogAsync,
                  builder:
                      (
                        BuildContext context,
                        AsyncValue<SeriesDetailComicsCatalogState> async,
                        Widget? _,
                      ) {
                        return _SeriesDetailCatalogWhenHarness(
                          catalogAsync: async,
                          scrollController: scrollController,
                          skipLoadingOnReload: true,
                        );
                      },
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      scrollController.jumpTo(240);
      await tester.pump();

      catalogAsync.value = _asyncReloadingWithPrevious(catalog);
      await tester.pump();

      expect(scrollController.offset, 240);
    },
  );
}
