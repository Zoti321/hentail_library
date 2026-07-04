import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_view_model_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_pagination_providers.g.dart';

const LibraryComicProjection _libraryComicProjection = LibraryComicProjection();
const LibrarySeriesProjection _librarySeriesProjection =
    LibrarySeriesProjection();

class LibraryComicsPagination {
  const LibraryComicsPagination({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.isLoading,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final bool isLoading;
}

/// 筛选/排序/intent 变化时用于重置页码的查询键。
@Riverpod(keepAlive: true)
Object libraryComicsPageQueryKey(Ref ref) {
  final String keyword = ref.watch(libraryFilterQueryProvider);
  final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
    libraryComicsTabAgeRestrictionFilterProvider,
  );
  final LibraryComicSortOption sortOption = ref.watch(
    libraryComicsTabSortOptionProvider,
  );
  return (keyword, ageRestriction, sortOption);
}

@Riverpod(keepAlive: true)
class LibraryComicsPageIndex extends _$LibraryComicsPageIndex {
  @override
  int build() {
    ref.listen<String>(libraryFilterQueryProvider, (
      String? previous,
      String next,
    ) {
      if (previous != null && previous != next) {
        state = 1;
      }
    });
    ref.listen<LibraryAgeRestrictionFilter>(
      libraryComicsTabAgeRestrictionFilterProvider,
      (
        LibraryAgeRestrictionFilter? previous,
        LibraryAgeRestrictionFilter next,
      ) {
        if (previous != null && previous != next) {
          state = 1;
        }
      },
    );
    ref.listen<LibraryComicSortOption>(libraryComicsTabSortOptionProvider, (
      LibraryComicSortOption? previous,
      LibraryComicSortOption next,
    ) {
      if (previous != null && previous != next) {
        state = 1;
      }
    });
    return 1;
  }

  void setPage(int page) {
    if (page < 1) {
      return;
    }
    state = page;
  }

  void goToFirstPage() {
    state = 1;
  }

  void goToLastPage(int totalPages) {
    if (totalPages <= 0) {
      return;
    }
    state = totalPages;
  }

  void goToPreviousPage() {
    if (state > 1) {
      state = state - 1;
    }
  }

  void goToNextPage(int totalPages) {
    if (totalPages > 0 && state < totalPages) {
      state = state + 1;
    }
  }

  void resetToFirstPage() {
    state = 1;
  }
}

@Riverpod(keepAlive: true)
class LibraryComicsPage extends _$LibraryComicsPage {
  @override
  Future<PagedResult<Comic>> build() async {
    ref.watch(
      comicAggregateProvider.select(
        (ComicAggregateState s) => s.changeGeneration,
      ),
    );
    final ComicAggregateState aggregateState = ref.watch(
      comicAggregateProvider,
    );
    if (aggregateState.streamError != null) {
      throw aggregateState.streamError!;
    }
    final String keyword = ref.watch(libraryFilterQueryProvider);
    final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
      libraryComicsTabAgeRestrictionFilterProvider,
    );
    final LibraryComicSortOption sortOption = ref.watch(
      libraryComicsTabSortOptionProvider,
    );
    final LibraryComicFilter filter = _libraryComicProjection.buildListFilter(
      ageRestriction: ageRestriction,
      keyword: keyword,
    );
    final int page = ref.watch(libraryComicsPageIndexProvider);
    final PagedResult<Comic> result = await ref
        .read(comicRepoProvider)
        .fetchComicsPage(
          request: PageRequest(page: page),
          filter: filter,
          sortOption: sortOption,
        );
    if (result.page != page) {
      ref.read(libraryComicsPageIndexProvider.notifier).setPage(result.page);
    }
    return result;
  }
}

@Riverpod(keepAlive: true)
Future<int> libraryComicTableTotalCount(Ref ref) async {
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  return ref.read(comicRepoProvider).countAll();
}

/// 系列筛选/intent 变化时用于重置页码的查询键。
@Riverpod(keepAlive: true)
Object librarySeriesPageQueryKey(Ref ref) {
  final String keyword = ref.watch(libraryFilterQueryProvider);
  final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
    librarySeriesTabAgeRestrictionFilterProvider,
  );
  final LibraryComicSortOption sortOption = ref.watch(
    librarySeriesTabSortOptionProvider,
  );
  return (keyword, ageRestriction, sortOption);
}

@Riverpod(keepAlive: true)
class LibrarySeriesPageIndex extends _$LibrarySeriesPageIndex {
  @override
  int build() {
    ref.listen<String>(libraryFilterQueryProvider, (
      String? previous,
      String next,
    ) {
      if (previous != null && previous != next) {
        state = 1;
      }
    });
    ref.listen<LibraryAgeRestrictionFilter>(
      librarySeriesTabAgeRestrictionFilterProvider,
      (
        LibraryAgeRestrictionFilter? previous,
        LibraryAgeRestrictionFilter next,
      ) {
        if (previous != null && previous != next) {
          state = 1;
        }
      },
    );
    ref.listen<LibraryComicSortOption>(librarySeriesTabSortOptionProvider, (
      LibraryComicSortOption? previous,
      LibraryComicSortOption next,
    ) {
      if (previous != null && previous != next) {
        state = 1;
      }
    });
    return 1;
  }

  void setPage(int page) {
    if (page < 1) {
      return;
    }
    state = page;
  }

  void goToFirstPage() {
    state = 1;
  }

  void goToLastPage(int totalPages) {
    if (totalPages <= 0) {
      return;
    }
    state = totalPages;
  }

  void goToPreviousPage() {
    if (state > 1) {
      state = state - 1;
    }
  }

  void goToNextPage(int totalPages) {
    if (totalPages > 0 && state < totalPages) {
      state = state + 1;
    }
  }

  void resetToFirstPage() {
    state = 1;
  }
}

@Riverpod(keepAlive: true)
class LibrarySeriesPage extends _$LibrarySeriesPage {
  @override
  Future<PagedResult<Series>> build() async {
    ref.watch(seriesAggregateProvider);
    final String keyword = ref.watch(libraryFilterQueryProvider);
    final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
      librarySeriesTabAgeRestrictionFilterProvider,
    );
    final LibraryComicSortOption sortOption = ref.watch(
      librarySeriesTabSortOptionProvider,
    );
    final LibrarySeriesFilter filter = _librarySeriesProjection.buildListFilter(
      ageRestriction: ageRestriction,
      keyword: keyword,
    );
    final int page = ref.watch(librarySeriesPageIndexProvider);
    final PagedResult<Series> result = await ref
        .read(librarySeriesRepoProvider)
        .fetchPage(
          request: PageRequest(page: page),
          filter: filter,
          sortOption: sortOption,
        );
    if (result.page != page) {
      ref.read(librarySeriesPageIndexProvider.notifier).setPage(result.page);
    }
    return result;
  }
}
