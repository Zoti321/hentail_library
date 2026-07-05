import 'package:hentai_library/domain/reading/read_session.dart';

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
  });
  final List<ReaderComicListItem> items;
  final int currentIndex;
  final int? preferredPageIndex;

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext =>
      currentIndex >= 0 && currentIndex < items.length - 1;

  ReaderComicListItem? get previousItem =>
      hasPrevious ? items[currentIndex - 1] : null;

  ReaderComicListItem? get nextItem =>
      hasNext ? items[currentIndex + 1] : null;
}

class ReaderRouteContext {
  const ReaderRouteContext({
    required this.comicId,
    this.seriesId,
    this.incognito = false,
  });

  final String comicId;
  final String? seriesId;
  final bool incognito;

  ReadSessionRouteParams get session => ReadSessionRouteParams(
    comicId: comicId,
    seriesId: seriesId,
    incognito: incognito,
  );

  bool get isSeriesRead => session.isSeriesRead;

  static ReaderRouteContext normalize({
    required String comicId,
    String? seriesId,
    bool incognito = false,
  }) {
    final String? resolvedSeriesId = seriesId?.trim();
    return ReaderRouteContext(
      comicId: comicId.trim(),
      seriesId: resolvedSeriesId == null || resolvedSeriesId.isEmpty
          ? null
          : resolvedSeriesId,
      incognito: incognito,
    );
  }
}

ReaderNavContextData buildReaderNavContextData({
  required List<ReaderComicListItem> items,
  required String currentComicId,
  required int? preferredPageIndex,
}) {
  final List<ReaderComicListItem> sortedItems =
      List<ReaderComicListItem>.from(items)
        ..sort(
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
  );
}
