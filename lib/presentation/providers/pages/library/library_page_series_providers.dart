import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/models.dart' show AppSetting;
import 'package:hentai_library/presentation/providers/aggregates/comic_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_series_query.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';

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
final Provider<LibrarySeriesViewData> librarySeriesViewDataProvider =
    Provider<LibrarySeriesViewData>((Ref ref) {
      final AsyncValue<List<Series>> seriesAsync = ref.watch(allSeriesProvider);
      final bool showR18 = !ref.watch(
        settingsProvider.select(
          (AsyncValue<AppSetting> async) =>
              async.asData?.value.isHealthyMode ?? false,
        ),
      );
      final List<Comic> rawComics = ref.watch(
        comicAggregateProvider.select((ComicAggregateState s) => s.rawList),
      );
      final LibraryQueryIntent intent = ref.watch(libraryQueryIntentProvider);
      final Map<String, Comic> comicsById = <String, Comic>{};
      for (final Comic comic in rawComics) {
        comicsById[comic.comicId] = comic;
      }
      return seriesAsync.when(
        data: (List<Series> list) {
          final LibrarySeriesQueryResult result = LibrarySeriesQuery(
            showR18: showR18,
            query: '',
            sortOption: intent.sortOption,
            comicsById: comicsById,
          ).apply(list);
          return LibrarySeriesViewData(
            headerTotalSeriesWithItemsCount:
                result.headerTotalSeriesWithItemsCount,
            seriesWithItemsCount: result.seriesWithItemsCount,
            filteredSeries: result.filteredSeries,
          );
        },
        loading: () => const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        ),
        error: (Object _, StackTrace _) => const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        ),
        skipLoadingOnReload: true,
      );
    });

final Provider<int> libraryDisplayedSeriesCountProvider = Provider<int>((
  Ref ref,
) {
  final LibrarySeriesViewData viewData = ref.watch(
    librarySeriesViewDataProvider,
  );
  return viewData.filteredSeries.length;
});
