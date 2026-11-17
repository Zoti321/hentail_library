import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';

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
    required this.source,
    this.incognito = false,
    this.startFromFirstPage = false,
  });

  final ReadSessionSource source;
  final bool incognito;
  final bool startFromFirstPage;

  String get comicId => source.sessionKey;

  bool get persistProgress => source.isComic;

  bool get isImageSet => source.isImageSet;

  /// Comic go_router / OpenReaderArgs bridge（Image set 不走此路径）。
  OpenReaderArgs get session {
    final ReadSessionSource current = source;
    if (current is! ComicReadSessionSource) {
      throw StateError('OpenReaderArgs is comic-only');
    }
    return OpenReaderArgs(
      comicId: current.comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
  }

  static ReaderRouteContext normalize({
    required String comicId,
    bool incognito = false,
    bool startFromFirstPage = false,
  }) {
    return ReaderRouteContext(
      source: ComicReadSessionSource(comicId.trim()),
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
  }

  static ReaderRouteContext imageSet({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) {
    return ReaderRouteContext(
      source: ImageSetReadSessionSource(
        libraryId: libraryId,
        imageSetId: imageSetId,
        startIndex: startIndex,
      ),
      startFromFirstPage: true,
    );
  }
}

ReaderNavContextData buildReaderNavContextData({
  required List<ReaderComicListItem> items,
  required String currentComicId,
  required int? preferredPageIndex,
}) {
  final List<ReaderComicListItem> sortedItems =
      List<ReaderComicListItem>.of(items)..sort(
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
