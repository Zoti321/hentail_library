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
}

class ReaderRouteContext {
  const ReaderRouteContext({
    required this.comicId,
    this.incognito = false,
  });

  final String comicId;
  final bool incognito;

  static ReaderRouteContext normalize({
    required String comicId,
    bool incognito = false,
  }) {
    return ReaderRouteContext(
      comicId: comicId.trim(),
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
