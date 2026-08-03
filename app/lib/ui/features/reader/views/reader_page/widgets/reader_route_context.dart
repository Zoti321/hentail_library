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

  bool get hasNext => currentIndex >= 0 && currentIndex < items.length - 1;

  ReaderComicListItem? get previousItem =>
      hasPrevious ? items[currentIndex - 1] : null;

  ReaderComicListItem? get nextItem => hasNext ? items[currentIndex + 1] : null;
}

class ReaderRouteContext {
  const ReaderRouteContext({
    required this.comicId,
    this.incognito = false,
    this.startFromFirstPage = false,
  });

  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;

  ReadSessionRouteParams get session => ReadSessionRouteParams(
    comicId: comicId,
    incognito: incognito,
    startFromFirstPage: startFromFirstPage,
  );

  static ReaderRouteContext normalize({
    required String comicId,
    bool incognito = false,
    bool startFromFirstPage = false,
  }) {
    return ReaderRouteContext(
      comicId: comicId.trim(),
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
  }
}

ReaderNavContextData buildReaderNavContextData({
  required List<ReaderComicListItem> items,
  required String currentComicId,
  required int? preferredPageIndex,
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
  );
}
