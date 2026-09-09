import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/ports/comic_page_source_port.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/reading/read_session_page.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/domain/reading/reader_session_service.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/paged_viewport.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_image_item.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

/// 1x1 PNG — non-empty payload for archive page providers.
final Uint8List _kTinyPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

const String _comicId = 'paged-slider-jump-load-comic';
const ReaderControllerKey _viewKey = (
  comicId: _comicId,
  incognito: false,
  startFromFirstPage: false,
);

void main() {
  testWidgets(
    'paged large slider jump loads landing page without prev/next wake',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const int pageCount = 40;
      const int startPage = 1;
      const int jumpToPage = 28;
      final Set<int> requestedZeroBased = <int>{};
      final Map<int, Completer<ReaderPagePayload>> pending =
          <int, Completer<ReaderPagePayload>>{};

      final Comic comic = Comic(
        comicId: _comicId,
        path: '/tmp/test.cbz',
        resourceType: ResourceType.cbz,
        resourceSize: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        lastUpdatedAt: DateTime.utc(2026, 1, 1),
        title: 'Slider Jump Load',
        pageCount: pageCount,
      );
      final ReaderSessionService session = ReaderSessionService(
        comicRepo: _FakeComicRepo(comic),
        pageSource: _FakePageSource(),
        readingHistoryRepo: _FakeHistoryRepo(),
        sessionPort: _FakeSessionPort(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readerControllerProvider(
              _viewKey,
            ).overrideWith(() => _PagedReaderController(startPage, pageCount)),
            // Real warmWindow (invalidate leavers + kick center); skip Flutter
            // image precache which hangs widget tests on ExtendedImage streams.
            readerPrefetchControllerProvider.overrideWith(
              _WarmOnlyPrefetch.new,
            ),
            readerSessionServiceProvider.overrideWithValue(session),
            comicImagesProvider(comicId: _comicId).overrideWith(
              (Ref ref) async => List<ReaderPageImageData>.generate(
                pageCount,
                (int index) => ReaderArchivePageImageData(
                  comicId: _comicId,
                  pageIndex: index,
                ),
              ),
            ),
            ...List<Override>.generate(pageCount, (int index) {
              return comicReaderPageProvider(
                comicId: _comicId,
                pageIndex: index,
              ).overrideWith((Ref ref) async {
                requestedZeroBased.add(index);
                final Completer<ReaderPagePayload> completer =
                    pending.putIfAbsent(
                      index,
                      Completer<ReaderPagePayload>.new,
                    );
                return completer.future;
              });
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PagedViewport(
                comicId: _comicId,
                incognito: false,
                initialPage: 0,
                preferredPageIndex: null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      void resolve(int zeroBased) {
        pending
            .putIfAbsent(zeroBased, Completer<ReaderPagePayload>.new)
            .complete(ReaderPageBytes(_kTinyPng));
      }

      // Settle opening window (center + neighbors from real warmWindow).
      resolve(0);
      resolve(1);
      resolve(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      requestedZeroBased.clear();
      pending.clear();

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(PagedViewport)),
      );

      container.read(readerControllerProvider(_viewKey).notifier).setIndex(
        jumpToPage,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 200));

      final int landingZeroBased = jumpToPage - 1;
      expect(
        requestedZeroBased.contains(landingZeroBased),
        isTrue,
        reason:
            'large jump must request landing page payload without prev/next '
            '(requested=$requestedZeroBased)',
      );

      // Resolve landing window pages kicked by warmWindow center-first load.
      for (final int index in List<int>.from(requestedZeroBased)) {
        resolve(index);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final PageView pageView = tester.widget(find.byType(PageView));
      final PageController? pageController = pageView.controller;
      expect(pageController, isNotNull);
      expect(
        pageController!.page?.round() ?? pageController.initialPage,
        landingZeroBased,
      );

      final int? currentIndex = container
          .read(readerControllerProvider(_viewKey))
          .asData
          ?.value
          .currentIndex;
      expect(currentIndex, jumpToPage);

      expect(
        find.byType(ReaderImageItem),
        findsWidgets,
        reason: 'landing page ReaderImageItem must be mounted after jump',
      );

      final AsyncValue<ReaderPagePayload> landing = container.read(
        comicReaderPageProvider(
          comicId: _comicId,
          pageIndex: landingZeroBased,
        ),
      );
      expect(
        landing.hasValue,
        isTrue,
        reason: 'landing page must resolve without prev/next wake',
      );
    },
  );
}

class _PagedReaderController extends ReaderController {
  _PagedReaderController(this.page, this.pageCount);

  final int page;
  final int pageCount;

  @override
  Future<ReaderState> build(ReaderControllerKey key) async {
    final DateTime now = DateTime.utc(2026, 1, 1);
    return ReaderState(
      comic: Comic(
        comicId: key.comicId,
        path: '/tmp/test.cbz',
        resourceType: ResourceType.cbz,
        resourceSize: 1,
        createdAt: now,
        lastUpdatedAt: now,
        title: 'Slider Jump Load',
        pageCount: pageCount,
      ),
      readingMode: ReadingMode.paged,
      currentIndex: page,
      totalPagesOverride: pageCount,
    );
  }
}

/// Production [warmWindow]; no-op [precacheWindow] for widget-test stability.
class _WarmOnlyPrefetch extends ReaderPrefetchController {
  @override
  Future<void> precacheWindow({
    required BuildContext context,
    required String comicId,
    required Set<int> pageIndexesOneBased,
    required List<ReaderPageImageData> imageList,
    int? cacheWidth,
  }) async {}
}

class _FakeComicRepo implements ComicRepository {
  _FakeComicRepo(this.comic);
  final Comic comic;

  @override
  Future<Comic?> findById(String comicId) async => comic;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHistoryRepo implements ReadingHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSessionPort implements ReaderSessionPort {
  @override
  Future<void> openComic(Comic comic) async {}

  @override
  Future<void> closeComic(String comicId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePageSource implements ComicPageSourcePort {
  @override
  Future<List<ReadSessionPage>> loadPages(Comic comic) async =>
      const <ReadSessionPage>[];

  @override
  Future<ReaderPagePayload> loadReaderPage({
    required Comic comic,
    required int pageIndex,
  }) async => ReaderPageBytes(_kTinyPng);

  @override
  Future<void> prefetchPages({
    required Comic comic,
    required List<int> pageIndexes,
    required int generation,
  }) async {}

  @override
  Future<void> clearPageCache({required String comicId}) async {}

  @override
  Future<Uint8List?> loadPageBytes({
    required Comic comic,
    required int pageIndex,
  }) async => null;
}
