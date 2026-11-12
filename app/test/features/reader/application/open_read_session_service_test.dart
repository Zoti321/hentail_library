import 'package:hentai_library/composition/modules/comic/comic_read_query.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/features/comic/public/comic.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/comic/public/comic_lookup_repository.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:test/test.dart';

class _FakeComicRepository implements ComicLookupRepository {
  _FakeComicRepository({this.comic});

  final Comic? comic;

  @override
  Future<Comic?> findById(String comicId) async => comic;

  @override
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeReadingHistoryCommands {
  _FakeReadingHistoryCommands({this.pageIndex});

  final int? pageIndex;

  Future<int?> readResumePageIndex(String comicId) async => pageIndex;

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
       clearedComicIds = clearedComicIds ?? <String>[],
       loadPagesCallCount = 0;

  final List<ReadSessionPage> pages;
  final Object? error;
  final ReaderPagePayload? readerPagePayload;
  final List<List<int>> prefetchedPageIndexes;
  final List<String> clearedComicIds;
  int loadPagesCallCount;

  @override
  Future<List<ReadSessionPage>> loadPages(ReaderComicRef comic) async {
    loadPagesCallCount += 1;
    if (error != null) {
      throw error!;
    }
    return pages;
  }

  @override
  Future<Uint8List?> loadPageBytes({
    required String comicId,
    required int pageIndex,
  }) async {
    return null;
  }

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required String comicId,
    required int pageIndex,
  }) async {
    if (error != null) {
      throw error!;
    }
    return readerPagePayload ?? ReaderPageFilePath('/tmp/page-$pageIndex');
  }

  @override
  Future<void> prefetchPages({
    required String comicId,
    required List<int> pageIndexes,
    required int generation,
  }) async {
    prefetchedPageIndexes.add(List<int>.from(pageIndexes));
  }

  @override
  Future<void> clearPageCache({required String comicId}) async {
    clearedComicIds.add(comicId);
  }
}

class _FakeNativeReaderPort implements NativeReaderPort {
  _FakeNativeReaderPort({this.openHang});

  final Future<void>? openHang;
  final List<String> openedComicIds = <String>[];
  final List<String> closedComicIds = <String>[];

  @override
  Future<void> openComic(ReaderComicRef comic) async {
    openedComicIds.add(comic.comicId);
    final Future<void>? hang = openHang;
    if (hang != null) {
      await hang;
    }
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
  return Comic.restore(
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

OpenReadSessionService _service({
  Comic? comic,
  List<ReadSessionPage>? pages,
  Object? loadError,
  int? storedPageIndex,
  _FakeComicPageSourcePort? pageSource,
}) {
  return OpenReadSessionService(
    comicLookup: createComicReadQuery(
      _FakeComicRepository(comic: comic ?? _inputComic()),
    ),
    pageSource:
        pageSource ??
        _FakeComicPageSourcePort(
          pages: pages ?? <ReadSessionPage>[],
          error: loadError,
        ),
    readResumePage: _FakeReadingHistoryCommands(pageIndex: storedPageIndex)
        .readResumePageIndex,
    sessionPort: _FakeNativeReaderPort(),
  );
}

void main() {
  group('OpenReadSessionService', () {
    test('open throws when comic is missing', () async {
      final OpenReadSessionService service = _service(comic: null);
      expect(
        () => service.open(comicId: 'missing'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open throws when page list is empty', () async {
      final OpenReadSessionService service = _service(
        pages: <ReadSessionPage>[],
      );
      expect(
        () => service.open(comicId: 'c1'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open returns snapshot with clamped resume index', () async {
      final _FakeNativeReaderPort sessionPort = _FakeNativeReaderPort();
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 1),
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 2),
          ],
        ),
        readResumePage: _FakeReadingHistoryCommands(pageIndex: 99)
            .readResumePageIndex,
        sessionPort: sessionPort,
      );

      final OpenedReadSession snapshot = await service.open(comicId: 'c1');

      expect(snapshot.totalPages, 3);
      expect(snapshot.resumePageIndex, 3);
      expect(sessionPort.openedComicIds, <String>['c1']);
    });

    test('open uses page 1 when incognito', () async {
      final OpenReadSessionService service = _service(
        pages: <ReadSessionPage>[
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
        ],
        storedPageIndex: 2,
      );

      final OpenedReadSession snapshot = await service.open(
        comicId: 'c1',
        incognito: true,
      );

      expect(snapshot.resumePageIndex, 1);
    });

    test('open uses page 1 when startFromFirstPage', () async {
      final OpenReadSessionService service = _service(
        pages: <ReadSessionPage>[
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 1),
        ],
        storedPageIndex: 2,
      );

      final OpenedReadSession snapshot = await service.open(
        comicId: 'c1',
        startFromFirstPage: true,
      );

      expect(snapshot.resumePageIndex, 1);
    });

    test('wraps port failures as ReadSessionPageLoadException', () async {
      final OpenReadSessionService service = _service(
        loadError: StateError('io failed'),
      );
      expect(
        () => service.open(comicId: 'c1'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open times out when Resource access hang never completes', () async {
      final _FakeNativeReaderPort sessionPort = _FakeNativeReaderPort(
        openHang: Completer<void>().future,
      );
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
          ],
        ),
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: sessionPort,
        openTimeout: const Duration(milliseconds: 40),
      );

      await expectLater(
        service.open(comicId: 'c1'),
        throwsA(
          isA<ReadSessionPageLoadException>().having(
            (ReadSessionPageLoadException e) => e.kind,
            'kind',
            ReadSessionFailureKind.timedOut,
          ),
        ),
      );
      expect(sessionPort.closedComicIds, <String>['c1']);
    });

    test('open classifies empty pages as invalidOrEmptyContent', () async {
      final OpenReadSessionService service = _service(
        pages: <ReadSessionPage>[],
      );
      await expectLater(
        service.open(comicId: 'c1'),
        throwsA(
          isA<ReadSessionPageLoadException>().having(
            (ReadSessionPageLoadException e) => e.kind,
            'kind',
            ReadSessionFailureKind.invalidOrEmptyContent,
          ),
        ),
      );
    });

    test('open classifies missing comic as resourceNotFound', () async {
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(_FakeComicRepository(comic: null)),
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: _FakeNativeReaderPort(),
      );
      await expectLater(
        service.open(comicId: 'missing'),
        throwsA(
          isA<ReadSessionPageLoadException>().having(
            (ReadSessionPageLoadException e) => e.kind,
            'kind',
            ReadSessionFailureKind.resourceNotFound,
          ),
        ),
      );
    });

    test('close delegates to session port', () async {
      final _FakeNativeReaderPort sessionPort = _FakeNativeReaderPort();
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: sessionPort,
      );

      await service.close('c1');

      expect(sessionPort.closedComicIds, <String>['c1']);
    });

    test('open then loadPages lists pages only once', () async {
      final _FakeNativeReaderPort sessionPort = _FakeNativeReaderPort();
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 1),
        ],
      );
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: pageSource,
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: sessionPort,
      );

      final OpenedReadSession snapshot = await service.open(comicId: 'c1');
      final List<ReadSessionPage> pages = await service.loadPages('c1');

      expect(snapshot.pages, pages);
      expect(pageSource.loadPagesCallCount, 1);
      expect(sessionPort.openedComicIds, <String>['c1']);
    });

    test('close clears page-list cache so next open lists again', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
        ],
      );
      final OpenReadSessionService service = _service(pageSource: pageSource);

      await service.open(comicId: 'c1');
      await service.close('c1');
      await service.open(comicId: 'c1');

      expect(pageSource.loadPagesCallCount, 2);
    });

    test(
      'loadReaderPage delegates to page source with archive index',
      () async {
        final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[],
          readerPagePayload: ReaderPageBytes(
            Uint8List.fromList(<int>[1, 2, 3]),
          ),
        );
        final OpenReadSessionService service = _service(pageSource: pageSource);

        final ReaderPagePayload payload = await service.loadReaderPage(
          comicId: 'c1',
          archivePageIndex: 2,
        );

        expect(payload, isA<ReaderPageBytes>());
      },
    );

    test('loadReaderPage throws when comic is missing', () async {
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(_FakeComicRepository(comic: null)),
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: _FakeNativeReaderPort(),
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
      final OpenReadSessionService service = OpenReadSessionService(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(
            comic: _inputComic().copyWith(resourceType: ResourceType.dir),
          ),
        ),
        pageSource: pageSource,
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: _FakeNativeReaderPort(),
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
      final OpenReadSessionService service = _service(pageSource: pageSource);

      await service.prefetchPages(
        comicId: 'c1',
        archivePageIndexes: <int>[0, 2],
        generation: 3,
      );

      expect(pageSource.prefetchedPageIndexes, <List<int>>[
        <int>[0, 2],
      ]);
    });

    test('clearPageCache delegates to page source', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
      );
      final OpenReadSessionService service = _service(pageSource: pageSource);

      await service.clearPageCache(comicId: 'c1');

      expect(pageSource.clearedComicIds, <String>['c1']);
    });

    group('page index convention', () {
      test('uiToArchivePageIndex converts 1-based to 0-based', () {
        expect(OpenReadSessionService.uiToArchivePageIndex(1), 0);
        expect(OpenReadSessionService.uiToArchivePageIndex(5), 4);
      });

      test('clampOneBasedResumeIndex clamps to total pages', () {
        expect(
          OpenReadSessionService.clampOneBasedResumeIndex(
            storedPageIndex: 99,
            totalPages: 3,
          ),
          3,
        );
        expect(
          OpenReadSessionService.clampOneBasedResumeIndex(
            storedPageIndex: null,
            totalPages: 3,
          ),
          1,
        );
      });
    });
  });
}
