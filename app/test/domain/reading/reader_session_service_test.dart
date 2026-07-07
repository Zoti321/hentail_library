import 'dart:typed_data';

import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/reading/read_session_exceptions.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/domain/reading/reader_session_service.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';
import 'package:test/test.dart';

class _FakeComicRepository implements ComicRepository {
  _FakeComicRepository({this.comic});

  final Comic? comic;

  @override
  Future<Comic?> findById(String comicId) async => comic;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReadingHistoryRepository implements ReadingHistoryRepository {
  _FakeReadingHistoryRepository({this.pageIndex});

  final int? pageIndex;

  @override
  Future<ReadingHistory?> getByComicId(String comicId) async {
    if (pageIndex == null) {
      return null;
    }
    return ReadingHistory(
      comicId: comicId,
      title: 'Test',
      lastReadTime: DateTime.utc(2026, 1, 1),
      pageIndex: pageIndex,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeComicPageSourcePort implements ComicPageSourcePort {
  _FakeComicPageSourcePort({
    required this.pages,
    this.error,
    this.readerPagePayload,
    List<List<int>>? prefetchedPageIndexes,
    List<String>? clearedComicIds,
  }) : prefetchedPageIndexes = prefetchedPageIndexes ?? <List<int>>[],
       clearedComicIds = clearedComicIds ?? <String>[];

  final List<ReadSessionPage> pages;
  final Object? error;
  final ReaderPagePayload? readerPagePayload;
  final List<List<int>> prefetchedPageIndexes;
  final List<String> clearedComicIds;

  @override
  Future<List<ReadSessionPage>> loadPages(Comic comic) async {
    if (error != null) {
      throw error!;
    }
    return pages;
  }

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async {
    return null;
  }

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required Comic comic,
    required int pageIndex,
  }) async {
    if (error != null) {
      throw error!;
    }
    return readerPagePayload ?? ReaderPageFilePath('/tmp/page-$pageIndex');
  }

  @override
  Future<void> prefetchPages({
    required Comic comic,
    required List<int> pageIndexes,
    required int generation,
  }) async {
    prefetchedPageIndexes.add(List<int>.from(pageIndexes));
  }

  @override
  void clearPageCache({required String comicId}) {
    clearedComicIds.add(comicId);
  }
}

class _FakeReaderSessionPort implements ReaderSessionPort {
  final List<String> openedComicIds = <String>[];
  final List<String> closedComicIds = <String>[];

  @override
  Future<void> openComic(Comic comic) async {
    openedComicIds.add(comic.comicId);
  }

  @override
  Future<void> closeComic(String comicId) async {
    closedComicIds.add(comicId);
  }

  @override
  Future<void> clear() async {}
}

Comic _inputComic() {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: 'c1',
    path: '/tmp/comic',
    resourceType: ResourceType.zip,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: 'Test',
    pageCount: 3,
  );
}

ReaderSessionService _service({
  Comic? comic,
  List<ReadSessionPage>? pages,
  Object? loadError,
  int? storedPageIndex,
  _FakeComicPageSourcePort? pageSource,
}) {
  return ReaderSessionService(
    comicRepo: _FakeComicRepository(comic: comic ?? _inputComic()),
    pageSource:
        pageSource ??
        _FakeComicPageSourcePort(
          pages: pages ?? <ReadSessionPage>[],
          error: loadError,
        ),
    readingHistoryRepo: _FakeReadingHistoryRepository(
      pageIndex: storedPageIndex,
    ),
    sessionPort: _FakeReaderSessionPort(),
  );
}

void main() {
  group('ReaderSessionService', () {
    test('open throws when comic is missing', () async {
      final ReaderSessionService service = _service(comic: null);
      expect(
        () => service.open(comicId: 'missing'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open throws when page list is empty', () async {
      final ReaderSessionService service = _service(pages: <ReadSessionPage>[]);
      expect(
        () => service.open(comicId: 'c1'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open returns snapshot with clamped resume index', () async {
      final _FakeReaderSessionPort sessionPort = _FakeReaderSessionPort();
      final ReaderSessionService service = ReaderSessionService(
        comicRepo: _FakeComicRepository(comic: _inputComic()),
        pageSource: _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 1),
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 2),
          ],
        ),
        readingHistoryRepo: _FakeReadingHistoryRepository(pageIndex: 99),
        sessionPort: sessionPort,
      );

      final ReaderSessionSnapshot snapshot = await service.open(comicId: 'c1');

      expect(snapshot.totalPages, 3);
      expect(snapshot.resumePageIndex, 3);
      expect(sessionPort.openedComicIds, <String>['c1']);
    });

    test('open uses page 1 when incognito', () async {
      final ReaderSessionService service = _service(
        pages: <ReadSessionPage>[
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
        ],
        storedPageIndex: 2,
      );

      final ReaderSessionSnapshot snapshot = await service.open(
        comicId: 'c1',
        incognito: true,
      );

      expect(snapshot.resumePageIndex, 1);
    });

    test('wraps port failures as ReadSessionPageLoadException', () async {
      final ReaderSessionService service = _service(
        loadError: StateError('io failed'),
      );
      expect(
        () => service.open(comicId: 'c1'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('close delegates to session port', () async {
      final _FakeReaderSessionPort sessionPort = _FakeReaderSessionPort();
      final ReaderSessionService service = ReaderSessionService(
        comicRepo: _FakeComicRepository(comic: _inputComic()),
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
        readingHistoryRepo: _FakeReadingHistoryRepository(),
        sessionPort: sessionPort,
      );

      await service.close('c1');

      expect(sessionPort.closedComicIds, <String>['c1']);
    });

    test('loadReaderPage delegates to page source with archive index', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
        readerPagePayload: ReaderPageBytes(Uint8List.fromList(<int>[1, 2, 3])),
      );
      final ReaderSessionService service = _service(pageSource: pageSource);

      final ReaderPagePayload payload = await service.loadReaderPage(
        comicId: 'c1',
        archivePageIndex: 2,
      );

      expect(payload, isA<ReaderPageBytes>());
    });

    test('loadReaderPage throws when comic is missing', () async {
      final ReaderSessionService service = ReaderSessionService(
        comicRepo: _FakeComicRepository(comic: null),
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
        readingHistoryRepo: _FakeReadingHistoryRepository(),
        sessionPort: _FakeReaderSessionPort(),
      );

      expect(
        () => service.loadReaderPage(comicId: 'missing', archivePageIndex: 0),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('prefetchPages skips dir comics', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
      );
      final ReaderSessionService service = ReaderSessionService(
        comicRepo: _FakeComicRepository(
          comic: _inputComic().copyWith(resourceType: ResourceType.dir),
        ),
        pageSource: pageSource,
        readingHistoryRepo: _FakeReadingHistoryRepository(),
        sessionPort: _FakeReaderSessionPort(),
      );

      await service.prefetchPages(
        comicId: 'c1',
        archivePageIndexes: <int>[0, 1],
        generation: 1,
      );

      expect(pageSource.prefetchedPageIndexes, isEmpty);
    });

    test('prefetchPages delegates archive indexes to page source', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
      );
      final ReaderSessionService service = _service(pageSource: pageSource);

      await service.prefetchPages(
        comicId: 'c1',
        archivePageIndexes: <int>[0, 2],
        generation: 3,
      );

      expect(pageSource.prefetchedPageIndexes, <List<int>>[<int>[0, 2]]);
    });

    test('clearPageCache delegates to page source', () {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
      );
      final ReaderSessionService service = _service(pageSource: pageSource);

      service.clearPageCache(comicId: 'c1');

      expect(pageSource.clearedComicIds, <String>['c1']);
    });

    group('page index convention', () {
      test('uiToArchivePageIndex converts 1-based to 0-based', () {
        expect(ReaderSessionService.uiToArchivePageIndex(1), 0);
        expect(ReaderSessionService.uiToArchivePageIndex(5), 4);
      });

      test('clampOneBasedResumeIndex clamps to total pages', () {
        expect(
          ReaderSessionService.clampOneBasedResumeIndex(
            storedPageIndex: 99,
            totalPages: 3,
          ),
          3,
        );
        expect(
          ReaderSessionService.clampOneBasedResumeIndex(
            storedPageIndex: null,
            totalPages: 3,
          ),
          1,
        );
      });
    });
  });
}
