import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart'
    as series_entity;
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/presentation/providers/aggregates/comic_aggregate_notifier.dart';
import 'package:hentai_library/presentation/providers/aggregates/series_aggregate_notifier.dart';
import 'package:hentai_library/presentation/dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_page_notifier.g.dart';

const int _kHistoryContinueReadingVisibleCount = 10;

class HistoryFeedViewData {
  const HistoryFeedViewData({
    required this.isLoading,
    required this.hasError,
    required this.totalCount,
    required this.mergedItems,
    required this.continueReadingItems,
  });
  final bool isLoading;
  final bool hasError;
  final int totalCount;
  final List<HistoryGridItemDto> mergedItems;
  final List<HistoryGridItemDto> continueReadingItems;
}

@Riverpod(keepAlive: true)
Stream<List<entity.ReadingHistory>> readingHistoryStream(Ref ref) {
  return ref.watch(readingHistoryRepoProvider).watchAllHistory();
}

@Riverpod(keepAlive: true)
Stream<List<series_entity.SeriesReadingHistory>> seriesReadingHistoryStream(
  Ref ref,
) {
  return ref.watch(readingHistoryRepoProvider).watchAllSeriesReading();
}

@Riverpod(keepAlive: true)
List<HistoryGridItemDto> mergedHistoryGridItems(Ref ref) {
  final bool isHealthy =
      (ref.watch(settingsProvider).value?.isHealthyMode) ?? false;
  final ComicAggregateState aggregate = ref.watch(comicAggregateProvider);
  if (isHealthy && !aggregate.hasReceivedFirstEmit) {
    return const <HistoryGridItemDto>[];
  }
  final Map<String, Comic> comicsById = <String, Comic>{
    for (final Comic c in aggregate.rawList) c.comicId: c,
  };
  List<entity.ReadingHistory> comics = ref
      .watch(readingHistoryStreamProvider)
      .maybeWhen(
        data: (data) => data,
        orElse: () => const <entity.ReadingHistory>[],
      );
  List<series_entity.SeriesReadingHistory> seriesHistory = ref
      .watch(seriesReadingHistoryStreamProvider)
      .maybeWhen(
        data: (data) => data,
        orElse: () => const <series_entity.SeriesReadingHistory>[],
      );
  final List<Series> allSeries = ref
      .watch(allSeriesProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <Series>[]);
  if (isHealthy) {
    comics = comics
        .where(
          (entity.ReadingHistory h) {
            return comicsById[h.comicId]?.contentRating !=
                ContentRating.r18;
          },
        )
        .toList(growable: false);
    seriesHistory = seriesHistory
        .where(
          (series_entity.SeriesReadingHistory h) {
            final Series? s = _findSeriesByName(allSeries, h.seriesName);
            if (s == null) {
              return true;
            }
            return !s.hasR18Comic(comicsById: comicsById);
          },
        )
        .toList(growable: false);
  }
  final Map<String, int> seriesOrderMap = _buildSeriesOrderMap(allSeries);
  final List<HistoryGridItemDto> merged = <HistoryGridItemDto>[
    ...comics.map(
      (entity.ReadingHistory history) => HistoryGridItemDto.comic(
        id: 'comic:${history.comicId}',
        title: history.title,
        lastReadTime: history.lastReadTime,
        coverComicId: history.comicId,
        comicId: history.comicId,
        pageIndex: history.pageIndex,
      ),
    ),
    ...seriesHistory.map(
      (series_entity.SeriesReadingHistory history) => HistoryGridItemDto.series(
        id: 'series:${history.seriesName}',
        title: history.seriesName,
        lastReadTime: history.lastReadTime,
        coverComicId: history.lastReadComicId,
        seriesName: history.seriesName,
        lastReadComicId: history.lastReadComicId,
        pageIndex: history.pageIndex,
        lastReadComicOrder:
            seriesOrderMap['${history.seriesName}|${history.lastReadComicId}'],
      ),
    ),
  ];
  merged.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
  return merged;
}

Series? _findSeriesByName(List<Series> allSeries, String name) {
  for (final Series s in allSeries) {
    if (s.name == name) {
      return s;
    }
  }
  return null;
}

@Riverpod(keepAlive: true)
HistoryFeedViewData historyFeedView(Ref ref) {
  final bool isHealthy =
      (ref.watch(settingsProvider).value?.isHealthyMode) ?? false;
  final AsyncValue<List<entity.ReadingHistory>> comicsAsync = ref.watch(
    readingHistoryStreamProvider,
  );
  final AsyncValue<List<series_entity.SeriesReadingHistory>> seriesAsync = ref
      .watch(seriesReadingHistoryStreamProvider);
  final AsyncValue<List<Series>> allSeriesAsync = ref.watch(allSeriesProvider);
  final ComicAggregateState aggregate = ref.watch(comicAggregateProvider);
  final bool isLoading =
      comicsAsync.isLoading ||
      seriesAsync.isLoading ||
      allSeriesAsync.isLoading ||
      (isHealthy && !aggregate.hasReceivedFirstEmit);
  final bool hasError =
      comicsAsync.hasError || seriesAsync.hasError || allSeriesAsync.hasError;
  final List<HistoryGridItemDto> visibleItems = ref.watch(
    historyVisibleGridItemsProvider,
  );
  final int totalCount = visibleItems.length;
  final List<HistoryGridItemDto> continueReadingItems = visibleItems
      .take(_kHistoryContinueReadingVisibleCount)
      .toList(growable: false);
  return HistoryFeedViewData(
    isLoading: isLoading,
    hasError: hasError,
    totalCount: totalCount,
    mergedItems: visibleItems,
    continueReadingItems: continueReadingItems,
  );
}

Map<String, int> _buildSeriesOrderMap(List<Series> allSeries) {
  final Map<String, int> map = <String, int>{};
  for (final Series series in allSeries) {
    for (final SeriesItem item in series.items) {
      map['${series.name}|${item.comicId}'] = item.order;
    }
  }
  return map;
}

/// Desktop history page search query. Auto-dispose clears when the page is left.
class HistorySearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final historySearchQueryProvider =
    NotifierProvider.autoDispose<HistorySearchQueryNotifier, String>(
      HistorySearchQueryNotifier.new,
    );

final Provider<List<HistoryGridItemDto>> historyVisibleGridItemsProvider =
    Provider<List<HistoryGridItemDto>>((Ref ref) {
  final List<HistoryGridItemDto> mergedItems = ref.watch(
    mergedHistoryGridItemsProvider,
  );
  final String query = ref.watch(historySearchQueryProvider);
  final String normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return mergedItems;
  }
  return mergedItems
      .where(
        (HistoryGridItemDto item) =>
            item.title.toLowerCase().contains(normalizedQuery),
      )
      .toList(growable: false);
});
