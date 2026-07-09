import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
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

part 'library_comics_catalog_controller.g.dart';

const LibraryComicProjection _libraryComicProjection = LibraryComicProjection();

@Riverpod(keepAlive: true)
class LibraryComicsCatalogController extends _$LibraryComicsCatalogController {
  final CatalogPaginationEngine _pagination = CatalogPaginationEngine();

  int get pageIndex => _pagination.pageIndex;

  @override
  Future<LibraryComicsCatalogState> build() async {
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
      ref.watch(libraryComicsTabAgeRestrictionFilterProvider),
      ref.watch(libraryComicsTabMediaTypeFilterProvider),
      ref.watch(libraryComicsTabSortOptionProvider),
      ref.watch(libraryComicsTabPageSizeProvider),
    ));
  }

  Future<LibraryComicsCatalogState> _load() async {
    ref.watch(
      libraryRevisionProvider.select(
        (LibraryRevisionState state) => state.revision,
      ),
    );

    final LibraryRevisionState revisionState = ref.read(
      libraryRevisionProvider,
    );
    if (revisionState.streamError != null) {
      throw revisionState.streamError!;
    }

    final String keyword = ref.read(libraryQueryIntentProvider).keyword;
    final PagedResult<Comic> page = await _fetchPage(keyword);
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

  Future<PagedResult<Comic>> _fetchPage(String keyword) async {
    final LibraryAgeRestrictionFilter ageRestriction = ref.read(
      libraryComicsTabAgeRestrictionFilterProvider,
    );
    final LibraryMediaTypeFilterSelection mediaTypeFilter = ref.read(
      libraryComicsTabMediaTypeFilterProvider,
    );
    final LibraryComicSortOption sortOption = ref.read(
      libraryComicsTabSortOptionProvider,
    );
    final LibraryComicFilter filter = _libraryComicProjection.buildListFilter(
      ageRestriction: ageRestriction,
      mediaTypeFilter: mediaTypeFilter,
      keyword: keyword,
    );
    final int pageSize = ref.read(libraryComicsTabPageSizeProvider);
    return _pagination.fetchPage<Comic>(
      pageSize: pageSize,
      fetch: (request) => ref
          .read(comicRepoProvider)
          .fetchComicsPage(
            request: request,
            filter: filter,
            sortOption: sortOption,
          ),
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
