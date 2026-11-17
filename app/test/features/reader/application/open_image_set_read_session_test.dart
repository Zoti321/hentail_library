import 'dart:typed_data';

import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/features/reader/application/read_session_application_service.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
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

  @override
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) async {
    openCount += 1;
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
  test('openFromSource maps image set pages and start index', () async {
    final _FakeImageSetPort port = _FakeImageSetPort();
    final OpenReadSessionService service = OpenReadSessionService(
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
    expect(opened.comic.comicId, 'image_set:lib:set');
    expect(opened.comic.resourceType, ResourceType.dir);

    final ReaderPagePayload payload = await service.loadReaderPage(
      comicId: opened.comic.comicId,
      archivePageIndex: 1,
    );
    expect(payload, isA<ReaderPageBytes>());
  });

  test('beginReadSession skips progress when persistProgress is false', () async {
    int writes = 0;
    final OpenReadSessionService sessions = OpenReadSessionService(
      comicLookup: _NoComicLookup(),
      pageSource: _UnusedPageSource(),
      readResumePage: (_) async => null,
      sessionPort: _UnusedNative(),
      imageSetReadPort: _FakeImageSetPort(),
    );
    final ReadSessionApplicationService app = ReadSessionApplicationService(
      sessionService: sessions,
      recordProgress:
          ({
            required String comicId,
            required String title,
            required DateTime lastReadTime,
            required int pageIndex,
          }) async {
            writes += 1;
          },
      recordActivity:
          ({
            required String comicId,
            required bool incognito,
            required Duration foregroundElapsed,
            required int pageIndex,
            required int pageCount,
          }) async {},
    );

    await app.beginReadSession(
      comic: const ReaderComicRef(
        comicId: 'image_set:lib:set',
        path: 'image_set:lib:set',
        resourceType: ResourceType.dir,
        pageCount: 2,
        title: 'p1.png',
      ),
      persistProgress: false,
    );
    expect(writes, 0);
    expect(app.hasActiveSession, isFalse);
  });
}
