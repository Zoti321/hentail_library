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
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:test/test.dart';

class _FakeComicRepository implements ComicLookupRepository {
  _FakeComicRepository({this.comic});

  final Comic? comic;
  Future<Comic?>? pendingLookup;

  @override
  Future<Comic?> findById(String comicId) async =>
      pendingLookup == null ? comic : await pendingLookup!;

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

class _ControlledNativeReaderPort implements NativeReaderPort {
  final firstOpen = Completer<void>();
  final entered = Completer<void>();
  final events = <String>[];
  int opens = 0;
  int? active;
  Object? closeError;
  Completer<void>? firstClose;
  final closeEntered = Completer<void>();
  int closes = 0;

  @override
  Future<void> openComic(ReaderComicRef comic) async {
    final run = ++opens;
    events.add('open:$run');
    if (run == 1) {
      entered.complete();
      await firstOpen.future;
    }
    active = run;
  }

  @override
  Future<void> closeComic(String comicId) async {
    events.add('close');
    if (++closes == 1 && firstClose != null) {
      closeEntered.complete();
      await firstClose!.future;
    }
    active = null;
    if (closeError != null) throw closeError!;
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

OpenReadSessionUseCase _service({
  Comic? comic,
  List<ReadSessionPage>? pages,
  Object? loadError,
  int? storedPageIndex,
  _FakeComicPageSourcePort? pageSource,
}) {
  return OpenReadSessionUseCase(
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
  group('OpenReadSessionUseCase', () {
    test(
      'a hanging native timeout cleanup does not delay the timeout result',
      () async {
        final native = _ControlledNativeReaderPort()
          ..firstClose = Completer<void>();
        final service = OpenReadSessionUseCase(
          comicLookup: createComicReadQuery(
            _FakeComicRepository(comic: _inputComic()),
          ),
          pageSource: _FakeComicPageSourcePort(
            pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
          ),
          readResumePage: (_) async => 1,
          sessionPort: native,
          openTimeout: const Duration(milliseconds: 40),
        );
        try {
          await expectLater(
            service
                .open(comicId: 'c1')
                .timeout(const Duration(milliseconds: 250)),
            throwsA(
              isA<ReadSessionPageLoadException>().having(
                (e) => e.kind,
                'kind',
                ReadSessionFailureKind.timedOut,
              ),
            ),
          );
          expect(native.firstClose!.isCompleted, isFalse);
        } finally {
          native.firstClose!.complete();
          native.firstOpen.complete();
        }
        await service.open(comicId: 'c1');
        expect(native.active, 2);
      },
    );

    test('cached loadPages cannot return a lifetime closed before its continuation', () async {
      final service = _service(
        pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
      );
      await service.open(comicId: 'c1');
      final pages = service.loadPagesByComicId('c1');
      final checked = expectLater(
        pages,
        throwsA(isA<ReadSessionPageLoadException>()),
      );
      await service.close('c1');
      await checked;
    });

    test(
      'delayed timeout cleanup finishes before reopening native resources',
      () async {
        final native = _ControlledNativeReaderPort()
          ..firstClose = Completer<void>();
        final service = OpenReadSessionUseCase(
          comicLookup: createComicReadQuery(
            _FakeComicRepository(comic: _inputComic()),
          ),
          pageSource: _FakeComicPageSourcePort(
            pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
          ),
          readResumePage: (_) async => 1,
          sessionPort: native,
          openTimeout: const Duration(milliseconds: 40),
        );
        final old = service.open(comicId: 'c1');
        final checked = expectLater(
          old,
          throwsA(isA<ReadSessionPageLoadException>()),
        );
        await native.closeEntered.future;
        native.firstOpen.complete();
        await Future<void>.delayed(Duration.zero);
        await service.close('c1');
        final next = service.open(comicId: 'c1');
        await Future<void>.delayed(Duration.zero);
        try {
          expect(native.opens, 1);
        } finally {
          native.firstClose!.complete();
        }
        await checked;
        await next;
        expect(native.active, 2);
      },
    );

    test('a closed lookup cannot block a later open or clean up its native session', () async {
      final pending = Completer<Comic?>();
      final repo = _FakeComicRepository(comic: _inputComic())
        ..pendingLookup = pending.future;
      final native = _ControlledNativeReaderPort()..firstOpen.complete();
      final service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(repo),
        pageSource: _FakeComicPageSourcePort(
          pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
        ),
        readResumePage: (_) async => 1,
        sessionPort: native,
      );
      final old = service.open(comicId: 'c1');
      final checked = expectLater(
        old,
        throwsA(isA<ReadSessionPageLoadException>()),
      );
      await Future<void>.delayed(Duration.zero);
      await service.close('c1');
      repo.pendingLookup = null;
      await service.open(comicId: 'c1');
      expect(native.active, 1);
      pending.complete(_inputComic());
      await checked;
      expect(native.active, 1);
      expect(native.events, ['close', 'open:1']);
    });

    test('concurrent open options and loadPages share only the native page-list operation', () async {
      final native = _ControlledNativeReaderPort();
      final pages = _FakeComicPageSourcePort(
        pages: [
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
          ReadSessionArchivePage(comicId: 'c1', pageIndex: 1),
        ],
      );
      final service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: pages,
        readResumePage: (_) async => 2,
        sessionPort: native,
      );
      final ordinary = service.open(comicId: 'c1');
      final incognito = service.open(comicId: 'c1', incognito: true);
      final listed = service.loadPagesByComicId('c1');
      await native.entered.future;
      native.firstOpen.complete();
      expect((await ordinary).resumePageIndex, 2);
      expect((await incognito).resumePageIndex, 1);
      expect(await listed, hasLength(2));
      expect(native.opens, 1);
      expect(pages.loadPagesCallCount, 1);
    });

    test(
      'a reopen waiting for uncancellable native work retains its own timeout',
      () async {
        final native = _ControlledNativeReaderPort();
        final service = OpenReadSessionUseCase(
          comicLookup: createComicReadQuery(
            _FakeComicRepository(comic: _inputComic()),
          ),
          pageSource: _FakeComicPageSourcePort(
            pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
          ),
          readResumePage: (_) async => 1,
          sessionPort: native,
          openTimeout: const Duration(milliseconds: 40),
        );
        final old = service.open(comicId: 'c1');
        final checked = expectLater(
          old,
          throwsA(isA<ReadSessionPageLoadException>()),
        );
        await native.entered.future;
        await service.close('c1');
        await expectLater(
          service.open(comicId: 'c1'),
          throwsA(
            isA<ReadSessionPageLoadException>().having(
              (e) => e.kind,
              'kind',
              ReadSessionFailureKind.timedOut,
            ),
          ),
        );
        expect(native.opens, 1);
        native.firstOpen.complete();
        await checked;
        await service.open(comicId: 'c1');
        expect(native.active, 2);
      },
    );

    test('close failure remains with its caller and late cleanup cannot replace it', () async {
      final error = StateError('native close');
      final native = _ControlledNativeReaderPort()..closeError = error;
      final service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: _FakeComicPageSourcePort(
          pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
        ),
        readResumePage: (_) async => 1,
        sessionPort: native,
      );
      final old = service.open(comicId: 'c1');
      final checked = expectLater(
        old,
        throwsA(isA<ReadSessionPageLoadException>()),
      );
      await native.entered.future;
      await expectLater(service.close('c1'), throwsA(same(error)));
      native.firstOpen.complete();
      await checked;
      native.closeError = null;
      await service.open(comicId: 'c1');
      expect(native.active, 2);
    });

    for (final reopenImmediately in [false, true]) {
      test(
        'close prevents a late native open from owning a reopened session: $reopenImmediately',
        () async {
          final native = _ControlledNativeReaderPort();
          final pages = _FakeComicPageSourcePort(
            pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
          );
          final service = OpenReadSessionUseCase(
            comicLookup: createComicReadQuery(
              _FakeComicRepository(comic: _inputComic()),
            ),
            pageSource: pages,
            readResumePage: (_) async => 1,
            sessionPort: native,
          );
          final old = service.open(comicId: 'c1');
          final oldChecked = expectLater(
            old,
            throwsA(isA<ReadSessionPageLoadException>()),
          );
          await native.entered.future;
          await service.close('c1');
          final next = reopenImmediately ? service.open(comicId: 'c1') : null;
          await Future<void>.delayed(Duration.zero);
          try {
            expect(native.opens, 1);
          } finally {
            native.firstOpen.complete();
          }
          await oldChecked;
          final reopened = await (next ?? service.open(comicId: 'c1'));
          expect(reopened.totalPages, 1);
          expect(native.active, 2);
          expect(native.events, ['open:1', 'close', 'close', 'open:2']);
          expect(pages.loadPagesCallCount, 1);
        },
      );
    }

    test(
      'timed out native open is closed when it eventually completes',
      () async {
        final native = _ControlledNativeReaderPort();
        final pages = _FakeComicPageSourcePort(
          pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
        );
        final service = OpenReadSessionUseCase(
          comicLookup: createComicReadQuery(
            _FakeComicRepository(comic: _inputComic()),
          ),
          pageSource: pages,
          readResumePage: (_) async => 1,
          sessionPort: native,
          openTimeout: const Duration(milliseconds: 40),
        );
        await expectLater(
          service.open(comicId: 'c1'),
          throwsA(
            isA<ReadSessionPageLoadException>().having(
              (e) => e.kind,
              'kind',
              ReadSessionFailureKind.timedOut,
            ),
          ),
        );
        native.firstOpen.complete();
        await Future<void>.delayed(Duration.zero);
        expect(native.active, isNull);
        expect(pages.loadPagesCallCount, 0);
        await service.open(comicId: 'c1');
        expect(native.active, 2);
      },
    );

    test(
      'close during resume lookup prevents an obsolete open result',
      () async {
        final resume = Completer<int?>();
        final entered = Completer<void>();
        final service = OpenReadSessionUseCase(
          comicLookup: createComicReadQuery(
            _FakeComicRepository(comic: _inputComic()),
          ),
          pageSource: _FakeComicPageSourcePort(
            pages: [ReadSessionArchivePage(comicId: 'c1', pageIndex: 0)],
          ),
          readResumePage: (_) {
            entered.complete();
            return resume.future;
          },
          sessionPort: _FakeNativeReaderPort(),
        );
        final old = service.open(comicId: 'c1');
        final checked = expectLater(
          old,
          throwsA(isA<ReadSessionPageLoadException>()),
        );
        await entered.future;
        await service.close('c1');
        resume.complete(1);
        await checked;
      },
    );

    test('resume lookup runs in parallel with native open', () async {
      final openHang = Completer<void>();
      final resumeEntered = Completer<void>();
      final resume = Completer<int?>();
      final service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: _FakeComicPageSourcePort(
          pages: <ReadSessionPage>[
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 0),
            ReadSessionArchivePage(comicId: 'c1', pageIndex: 1),
          ],
        ),
        readResumePage: (_) {
          resumeEntered.complete();
          return resume.future;
        },
        sessionPort: _FakeNativeReaderPort(openHang: openHang.future),
      );
      final Future<OpenedReadSession> opening = service.open(comicId: 'c1');
      await resumeEntered.future;
      expect(openHang.isCompleted, isFalse);
      openHang.complete();
      resume.complete(2);
      expect((await opening).resumePageIndex, 2);
    });

    test('open throws when comic is missing', () async {
      final OpenReadSessionUseCase service = _service(comic: null);
      expect(
        () => service.open(comicId: 'missing'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open throws when page list is empty', () async {
      final OpenReadSessionUseCase service = _service(
        pages: <ReadSessionPage>[],
      );
      expect(
        () => service.open(comicId: 'c1'),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('open returns snapshot with clamped resume index', () async {
      final _FakeNativeReaderPort sessionPort = _FakeNativeReaderPort();
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
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
      final OpenReadSessionUseCase service = _service(
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
      final OpenReadSessionUseCase service = _service(
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
      final OpenReadSessionUseCase service = _service(
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
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
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
      await Future<void>.delayed(Duration.zero);
      expect(sessionPort.closedComicIds, <String>['c1']);
    });

    test('open classifies empty pages as invalidOrEmptyContent', () async {
      final OpenReadSessionUseCase service = _service(
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
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
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
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
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
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(comic: _inputComic()),
        ),
        pageSource: pageSource,
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: sessionPort,
      );

      final OpenedReadSession snapshot = await service.open(comicId: 'c1');
      final List<ReadSessionPage> pages = await service.loadPagesByComicId('c1');

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
      final OpenReadSessionUseCase service = _service(pageSource: pageSource);

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
        final OpenReadSessionUseCase service = _service(pageSource: pageSource);

        final ReaderPagePayload payload = await service.loadReaderPage(
          sessionKey: 'c1',
          archivePageIndex: 2,
        );

        expect(payload, isA<ReaderPageBytes>());
      },
    );

    test('loadReaderPage throws when comic is missing', () async {
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(_FakeComicRepository(comic: null)),
        pageSource: _FakeComicPageSourcePort(pages: <ReadSessionPage>[]),
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: _FakeNativeReaderPort(),
      );

      expect(
        () => service.loadReaderPage(sessionKey: 'missing', archivePageIndex: 0),
        throwsA(isA<ReadSessionPageLoadException>()),
      );
    });

    test('prefetchPages skips dir comics', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
      );
      final OpenReadSessionUseCase service = OpenReadSessionUseCase(
        comicLookup: createComicReadQuery(
          _FakeComicRepository(
            comic: _inputComic().copyWith.resourceInfo(
              resourceType: ResourceType.dir,
            ),
          ),
        ),
        pageSource: pageSource,
        readResumePage: _FakeReadingHistoryCommands().readResumePageIndex,
        sessionPort: _FakeNativeReaderPort(),
      );

      await service.prefetchPages(
        sessionKey: 'c1',
        archivePageIndexes: <int>[0, 1],
        generation: 1,
      );

      expect(pageSource.prefetchedPageIndexes, isEmpty);
    });

    test('prefetchPages delegates archive indexes to page source', () async {
      final _FakeComicPageSourcePort pageSource = _FakeComicPageSourcePort(
        pages: <ReadSessionPage>[],
      );
      final OpenReadSessionUseCase service = _service(pageSource: pageSource);

      await service.prefetchPages(
        sessionKey: 'c1',
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
      final OpenReadSessionUseCase service = _service(pageSource: pageSource);

      await service.clearPageCache(sessionKey: 'c1');

      expect(pageSource.clearedComicIds, <String>['c1']);
    });

    group('page index convention', () {
      test('uiToArchivePageIndex converts 1-based to 0-based', () {
        expect(OpenReadSessionUseCase.uiToArchivePageIndex(1), 0);
        expect(OpenReadSessionUseCase.uiToArchivePageIndex(5), 4);
      });

      test('clampOneBasedResumeIndex clamps to total pages', () {
        expect(
          OpenReadSessionUseCase.clampOneBasedResumeIndex(
            storedPageIndex: 99,
            totalPages: 3,
          ),
          3,
        );
        expect(
          OpenReadSessionUseCase.clampOneBasedResumeIndex(
            storedPageIndex: null,
            totalPages: 3,
          ),
          1,
        );
      });
    });
  });
}
