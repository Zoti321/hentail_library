import 'package:hentai_library/domain/entity/reading_history.dart' as entity;
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';
import 'package:hentai_library/domain/entity/series_reading_history.dart'
    as series_entity;
import 'package:hentai_library/presentation/providers/pages/series_management/series_management_notifier.dart';
import 'package:hentai_library/presentation/ui_dto/history_grid_item_dto.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_page_notifier.g.dart';

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
  final List<entity.ReadingHistory> comics = ref
      .watch(readingHistoryStreamProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <entity.ReadingHistory>[]);
  final List<series_entity.SeriesReadingHistory> seriesHistory = ref
      .watch(seriesReadingHistoryStreamProvider)
      .maybeWhen(
        data: (data) => data,
        orElse: () => const <series_entity.SeriesReadingHistory>[],
      );
  final List<Series> allSeries = ref
      .watch(allSeriesProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <Series>[]);
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

Map<String, int> _buildSeriesOrderMap(List<Series> allSeries) {
  final Map<String, int> map = <String, int>{};
  for (final Series series in allSeries) {
    for (final SeriesItem item in series.items) {
      map['${series.name}|${item.comicId}'] = item.order;
    }
  }
  return map;
}
