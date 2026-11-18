import 'dart:typed_data';

import 'package:hentai_library/features/reader/application/manage_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_navigation.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
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

class _CatalogPort implements ImageSetReadPort {
  final List<String> listedLibraries = <String>[];

  @override
  Future<List<ImageSetNavItem>> listNavigableImageSets({
    required String libraryId,
  }) async {
    listedLibraries.add(libraryId);
    return const <ImageSetNavItem>[
      ImageSetNavItem(imageSetId: 's1', title: 'One'),
      ImageSetNavItem(imageSetId: 's2', title: 'Two'),
      ImageSetNavItem(imageSetId: 's3', title: 'Three'),
    ];
  }

  @override
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) async => ImageSetOpenedReadSession(
    libraryId: libraryId,
    imageSetId: imageSetId,
    title: imageSetId,
    startIndex: startIndex,
    pages: <ImageSetReadPage>[
      ImageSetReadPage(
        imageSetImageId: '$imageSetId-1',
        imageSetId: imageSetId,
        libraryId: libraryId,
        carrierRelativePath: '$imageSetId/1.png',
        memberPath: '',
        carrierKind: 'loose',
        name: '1.png',
        index: 0,
      ),
    ],
  );

  @override
  Future<Uint8List> loadPageBytes(ImageSetReadPage page) async => Uint8List(0);
}

const ImageSetReadSessionSource _current = ImageSetReadSessionSource(
  libraryId: 'lib',
  imageSetId: 's2',
  startIndex: 3,
);

void main() {
  late _CatalogPort port;
  late OpenReadSessionUseCase sessions;
  late ManageReadSessionUseCase app;
  late int progressWrites;
  late int activityWrites;

  setUp(() {
    port = _CatalogPort();
    progressWrites = 0;
    activityWrites = 0;
    sessions = OpenReadSessionUseCase(
      comicLookup: _NoComicLookup(),
      pageSource: _UnusedPageSource(),
      readResumePage: (_) async => null,
      sessionPort: _UnusedNative(),
      imageSetReadPort: port,
    );
    app = ManageReadSessionUseCase(
      openReadSession: sessions,
      recordProgress:
          ({
            required String comicId,
            required String title,
            required DateTime lastReadTime,
            required int pageIndex,
          }) async {
            progressWrites += 1;
          },
      recordActivity:
          ({
            required String comicId,
            required bool incognito,
            required Duration foregroundElapsed,
            required int pageIndex,
            required int pageCount,
          }) async {
            activityWrites += 1;
          },
    );
  });

  test('navigation lists the current library in catalog order', () async {
    final ImageSetNavigation nav = await sessions.loadImageSetNavigation(
      _current,
    );

    expect(port.listedLibraries, <String>['lib']);
    expect(nav.previous?.imageSetId, 's1');
    expect(nav.next?.imageSetId, 's3');
  });

  test(
    'switch closes the current session and opens a fresh source at page one',
    () async {
      await sessions.openFromSource(_current);
      expect(sessions.openedSource(_current.sessionKey), isNotNull);

      final ImageSetSwitchPlan plan = await app.prepareImageSetSwitch(
        currentSession: _current,
        targetImageSetId: 's3',
      );

      expect(plan.closeSessionKey, _current.sessionKey);
      expect(
        plan.nextSource,
        const ImageSetReadSessionSource(
          libraryId: 'lib',
          imageSetId: 's3',
          startIndex: 0,
        ),
      );
      expect(sessions.openedSource(_current.sessionKey), isNull);
      final opened = await sessions.openFromSource(plan.nextSource);
      expect(opened.capabilities.persistProgress, isFalse);
      expect(opened.capabilities.imageSetNavigation, isTrue);
      expect(opened.resumePageIndex, 1);
      expect(progressWrites, 0);
      expect(activityWrites, 0);
    },
  );

  test('switch by id rejects a set missing from the catalog', () async {
    await sessions.openFromSource(_current);

    await expectLater(
      app.prepareImageSetSwitch(
        currentSession: _current,
        targetImageSetId: 'removed',
      ),
      throwsA(
        isA<ReadSessionPageLoadException>().having(
          (error) => error.kind,
          'kind',
          ReadSessionFailureKind.resourceNotFound,
        ),
      ),
    );
    expect(sessions.openedSource(_current.sessionKey), isNotNull);
  });

  test('switch to the current set is rejected', () async {
    await expectLater(
      app.prepareImageSetSwitch(
        currentSession: _current,
        targetImageSetId: 's2',
      ),
      throwsArgumentError,
    );
  });
}
