import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/paged_viewport.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

/// After bottom-bar volume switch, route opens with [startFromFirstPage]: true.
/// Chrome and viewport must share that controller key or slider updates UI
/// while PageView stays put.
const String _comicId = 'series-switch-page-jump-comic';
const ReaderControllerKey _uiKeyAfterVolumeSwitch = (
  comicId: _comicId,
  incognito: false,
  startFromFirstPage: true,
);

void main() {
  testWidgets(
    'after volume switch (startFromFirstPage=true), setIndex moves PageView',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const int pageCount = 20;
      const int jumpToPage = 8;
      final List<ReaderPageImageData> images =
          List<ReaderPageImageData>.generate(
            pageCount,
            (int index) =>
                ReaderArchivePageImageData(comicId: _comicId, pageIndex: index),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readerControllerProvider(_uiKeyAfterVolumeSwitch).overrideWith(
              () => _PagedReaderController(1, pageCount),
            ),
            readerPrefetchControllerProvider.overrideWith(_FakePrefetch.new),
            comicImagesProvider(
              comicId: _comicId,
            ).overrideWith((Ref ref) async => images),
            ...List<Override>.generate(
              pageCount,
              (int index) => comicReaderPageProvider(
                comicId: _comicId,
                pageIndex: index,
              ).overrideWith((Ref ref) async => ReaderPageBytes(Uint8List(0))),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PagedViewport(
                comicId: _comicId,
                incognito: false,
                startFromFirstPage: true,
                initialPage: 0,
                preferredPageIndex: null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(PagedViewport)),
      );

      container
          .read(readerControllerProvider(_uiKeyAfterVolumeSwitch).notifier)
          .setIndex(jumpToPage);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final PageView pageView = tester.widget(find.byType(PageView));
      final PageController? pageController = pageView.controller;
      expect(pageController, isNotNull);
      expect(
        pageController!.page?.round() ?? pageController.initialPage,
        jumpToPage - 1,
        reason:
            'after volume switch, chrome and viewport must share '
            'startFromFirstPage=true controller key',
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
        title: 'Series Switch Jump',
        pageCount: pageCount,
      ),
      readingMode: ReadingMode.paged,
      currentIndex: page,
      totalPagesOverride: pageCount,
    );
  }
}

class _FakePrefetch extends ReaderPrefetchController {
  @override
  Map<String, int> build() => <String, int>{};

  @override
  Future<void> warmWindow({
    required String comicId,
    required int centerPageOneBased,
    required int totalPages,
    Iterable<int> extraPageIndexesOneBased = const <int>[],
  }) async {}

  @override
  Future<void> precacheWindow({
    required BuildContext context,
    required String comicId,
    required Set<int> pageIndexesOneBased,
    required List<ReaderPageImageData> imageList,
    int? cacheWidth,
  }) async {}
}
