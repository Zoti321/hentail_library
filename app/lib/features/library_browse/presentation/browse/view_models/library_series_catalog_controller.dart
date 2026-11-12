import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_browse_view_object.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_jump.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_revision_coordinator.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/shared/domain/catalog/pagination/library_pagination.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_series_filters_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_tab_page_size_providers.dart';
import 'package:hentai_library/shared/domain/catalog/pagination/catalog_pagination_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/series/public.dart';

part 'library_series_catalog_controller.g.dart';

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
      ref.watch(librarySeriesFiltersQueryProvider),
      ref.watch(librarySeriesTabSortOptionProvider),
      ref.watch(librarySeriesTabGroupingProvider),
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
        libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.series),
      );
    }
    final LibraryRevisionState revisionState = ref.read(
      libraryRevisionStateProvider,
    );

    final String keyword = ref.read(libraryQueryIntentProvider).keyword;
    final PagedResult<SeriesBrowseViewObject> page = await _fetchPage();
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

  Future<PagedResult<SeriesBrowseViewObject>> _fetchPage() {
    final LibrarySeriesFilter filter = ref.read(
      librarySeriesFiltersQueryProvider,
    );
    final LibrarySeriesSortOption sortOption = ref.read(
      librarySeriesTabSortOptionProvider,
    );
    final LibrarySeriesGrouping grouping = ref.read(
      librarySeriesTabGroupingProvider,
    );
    final int pageSize = ref.read(librarySeriesTabPageSizeProvider);
    return _pagination.fetchPage<SeriesBrowseViewObject>(
      pageSize: pageSize,
      fetch: (request) => ref
          .read(seriesRepoProvider)
          .fetchBrowsePage(
            request: request,
            filter: filter,
            grouping: grouping,
            sortOption: sortOption,
          ),
    );
  }

  void setPage(int page) {
    if (_pagination.setPage(page)) {
      ref.invalidateSelf();
    }
  }

  /// 以当前已加载的总页数为界；目录尚未加载时忽略。
  void jump(PageJump jump) {
    final int? totalPages = state.value?.pagination.totalPages;
    if (totalPages != null && _pagination.jump(jump, totalPages)) {
      ref.invalidateSelf();
    }
  }

  void refresh() {
    _pagination.refresh();
    ref.invalidateSelf();
  }
}
