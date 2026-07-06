import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_series_catalog_controller.g.dart';

const LibrarySeriesProjection _librarySeriesProjection =
    LibrarySeriesProjection();

@Riverpod(keepAlive: true)
class LibrarySeriesCatalogController extends _$LibrarySeriesCatalogController {
  int _pageIndex = 1;
  Object? _lastQueryKey;

  int get pageIndex => _pageIndex;

  @override
  Future<LibrarySeriesCatalogState> build() async {
    _syncPaginationWithQueryKey();
    return _load();
  }

  void _syncPaginationWithQueryKey() {
    final String keyword = ref.watch(
      libraryQueryIntentProvider.select(
        (LibraryQueryIntent intent) => intent.keyword,
      ),
    );
    final Object queryKey = (
      keyword,
      ref.watch(librarySeriesTabAgeRestrictionFilterProvider),
      ref.watch(librarySeriesTabSortOptionProvider),
      ref.watch(librarySeriesTabPageSizeProvider),
    );
    if (_lastQueryKey != null && _lastQueryKey != queryKey) {
      _pageIndex = 1;
    }
    _lastQueryKey = queryKey;
  }

  Future<LibrarySeriesCatalogState> _load() async {
    ref.watch(seriesAggregateProvider);

    final String keyword = ref.read(libraryQueryIntentProvider).keyword;
    final PagedResult<Series> page = await _fetchPage(keyword);
    final int tableTotalCount = await ref
        .read(librarySeriesRepoProvider)
        .countAll();

    return LibrarySeriesCatalogState(
      items: page.items,
      pagination: LibraryPagination(
        page: page.page,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        isLoading: false,
      ),
      filterQuery: keyword,
      isSeriesTableEmpty: tableTotalCount == 0,
    );
  }

  Future<PagedResult<Series>> _fetchPage(String keyword) async {
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
          request: PageRequest(page: _pageIndex, pageSize: pageSize),
          filter: filter,
          sortOption: sortOption,
        );
    if (result.page != _pageIndex) {
      _pageIndex = result.page;
    }
    return result;
  }

  void setPage(int page) {
    if (page < 1 || page == _pageIndex) {
      return;
    }
    _pageIndex = page;
    ref.invalidateSelf();
  }

  void goToFirstPage() {
    if (_pageIndex == 1) {
      return;
    }
    _pageIndex = 1;
    ref.invalidateSelf();
  }

  void goToLastPage(int totalPages) {
    if (totalPages <= 0 || _pageIndex == totalPages) {
      return;
    }
    _pageIndex = totalPages;
    ref.invalidateSelf();
  }

  void goToPreviousPage() {
    if (_pageIndex <= 1) {
      return;
    }
    _pageIndex -= 1;
    ref.invalidateSelf();
  }

  void goToNextPage(int totalPages) {
    if (totalPages <= 0 || _pageIndex >= totalPages) {
      return;
    }
    _pageIndex += 1;
    ref.invalidateSelf();
  }

  void refresh() {
    ref.read(seriesAggregateProvider.notifier).refreshAllSeries();
    _pageIndex = 1;
    _lastQueryKey = null;
    ref.invalidateSelf();
  }
}
