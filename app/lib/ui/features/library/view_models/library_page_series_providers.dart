import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_query.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_view_model_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_tab_filter_sort_providers.dart';

Map<String, Comic> _comicsByIdFromAsync(AsyncValue<List<Comic>> comicsAsync) {
  return comicsAsync.when(
    data: (List<Comic> comics) => <String, Comic>{
      for (final Comic comic in comics) comic.comicId: comic,
    },
    loading: () {
      final List<Comic>? previous = comicsAsync.value;
      if (previous == null) {
        return <String, Comic>{};
      }
      return <String, Comic>{
        for (final Comic comic in previous) comic.comicId: comic,
      };
    },
    error: (Object _, StackTrace _) {
      final List<Comic>? previous = comicsAsync.value;
      if (previous == null) {
        return <String, Comic>{};
      }
      return <String, Comic>{
        for (final Comic comic in previous) comic.comicId: comic,
      };
    },
    skipLoadingOnReload: true,
  );
}

LibrarySeriesViewData _seriesViewDataFrom(
  List<Series> seriesList,
  Map<String, Comic> comicsById,
  LibraryAgeRestrictionFilter ageRestriction,
  String keyword,
  LibraryComicSortOption sortOption,
) {
  final LibrarySeriesQueryResult result = LibrarySeriesQuery(
    ageRestriction: ageRestriction,
    query: keyword,
    sortOption: sortOption,
    comicsById: comicsById,
  ).apply(seriesList);
  return LibrarySeriesViewData(
    headerTotalSeriesWithItemsCount: result.headerTotalSeriesWithItemsCount,
    seriesWithItemsCount: result.seriesWithItemsCount,
    filteredSeries: result.filteredSeries,
  );
}

/// Projection 层（系列）：负责生成系列区块渲染所需的只读视图数据。
@immutable
class LibrarySeriesViewData {
  const LibrarySeriesViewData({
    required this.headerTotalSeriesWithItemsCount,
    required this.seriesWithItemsCount,
    required this.filteredSeries,
  });
  final int headerTotalSeriesWithItemsCount;
  final int seriesWithItemsCount;
  final List<Series> filteredSeries;
}

/// 系列视图投影：统一组合设置、intent、漫画索引和系列源数据。
final Provider<LibrarySeriesViewData>
librarySeriesViewDataProvider = Provider<LibrarySeriesViewData>((Ref ref) {
  final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
  final LibraryAgeRestrictionFilter ageRestriction = ref.watch(
    librarySeriesTabAgeRestrictionFilterProvider,
  );
  final String keyword = ref.watch(libraryFilterQueryProvider);
  final LibraryComicSortOption sortOption = ref.watch(
    librarySeriesTabSortOptionProvider,
  );
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  final AsyncValue<List<Comic>> comicsAsync = ref.watch(
    librarySeriesComicsByIdSourceProvider,
  );
  final Map<String, Comic> comicsById = _comicsByIdFromAsync(comicsAsync);
  return seriesAsync.when(
    data: (List<Series> list) => _seriesViewDataFrom(
      list,
      comicsById,
      ageRestriction,
      keyword,
      sortOption,
    ),
    loading: () {
      final List<Series>? previous = seriesAsync.value;
      if (previous == null) {
        return const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        );
      }
      return _seriesViewDataFrom(
        previous,
        comicsById,
        ageRestriction,
        keyword,
        sortOption,
      );
    },
    error: (Object _, StackTrace _) {
      final List<Series>? previous = seriesAsync.value;
      if (previous == null) {
        return const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        );
      }
      return _seriesViewDataFrom(
        previous,
        comicsById,
        ageRestriction,
        keyword,
        sortOption,
      );
    },
    skipLoadingOnReload: true,
  );
});

final FutureProvider<List<Comic>> librarySeriesComicsByIdSourceProvider =
    FutureProvider<List<Comic>>((Ref ref) async {
      ref.watch(
        comicAggregateProvider.select(
          (ComicAggregateState s) => s.changeGeneration,
        ),
      );
      return ref.read(comicRepoProvider).getAll();
    });

/// 当前页系列条目（供库页网格消费）。
final Provider<AsyncValue<List<Series>>> libraryDisplayedSeriesProvider =
    Provider<AsyncValue<List<Series>>>((Ref ref) {
      final AsyncValue<PagedResult<Series>> pageAsync = ref.watch(
        librarySeriesPageProvider,
      );
      return pageAsync.when(
        data: (PagedResult<Series> page) => AsyncValue.data(page.items),
        loading: () => const AsyncValue.loading(),
        error: (Object error, StackTrace stackTrace) =>
            AsyncValue.error(error, stackTrace),
        skipLoadingOnReload: true,
      );
    });

final Provider<int> libraryDisplayedSeriesCountProvider = Provider<int>((
  Ref ref,
) {
  final AsyncValue<PagedResult<Series>> pageAsync = ref.watch(
    librarySeriesPageProvider,
  );
  return stablePagedTotalCount(pageAsync);
});
