import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
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

  String get sessionKey => source.sessionKey;

  /// Legacy alias for [sessionKey] (Comic id or Image set opaque key).
  String get comicId => sessionKey;

  ReadSessionCapabilities get capabilities =>
      ReadSessionCapabilities.from(source, incognito: incognito);

  bool get persistProgress => capabilities.persistProgress;

  /// Comic go_router / OpenReaderArgs bridge（仅 Comic / series 导航能力）。
  OpenReaderArgs? get sessionOrNull {
    final ReadSessionSource current = source;
    if (current is! ComicReadSessionSource) {
      return null;
    }
    return OpenReaderArgs(
      comicId: current.comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
  }

  /// Comic-only; throws when Series/Comic session args are unavailable.
  OpenReaderArgs get session {
    final OpenReaderArgs? args = sessionOrNull;
    if (args == null) {
      throw StateError('OpenReaderArgs is comic-only');
    }
    return args;
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
    String? imageSetImageId,
  }) {
    return ReaderRouteContext(
      source: ImageSetReadSessionSource(
        libraryId: libraryId,
        imageSetId: imageSetId,
        startIndex: startIndex,
        imageSetImageId: imageSetImageId,
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
