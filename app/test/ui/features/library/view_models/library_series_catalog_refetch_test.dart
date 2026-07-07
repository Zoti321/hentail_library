import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _ControllableLibraryRevision extends LibraryRevision {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }

  void setStreamError(Object error) {
    state = state.copyWith(streamError: error);
  }

  void bumpRevision() {
    state = state.copyWith(revision: state.revision + 1, streamError: null);
  }
}

class _CountingSeriesRepo implements SeriesRepository {
  int fetchCount = 0;

  @override
  Future<PagedResult<Series>> fetchPage({
    required PageRequest request,
    required LibrarySeriesFilter filter,
    required LibrarySeriesSortOption sortOption,
  }) async {
    fetchCount++;
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
  _ControllableLibraryRevision revisionNotifier(ProviderContainer container) {
    return container.read(libraryRevisionProvider.notifier)
        as _ControllableLibraryRevision;
  }

  test(
    'streamError-only revision updates do not refetch series catalog',
    () async {
      final _CountingSeriesRepo repo = _CountingSeriesRepo();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          seriesRepoProvider.overrideWith((Ref ref) => repo),
          libraryRevisionProvider.overrideWith(
            _ControllableLibraryRevision.new,
          ),
          librarySeriesTabSortOptionProvider.overrideWith(
            (Ref ref) => const LibrarySeriesSortOption(
              field: LibrarySeriesSortField.random,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(librarySeriesCatalogControllerProvider.future);
      expect(repo.fetchCount, 1);

      revisionNotifier(container).setStreamError(StateError('stream failed'));
      await Future<void>.delayed(Duration.zero);
      expect(repo.fetchCount, 1);
    },
  );

  test('revision bump does not refetch random sort catalog', () async {
    final _CountingSeriesRepo repo = _CountingSeriesRepo();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        seriesRepoProvider.overrideWith((Ref ref) => repo),
        libraryRevisionProvider.overrideWith(_ControllableLibraryRevision.new),
        librarySeriesTabSortOptionProvider.overrideWith(
          (Ref ref) => const LibrarySeriesSortOption(
            field: LibrarySeriesSortField.random,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(librarySeriesCatalogControllerProvider.future);
    expect(repo.fetchCount, 1);

    revisionNotifier(container).bumpRevision();
    await Future<void>.delayed(Duration.zero);
    expect(repo.fetchCount, 1);
  });

  test('revision bump still refetches deterministic sort catalog', () async {
    final _CountingSeriesRepo repo = _CountingSeriesRepo();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        seriesRepoProvider.overrideWith((Ref ref) => repo),
        libraryRevisionProvider.overrideWith(_ControllableLibraryRevision.new),
        librarySeriesTabSortOptionProvider.overrideWith(
          (Ref ref) =>
              const LibrarySeriesSortOption(field: LibrarySeriesSortField.name),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(librarySeriesCatalogControllerProvider.future);
    expect(repo.fetchCount, 1);

    revisionNotifier(container).bumpRevision();
    await container.read(librarySeriesCatalogControllerProvider.future);
    expect(repo.fetchCount, 2);
  });
}
