import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/entity/comic/series_item.dart';

class ReaderComicListItem {
  const ReaderComicListItem({
    required this.comicId,
    required this.title,
    required this.order,
  });
  final String comicId;
  final String title;
  final int order;
}

class ReaderNavContextData {
  const ReaderNavContextData({
    required this.items,
    required this.currentIndex,
    required this.preferredPageIndex,
    this.seriesName,
  });
  final List<ReaderComicListItem> items;
  final int currentIndex;
  final int? preferredPageIndex;
  final String? seriesName;
  bool get hasMultipleItems => items.length > 1;
}

class SeriesReaderNavData {
  const SeriesReaderNavData({
    required this.seriesName,
    required this.sortedItems,
    required this.currentIndex,
  });
  final String seriesName;
  final List<SeriesItem> sortedItems;
  final int currentIndex;
}

enum ReaderReadType { comic, series }

class ReaderRouteContext {
  const ReaderRouteContext({
    required this.comicId,
    required this.readType,
    this.seriesName,
  });

  final String comicId;
  final ReaderReadType readType;
  final String? seriesName;

  bool get isSeriesMode => readType == ReaderReadType.series;

  static ReaderRouteContext normalize({
    required String comicId,
    required String readType,
    String? seriesName,
  }) {
    final ReaderReadType parsedType = readType == 'series'
        ? ReaderReadType.series
        : ReaderReadType.comic;
    final String normalizedComicId = comicId.trim();
    final String? normalizedSeriesName =
        seriesName != null && seriesName.isNotEmpty ? seriesName : null;
    final bool isValidSeries =
        parsedType == ReaderReadType.series && normalizedSeriesName != null;
    return ReaderRouteContext(
      comicId: normalizedComicId,
      readType: isValidSeries ? ReaderReadType.series : ReaderReadType.comic,
      seriesName: isValidSeries ? normalizedSeriesName : null,
    );
  }
}

SeriesReaderNavData? buildSeriesReaderNavData(Series? series, String comicId) {
  if (series == null || !series.containsComic(comicId)) {
    return null;
  }
  final List<SeriesItem> sorted = List<SeriesItem>.from(series.items)
    ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
  final int idx = sorted.indexWhere((SeriesItem e) => e.comicId == comicId);
  if (idx < 0) {
    return null;
  }
  return SeriesReaderNavData(
    seriesName: series.name,
    sortedItems: sorted,
    currentIndex: idx,
  );
}

ReaderNavContextData buildReaderNavContextData({
  required List<ReaderComicListItem> items,
  required String currentComicId,
  required int? preferredPageIndex,
  String? seriesName,
}) {
  final List<ReaderComicListItem> sortedItems =
      List<ReaderComicListItem>.from(items)..sort(
        (ReaderComicListItem a, ReaderComicListItem b) =>
            a.order.compareTo(b.order),
      );
  final int currentIndex = sortedItems.indexWhere(
    (ReaderComicListItem item) => item.comicId == currentComicId,
  );
  return ReaderNavContextData(
    items: sortedItems,
    currentIndex: currentIndex,
    preferredPageIndex: preferredPageIndex,
    seriesName: seriesName,
  );
}
