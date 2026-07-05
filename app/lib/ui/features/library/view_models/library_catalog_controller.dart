import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_catalog_controller.g.dart';

const LibraryComicProjection _libraryComicProjection = LibraryComicProjection();
const LibrarySeriesProjection _librarySeriesProjection =
    LibrarySeriesProjection();

@Riverpod(keepAlive: true)
class LibraryCatalogController extends _$LibraryCatalogController {
  int _comicsPageIndex = 1;
  int _seriesPageIndex = 1;
  Object? _lastComicsQueryKey;
  Object? _lastSeriesQueryKey;

  int get comicsPageIndex => _comicsPageIndex;

  int get seriesPageIndex => _seriesPageIndex;

  @override
  Future<LibraryPageSnapshot> build() async {
    _syncPaginationWithQueryKeys();
    return _loadSnapshot();
  }

  void _syncPaginationWithQueryKeys() {
    final String keyword = ref.watch(
      libraryQueryIntentProvider.select((LibraryQueryIntent intent) => intent.keyword),
    );
    final Object comicsQueryKey = (
      keyword,
      ref.watch(libraryComicsTabAgeRestrictionFilterProvider),
      ref.watch(libraryComicsTabSortOptionProvider),
      ref.watch(libraryComicsTabPageSizeProvider),
    );
    if (_lastComicsQueryKey != null && _lastComicsQueryKey != comicsQueryKey) {
      _comicsPageIndex = 1;
    }
    _lastComicsQueryKey = comicsQueryKey;

    final Object seriesQueryKey = (
      keyword,
      ref.watch(librarySeriesTabAgeRestrictionFilterProvider),
      ref.watch(librarySeriesTabSortOptionProvider),
      ref.watch(librarySeriesTabPageSizeProvider),
    );
    if (_lastSeriesQueryKey != null && _lastSeriesQueryKey != seriesQueryKey) {
      _seriesPageIndex = 1;
    }
    _lastSeriesQueryKey = seriesQueryKey;
  }

  Future<LibraryPageSnapshot> _loadSnapshot() async {
    ref.watch(
      comicAggregateProvider.select(
        (ComicAggregateState state) => state.changeGeneration,
      ),
    );
    ref.watch(seriesAggregateProvider);

    final ComicAggregateState aggregateState = ref.read(comicAggregateProvider);
    if (aggregateState.streamError != null) {
      throw aggregateState.streamError!;
    }

    final LibraryQueryIntent intent = ref.read(libraryQueryIntentProvider);
    final String keyword = intent.keyword;
    final LibraryDisplayTarget displayTarget = intent.displayTarget;
    final bool hasReceivedFirstEmit = aggregateState.hasReceivedFirstChange;

    final PagedResult<Comic> comicsPage = await _fetchComicsPage(keyword);
    final PagedResult<Series> seriesPage = await _fetchSeriesPage(keyword);
    final int tableTotalCount = await ref.read(comicRepoProvider).countAll();

    return LibraryPageSnapshot(
      comics: comicsPage.items,
      comicsPagination: LibraryPagination(
        page: comicsPage.page,
        totalPages: comicsPage.totalPages,
        totalCount: comicsPage.totalCount,
        isLoading: false,
      ),
      series: seriesPage.items,
      seriesPagination: LibraryPagination(
        page: seriesPage.page,
        totalPages: seriesPage.totalPages,
        totalCount: seriesPage.totalCount,
        isLoading: false,
      ),
      displayedComicCount: comicsPage.totalCount,
      displayedSeriesCount: seriesPage.totalCount,
      displayTarget: displayTarget,
      filterQuery: keyword,
      hasReceivedFirstEmit: hasReceivedFirstEmit,
      isComicTableEmpty: hasReceivedFirstEmit && tableTotalCount == 0,
    );
  }

  Future<PagedResult<Comic>> _fetchComicsPage(String keyword) async {
    final LibraryAgeRestrictionFilter ageRestriction = ref.read(
      libraryComicsTabAgeRestrictionFilterProvider,
    );
    final LibraryComicSortOption sortOption = ref.read(
      libraryComicsTabSortOptionProvider,
    );
    final LibraryComicFilter filter = _libraryComicProjection.buildListFilter(
      ageRestriction: ageRestriction,
      keyword: keyword,
    );
    final int pageSize = ref.read(libraryComicsTabPageSizeProvider);
    final PagedResult<Comic> result = await ref
        .read(comicRepoProvider)
        .fetchComicsPage(
          request: PageRequest(page: _comicsPageIndex, pageSize: pageSize),
          filter: filter,
          sortOption: sortOption,
        );
    if (result.page != _comicsPageIndex) {
      _comicsPageIndex = result.page;
    }
    return result;
  }

  Future<PagedResult<Series>> _fetchSeriesPage(String keyword) async {
    final LibraryAgeRestrictionFilter ageRestriction = ref.read(
      librarySeriesTabAgeRestrictionFilterProvider,
    );
    final LibraryComicSortOption sortOption = ref.read(
      librarySeriesTabSortOptionProvider,
    );
    final LibrarySeriesFilter filter = _librarySeriesProjection.buildListFilter(
      ageRestriction: ageRestriction,
      keyword: keyword,
    );
    final int pageSize = ref.read(librarySeriesTabPageSizeProvider);
    final PagedResult<Series> result = await ref
        .read(librarySeriesRepoProvider)
        .fetchPage(
          request: PageRequest(page: _seriesPageIndex, pageSize: pageSize),
          filter: filter,
          sortOption: sortOption,
        );
    if (result.page != _seriesPageIndex) {
      _seriesPageIndex = result.page;
    }
    return result;
  }

  void setComicsPage(int page) {
    if (page < 1 || page == _comicsPageIndex) {
      return;
    }
    _comicsPageIndex = page;
    ref.invalidateSelf();
  }

  void setSeriesPage(int page) {
    if (page < 1 || page == _seriesPageIndex) {
      return;
    }
    _seriesPageIndex = page;
    ref.invalidateSelf();
  }

  void goToComicsFirstPage() {
    if (_comicsPageIndex == 1) {
      return;
    }
    _comicsPageIndex = 1;
    ref.invalidateSelf();
  }

  void goToComicsLastPage(int totalPages) {
    if (totalPages <= 0 || _comicsPageIndex == totalPages) {
      return;
    }
    _comicsPageIndex = totalPages;
    ref.invalidateSelf();
  }

  void goToComicsPreviousPage() {
    if (_comicsPageIndex <= 1) {
      return;
    }
    _comicsPageIndex -= 1;
    ref.invalidateSelf();
  }

  void goToComicsNextPage(int totalPages) {
    if (totalPages <= 0 || _comicsPageIndex >= totalPages) {
      return;
    }
    _comicsPageIndex += 1;
    ref.invalidateSelf();
  }

  void goToSeriesFirstPage() {
    if (_seriesPageIndex == 1) {
      return;
    }
    _seriesPageIndex = 1;
    ref.invalidateSelf();
  }

  void goToSeriesLastPage(int totalPages) {
    if (totalPages <= 0 || _seriesPageIndex == totalPages) {
      return;
    }
    _seriesPageIndex = totalPages;
    ref.invalidateSelf();
  }

  void goToSeriesPreviousPage() {
    if (_seriesPageIndex <= 1) {
      return;
    }
    _seriesPageIndex -= 1;
    ref.invalidateSelf();
  }

  void goToSeriesNextPage(int totalPages) {
    if (totalPages <= 0 || _seriesPageIndex >= totalPages) {
      return;
    }
    _seriesPageIndex += 1;
    ref.invalidateSelf();
  }

  void refreshCatalog() {
    ref.read(comicAggregateProvider.notifier).refreshStream();
    _comicsPageIndex = 1;
    _seriesPageIndex = 1;
    _lastComicsQueryKey = null;
    _lastSeriesQueryKey = null;
    ref.read(seriesAggregateProvider.notifier).refreshAllSeries();
    ref.invalidateSelf();
  }
}
