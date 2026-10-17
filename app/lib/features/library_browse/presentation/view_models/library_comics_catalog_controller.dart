import 'package:hentai_library/features/library_browse/domain/library_comic_filter.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_jump.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/catalog_pagination_engine.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/library.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_comics_catalog_controller.g.dart';

@Riverpod(keepAlive: true)
class LibraryComicsCatalogController extends _$LibraryComicsCatalogController {
  final CatalogPaginationEngine _pagination = CatalogPaginationEngine();

  int get pageIndex => _pagination.pageIndex;

  @override
  Future<LibraryComicsCatalogState> build() async {
    _syncPaginationWithQueryKey();
    return _load();
  }

  /// 分页查询键 =（关键词，整份筛选意图，每页数量）；任一变化即回到第 1 页。
  void _syncPaginationWithQueryKey() {
    final String keyword = ref.watch(libraryFilterQueryProvider);
    final LibraryComicFiltersState filters =
        ref.watch(libraryComicFiltersProvider).value ??
        LibraryComicFiltersState.defaults;
    final int pageSize = ref.watch(libraryComicsTabPageSizeProvider);
    _pagination.syncQueryKey((keyword, filters, pageSize));
  }

  Future<LibraryComicsCatalogState> _load() async {
    // Comics sort has no `random` field (unlike Series); always watch revision.
    // If random comics sort is added later, exempt revision like Series (P2-8).
    ref.watch(libraryCatalogWatchRevisionProvider(LibraryDisplayTarget.comics));

    final LibraryRevisionState revisionState = ref.read(
      libraryRevisionStateProvider,
    );
    if (revisionState.streamError != null) {
      throw revisionState.streamError!;
    }

    final String keyword = ref.read(libraryQueryIntentProvider).keyword;
    final PagedResult<Comic> page = await _fetchPage();
    final int tableTotalCount = await ref.read(comicRepoProvider).countAll();

    return LibraryComicsCatalogState(
      items: page.items,
      pagination: LibraryPagination(
        page: page.page,
        totalPages: page.totalPages,
        totalCount: page.totalCount,
        isLoading: false,
      ),
      filterQuery: keyword,
      hasReceivedFirstEmit: revisionState.hasReceivedFirstEmit,
      isComicTableEmpty:
          revisionState.hasReceivedFirstEmit && tableTotalCount == 0,
    );
  }

  Future<PagedResult<Comic>> _fetchPage() async {
    final LibraryComicFilter filter = ref.read(libraryComicFilterQueryProvider);
    final LibraryComicFiltersState filters =
        ref.read(libraryComicFiltersProvider).value ??
        LibraryComicFiltersState.defaults;
    final int pageSize = ref.read(libraryComicsTabPageSizeProvider);
    return _pagination.fetchPage<Comic>(
      pageSize: pageSize,
      fetch: (request) => ref
          .read(comicRepoProvider)
          .fetchComicsPage(
            request: request,
            filter: filter,
            expandBySeries: filters.expandBySeries,
            sortOption: filters.sortOption,
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
