import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/reader/application/manage_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/open_read_session_use_case.dart';
import 'package:hentai_library/features/reader/application/read_session_page_load_exception.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/domain/image_set_navigation.dart';
import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/read_session_source.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/features/reader/domain/reader_page_payload.dart';
import 'package:hentai_library/features/reader/presentation/providers/reader_dependencies.dart';
import 'package:hentai_library/features/reader/presentation/providers/session_providers.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_providers.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_layout.dart';
import 'package:hentai_library/features/reader/presentation/views/reader/reader_page.dart';
import 'package:hentai_library/features/reader/presentation/widgets/reader_open_error_panel.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hentai_library/shared/application/contracts/comic_read_query.dart';
import 'package:hentai_library/shared/presentation/providers/comic_read_query_provider.dart';
import 'package:hentai_library/shared/ui/navigation/app_root_navigator_key.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../../support/pump_localized_app.dart';

const ImageSetReadSessionSource _source = ImageSetReadSessionSource(
  libraryId: 'img-1',
  imageSetId: 'a',
  startIndex: 0,
);

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

class _StubImageSetReadPort implements ImageSetReadPort {
  @override
  Future<ImageSetOpenedReadSession> openSession({
    required String libraryId,
    required String imageSetId,
    required int startIndex,
  }) async {
    throw StateError('unused');
  }

  @override
  Future<Uint8List> loadPageBytes(ImageSetReadPage page) async =>
      Uint8List(0);

  @override
  Future<List<ImageSetNavItem>> listNavigableImageSets({
    required String libraryId,
  }) async => const <ImageSetNavItem>[];
}

List<Override> _baseOverrides({
  required Future<OpenedReadSession> Function() open,
}) {
  final OpenReadSessionUseCase openUseCase = OpenReadSessionUseCase(
    comicLookup: _StubComicLookup(),
    pageSource: _StubPageSource(),
    readResumePage: (_) async => null,
    sessionPort: _StubNative(),
    imageSetReadPort: _StubImageSetReadPort(),
  );
  return <Override>[
    libraryRevisionStateProvider.overrideWithValue(
      const LibraryRevisionState(),
    ),
    imageSetReadPortProvider.overrideWithValue(_StubImageSetReadPort()),
    comicReadQueryProvider.overrideWithValue(_StubComicLookup()),
    comicPageSourcePortProvider.overrideWithValue(_StubPageSource()),
    nativeReaderPortProvider.overrideWithValue(_StubNative()),
    readResumePageQueryProvider.overrideWithValue((_) async => null),
    recordReadingProgressCommandProvider.overrideWithValue(({
      required String comicId,
      required String title,
      required DateTime lastReadTime,
      required int pageIndex,
    }) async {}),
    recordReadSessionActivityCommandProvider.overrideWithValue(
      ({
        required String comicId,
        required bool incognito,
        required Duration foregroundElapsed,
        required int pageIndex,
        required int pageCount,
      }) async {},
    ),
    openReadSessionUseCaseProvider.overrideWithValue(openUseCase),
    manageReadSessionUseCaseProvider.overrideWithValue(
      ManageReadSessionUseCase(
        openReadSession: openUseCase,
        recordProgress: ({
          required String comicId,
          required String title,
          required DateTime lastReadTime,
          required int pageIndex,
        }) async {},
        recordActivity: ({
          required String comicId,
          required bool incognito,
          required Duration foregroundElapsed,
          required int pageIndex,
          required int pageCount,
        }) async {},
      ),
    ),
    readerSessionOpenFromSourceProvider(
      source: _source,
      incognito: false,
      startFromFirstPage: true,
    ).overrideWith((Ref ref) => open()),
  ];
}

Future<void> _pumpFrames(WidgetTester tester, {int frames = 24}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpReaderHost(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  final config = localizedTestAppConfig();
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const ReaderPage.forSource(source: _source),
                    ),
                  );
                },
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
}

void main() {
  testWidgets('loading shell shows chrome back and exits without waiting open', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    final Completer<OpenedReadSession> hang = Completer<OpenedReadSession>();
    await _pumpReaderHost(
      tester,
      overrides: _baseOverrides(open: () => hang.future),
    );

    expect(find.byType(ReaderPage), findsOneWidget);
    expect(find.byType(ReaderLayout), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.tap(find.bySemanticsLabel('返回上一页'));
    await _pumpFrames(tester);

    expect(find.byType(ReaderPage), findsNothing);
    expect(find.text('open-reader'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('open error shows chrome and panel back exits', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await _pumpReaderHost(
      tester,
      overrides: _baseOverrides(
        open: () async {
          throw ReadSessionPageLoadException.loadFailed(
            comicId: _source.sessionKey,
            path: _source.sessionKey,
            cause: StateError('open failed'),
          );
        },
      ),
    );

    expect(find.byType(ReaderOpenErrorPanel), findsOneWidget);
    expect(find.byType(ReaderLayout), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('返回上一页'));
    await _pumpFrames(tester);

    expect(find.byType(ReaderPage), findsNothing);
    expect(find.text('open-reader'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('open error panel back-to-detail exits', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await _pumpReaderHost(
      tester,
      overrides: _baseOverrides(
        open: () async {
          throw ReadSessionPageLoadException.loadFailed(
            comicId: _source.sessionKey,
            path: _source.sessionKey,
            cause: StateError('open failed'),
          );
        },
      ),
    );

    expect(find.byType(ReaderOpenErrorPanel), findsOneWidget);
    await tester.tap(find.text('返回详情'));
    await _pumpFrames(tester);

    expect(find.byType(ReaderPage), findsNothing);
    expect(find.text('open-reader'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
