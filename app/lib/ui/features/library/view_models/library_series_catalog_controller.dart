import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/catalog_pagination_engine.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_series_catalog_controller.g.dart';

const LibrarySeriesProjection _librarySeriesProjection =
    LibrarySeriesProjection();

@Riverpod(keepAlive: true)
class LibrarySeriesCatalogController extends _$LibrarySeriesCatalogController {
  final CatalogPaginationEngine _pagination = CatalogPaginationEngine();

  int get pageIndex => _pagination.pageIndex;

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
    _pagination.syncQueryKey((
      keyword,
      ref.watch(librarySeriesTabAgeRestrictionFilterProvider),
      ref.watch(librarySeriesTabSortOptionProvider),
      ref.watch(librarySeriesTabPageSizeProvider),
    ));
  }

  Future<LibrarySeriesCatalogState> _load() async {
    final LibrarySeriesSortOption sortOption = ref.read(
      librarySeriesTabSortOptionProvider,
    );
    // 随机排序每次查询顺序不同；库 revision 被动刷新不应触发重排。
    if (sortOption.field != LibrarySeriesSortField.random) {
      ref.watch(
        libraryRevisionProvider.select(
          (LibraryRevisionState state) => state.revision,
        ),
      );
    }
    final LibraryRevisionState revisionState = ref.read(
      libraryRevisionProvider,
    );

    final String keyword = ref.read(libraryQueryIntentProvider).keyword;
    final PagedResult<Series> page = await _fetchPage(keyword);
    final int tableTotalCount = await ref.read(seriesRepoProvider).countAll();

    return LibrarySeriesCatalogState(
      items: page.items,
      pagination: LibraryPagination(
        page: page.page,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        isLoading: false,
      ),
      filterQuery: keyword,
      isSeriesTableEmpty:
          revisionState.hasReceivedFirstEmit && tableTotalCount == 0,
    );
  }

  Future<PagedResult<Series>> _fetchPage(String keyword) async {
    final LibraryAgeRestrictionFilter ageRestriction = ref.read(
      librarySeriesTabAgeRestrictionFilterProvider,
    );
    final LibrarySeriesSortOption sortOption = ref.read(
      librarySeriesTabSortOptionProvider,
    );
    final LibrarySeriesFilter filter = _librarySeriesProjection.buildListFilter(
      ageRestriction: ageRestriction,
      keyword: keyword,
    );
    final int pageSize = ref.read(librarySeriesTabPageSizeProvider);
    return _pagination.fetchPage<Series>(
      pageSize: pageSize,
      fetch: (request) => ref
          .read(seriesRepoProvider)
          .fetchPage(request: request, filter: filter, sortOption: sortOption),
    );
  }

  void setPage(int page) {
    if (_pagination.setPage(page)) {
      ref.invalidateSelf();
    }
  }

  void goToFirstPage() {
    if (_pagination.goToFirstPage()) {
      ref.invalidateSelf();
    }
  }

  void goToLastPage(int totalPages) {
    if (_pagination.goToLastPage(totalPages)) {
      ref.invalidateSelf();
    }
  }

  void goToPreviousPage() {
    if (_pagination.goToPreviousPage()) {
      ref.invalidateSelf();
    }
  }

  void goToNextPage(int totalPages) {
    if (_pagination.goToNextPage(totalPages)) {
      ref.invalidateSelf();
    }
  }

  void refresh() {
    _pagination.refresh();
    ref.invalidateSelf();
  }
}
