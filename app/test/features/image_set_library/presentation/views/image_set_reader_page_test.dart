import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_reader_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/presentation/providers/reader_dependencies.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_page.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:hentai_library/shared/ui/navigation/app_root_navigator_key.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/pump_localized_app.dart';

const List<ImageSetImage> _pages = <ImageSetImage>[
  ImageSetImage(
    imageSetImageId: 'i1',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/1.png',
    memberPath: '',
    carrierKind: 'loose',
    name: '1.png',
  ),
  ImageSetImage(
    imageSetImageId: 'i2',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/pack.zip',
    memberPath: '2.png',
    carrierKind: 'zip',
    name: '2.png',
  ),
  ImageSetImage(
    imageSetImageId: 'i3',
    imageSetId: 'a',
    libraryId: 'img-1',
    carrierRelativePath: 'alpha/3.png',
    memberPath: '',
    carrierKind: 'loose',
    name: '3.png',
  ),
];

const List<int> _png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, //
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00, //
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];

class _FakeImageSetReadPort implements ImageSetReadPort {
  @override
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) async {
    final List<ImageSetReadPage> pages = <ImageSetReadPage>[
      for (int i = 0; i < _pages.length; i++)
        ImageSetReadPage(
          imageSetImageId: _pages[i].imageSetImageId,
          imageSetId: _pages[i].imageSetId,
          libraryId: _pages[i].libraryId,
          carrierRelativePath: _pages[i].carrierRelativePath,
          memberPath: _pages[i].memberPath,
          carrierKind: _pages[i].carrierKind,
          name: _pages[i].name,
          index: i,
        ),
    ];
    final int clamped = startIndex.clamp(0, pages.length - 1);
    return ImageSetOpenedReadSession(
      libraryId: libraryId,
      imageSetId: imageSetId,
      title: pages[clamped].name,
      pages: pages,
      startIndex: clamped,
    );
  }

  @override
  Future<Uint8List> loadPageBytes(ImageSetReadPage page) async =>
      Uint8List.fromList(_png);
}

class _StubComicLookup implements ComicReadQuery {
  @override
  Future<ComicReadSnapshot?> findById(String comicId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubPageSource implements ComicPageSourcePort {
  @override
  Future<List<ReadSessionPage>> loadPages(ReaderComicRef comic) async =>
      const <ReadSessionPage>[];

  @override
  Future<Uint8List?> loadPageBytes({
    required String comicId,
    required int pageIndex,
  }) async => null;

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required String comicId,
    required int pageIndex,
  }) async => ReaderPageBytes(Uint8List(0));

  @override
  Future<void> prefetchPages({
    required String comicId,
    required List<int> pageIndexes,
    required int generation,
  }) async {}

  @override
  Future<void> clearPageCache({required String comicId}) async {}
}

class _StubNative implements NativeReaderPort {
  @override
  Future<void> openComic(ReaderComicRef comic) async {}

  @override
  Future<void> closeComic(String comicId) async {}

  @override
  Future<void> clear() async {}
}

class _Probe {
  int progressWrites = 0;
  int entryOpens = 0;
}

List<Override> _overrides(_Probe probe) {
  final _FakeImageSetReadPort imageSetPort = _FakeImageSetReadPort();
  return <Override>[
    libraryRevisionStateProvider.overrideWithValue(
      const LibraryRevisionState(),
    ),
    imageSetImagesQueryProvider.overrideWithValue(
      (String libraryId, String imageSetId) async => _pages,
    ),
    imageSetPageBytesQueryProvider.overrideWithValue(
      (String libraryId, ImageSetImage image) async => Uint8List.fromList(_png),
    ),
    imageSetReaderEntryCommandProvider.overrideWithValue((
      ImageSetReaderEntry entry,
    ) {
      probe.entryOpens++;
      pushImageSetReaderPage(appRootNavigatorKey.currentState, entry);
    }),
    imageSetReadPortProvider.overrideWithValue(imageSetPort),
    comicReadQueryProvider.overrideWithValue(_StubComicLookup()),
    comicPageSourcePortProvider.overrideWithValue(_StubPageSource()),
    nativeReaderPortProvider.overrideWithValue(_StubNative()),
    readResumePageQueryProvider.overrideWithValue((_) async => null),
    recordReadingProgressCommandProvider.overrideWithValue(({
      required String comicId,
      required String title,
      required DateTime lastReadTime,
      required int pageIndex,
    }) async {
      probe.progressWrites++;
    }),
    recordReadSessionActivityCommandProvider.overrideWithValue(({
      required String comicId,
      required bool incognito,
      required Duration foregroundElapsed,
      required int pageIndex,
      required int pageCount,
    }) async {}),
    openReadSessionServiceProvider.overrideWithValue(
      OpenReadSessionService(
        comicLookup: _StubComicLookup(),
        pageSource: _StubPageSource(),
        readResumePage: (_) async => null,
        sessionPort: _StubNative(),
        imageSetReadPort: imageSetPort,
      ),
    ),
  ];
}

/// Reader may keep a loading indicator spinning — avoid unbounded settle.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 24}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  const ImageSetReaderEntry entry = ImageSetReaderEntry(
    libraryId: 'img-1',
    imageSetId: 'a',
    imageSetImageId: 'i2',
    index: 1,
  );

  testWidgets('opens ReaderPage at catalog index without writing progress', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    final _Probe probe = _Probe();
    await pumpLocalizedApp(
      tester,
      overrides: _overrides(probe),
      home: const ImageSetReaderPage(entry: entry),
    );
    await _pumpFrames(tester);

    expect(find.byType(ReaderPage), findsOneWidget);
    expect(find.text('2.png'), findsWidgets);
    expect(probe.progressWrites, 0);

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).last));
    await _pumpFrames(tester);
    expect(find.text('系列目录'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'entry push opens ReaderPage and Flutter pop returns to host',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 800));
      final _Probe probe = _Probe();
      final config = localizedTestAppConfig();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(probe),
          child: MaterialApp(
            navigatorKey: appRootNavigatorKey,
            locale: config.locale,
            localizationsDelegates: config.delegates,
            supportedLocales: config.locales,
            theme: buildAppTheme(Brightness.light),
            home: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () =>
                        pushImageSetReaderPage(Navigator.of(context), entry),
                    child: const Text('open-reader'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.text('open-reader'));
      await _pumpFrames(tester);

      expect(find.byType(ReaderPage), findsOneWidget);
      expect(find.text('2.png'), findsWidgets);
      expect(probe.progressWrites, 0);

      // Reveal chrome and exit via Reader back (force pop past PopScope).
      await tester.tapAt(tester.getCenter(find.byType(Scaffold).last));
      await _pumpFrames(tester);
      await tester.tap(find.bySemanticsLabel('返回上一页'));
      await _pumpFrames(tester);

      expect(find.byType(ReaderPage), findsNothing);
      expect(find.text('open-reader'), findsOneWidget);
      expect(probe.progressWrites, 0);
      await tester.binding.setSurfaceSize(null);
    },
  );
}
