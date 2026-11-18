import 'dart:async';
import 'dart:typed_data';

import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/application/manage_read_session_use_case.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_capabilities.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:test/test.dart';

class _NoComicLookup implements ComicReadQuery {
  @override
  Future<ComicReadSnapshot?> findById(String comicId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedPageSource implements ComicPageSourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedNative implements NativeReaderPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeImageSetPort implements ImageSetReadPort {
  int openCount = 0;
  int? requestedStartIndex;
  Completer<void>? pendingOpen;

  @override
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) async {
    openCount += 1;
    requestedStartIndex = startIndex;
    await pendingOpen?.future;
    return ImageSetOpenedReadSession(
      libraryId: libraryId,
      imageSetId: imageSetId,
      title: 'p1.png',
      startIndex: startIndex,
      pages: <ImageSetReadPage>[
        ImageSetReadPage(
          imageSetImageId: 'i1',
          imageSetId: imageSetId,
          libraryId: libraryId,
          carrierRelativePath: 'a/1.png',
          memberPath: '',
          carrierKind: 'loose',
          name: 'p1.png',
          index: 0,
        ),
        ImageSetReadPage(
          imageSetImageId: 'i2',
          imageSetId: imageSetId,
          libraryId: libraryId,
          carrierRelativePath: 'a/2.png',
          memberPath: '',
          carrierKind: 'loose',
          name: 'p2.png',
          index: 1,
        ),
      ],
    );
  }

  @override
  Future<Uint8List> loadPageBytes(ImageSetReadPage page) async =>
      Uint8List.fromList(<int>[1, 2, 3]);
}

void main() {
  OpenReadSessionUseCase serviceFor(_FakeImageSetPort port) =>
      OpenReadSessionUseCase(
        comicLookup: _NoComicLookup(),
        pageSource: _UnusedPageSource(),
        readResumePage: (_) async => null,
        sessionPort: _UnusedNative(),
        imageSetReadPort: port,
      );

  test('selected image identity overrides an obsolete catalog index', () async {
    final port = _FakeImageSetPort();
    final service = serviceFor(port);
    final opened = await service.openFromSource(
      const ImageSetReadSessionSource(
        libraryId: 'lib',
        imageSetId: 'set',
        startIndex: 99,
        imageSetImageId: 'i2',
      ),
    );

    expect(opened.resumePageIndex, 2);
    expect(port.requestedStartIndex, 0);
  });

  test(
    'selection resolves separately against the shared page snapshot',
    () async {
      final port = _FakeImageSetPort();
      final service = serviceFor(port);
      final first = await service.openFromSource(
        const ImageSetReadSessionSource(
          libraryId: 'lib',
          imageSetId: 'set',
          startIndex: 1,
          imageSetImageId: 'i1',
        ),
      );
      final second = await service.openFromSource(
        const ImageSetReadSessionSource(
          libraryId: 'lib',
          imageSetId: 'set',
          startIndex: 0,
          imageSetImageId: 'i2',
        ),
      );

      expect(first.resumePageIndex, 1);
      expect(second.resumePageIndex, 2);
      expect(port.openCount, 1);
    },
  );

  test(
    'missing selected image fails instead of opening another page',
    () async {
      final port = _FakeImageSetPort();
      final service = serviceFor(port);
      await expectLater(
        service.openFromSource(
          const ImageSetReadSessionSource(
            libraryId: 'lib',
            imageSetId: 'set',
            startIndex: 0,
            imageSetImageId: 'removed',
          ),
        ),
        throwsA(
          isA<ReadSessionPageLoadException>().having(
            (error) => error.kind,
            'kind',
            ReadSessionFailureKind.resourceNotFound,
          ),
        ),
      );
      expect(port.openCount, 1);
    },
  );

  test(
    'concurrent callers share preparation but retain selected identities',
    () async {
      final pending = Completer<void>();
      final port = _FakeImageSetPort()..pendingOpen = pending;
      final service = serviceFor(port);
      final first = service.openFromSource(
        const ImageSetReadSessionSource(
          libraryId: 'lib',
          imageSetId: 'set',
          startIndex: 99,
          imageSetImageId: 'i1',
        ),
      );
      final second = service.openFromSource(
        const ImageSetReadSessionSource(
          libraryId: 'lib',
          imageSetId: 'set',
          startIndex: 99,
          imageSetImageId: 'i2',
        ),
      );
      pending.complete();
      final opened = await Future.wait(<Future<OpenedReadSession>>[
        first,
        second,
      ]);

      expect(opened.map((session) => session.resumePageIndex), <int>[1, 2]);
      expect(port.openCount, 1);
    },
  );

  test('openFromSource maps image set pages and start index', () async {
    final _FakeImageSetPort port = _FakeImageSetPort();
    final OpenReadSessionUseCase service = OpenReadSessionUseCase(
      comicLookup: _NoComicLookup(),
      pageSource: _UnusedPageSource(),
      readResumePage: (_) async => null,
      sessionPort: _UnusedNative(),
      imageSetReadPort: port,
    );

    final OpenedReadSession opened = await service.openFromSource(
      const ImageSetReadSessionSource(
        libraryId: 'lib',
        imageSetId: 'set',
        startIndex: 1,
      ),
    );

    expect(port.openCount, 1);
    expect(opened.resumePageIndex, 2);
    expect(opened.pages, hasLength(2));
    expect(opened.pages.first, isA<ReadSessionImageSetPage>());
    expect(opened.comic, isNull);
    expect(opened.subject.sessionKey, 'image_set:lib:set');
    expect(opened.capabilities.persistProgress, isFalse);

    final ReaderPagePayload payload = await service.loadReaderPage(
      sessionKey: opened.sessionKey,
      archivePageIndex: 1,
    );
    expect(payload, isA<ReaderPageBytes>());
  });

  test(
    'beginReadSession skips progress for Image set capabilities',
    () async {
      int writes = 0;
      final OpenReadSessionUseCase sessions = OpenReadSessionUseCase(
        comicLookup: _NoComicLookup(),
        pageSource: _UnusedPageSource(),
        readResumePage: (_) async => null,
        sessionPort: _UnusedNative(),
        imageSetReadPort: _FakeImageSetPort(),
      );
      final ManageReadSessionUseCase app = ManageReadSessionUseCase(
        openReadSession: sessions,
        recordProgress:
            ({
              required String comicId,
              required String title,
              required DateTime lastReadTime,
              required int pageIndex,
            }) async {
              writes += 1;
            },
        recordActivity: ({
          required String comicId,
          required bool incognito,
          required Duration foregroundElapsed,
          required int pageIndex,
          required int pageCount,
        }) async {},
      );

      await app.beginReadSession(
        capabilities: ReadSessionCapabilities.from(
          const ImageSetReadSessionSource(
            libraryId: 'lib',
            imageSetId: 'set',
            startIndex: 0,
          ),
        ),
      );
      expect(writes, 0);
      expect(app.hasActiveSession, isFalse);
    },
  );
}
