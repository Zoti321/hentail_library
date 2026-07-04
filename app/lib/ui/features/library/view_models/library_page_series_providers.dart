import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_pagination_providers.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/comic_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/series_aggregate_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_query.dart';
import 'package:hentai_library/ui/features/library/view_models/library_view_settings_providers.dart';

const LibraryComicProjection _libraryComicProjection = LibraryComicProjection();

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
  LibraryViewSettings viewSettings,
  LibraryQueryIntent intent,
) {
  final LibrarySeriesQueryResult result = LibrarySeriesQuery(
    showR18: _libraryComicProjection.showR18(
      isHealthyMode: viewSettings.isHealthyMode,
    ),
    query: intent.keyword,
    sortOption: intent.sortOption,
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
  final LibraryViewSettings viewSettings = ref.watch(
    libraryViewSettingsProvider,
  );
  ref.watch(
    comicAggregateProvider.select(
      (ComicAggregateState s) => s.changeGeneration,
    ),
  );
  final AsyncValue<List<Comic>> comicsAsync = ref.watch(
    librarySeriesComicsByIdSourceProvider,
  );
  final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
  final Map<String, Comic> comicsById = _comicsByIdFromAsync(comicsAsync);
  return seriesAsync.when(
    data: (List<Series> list) =>
        _seriesViewDataFrom(list, comicsById, viewSettings, intent),
    loading: () {
      final List<Series>? previous = seriesAsync.value;
      if (previous == null) {
        return const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        );
      }
      return _seriesViewDataFrom(previous, comicsById, viewSettings, intent);
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
      return _seriesViewDataFrom(previous, comicsById, viewSettings, intent);
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
