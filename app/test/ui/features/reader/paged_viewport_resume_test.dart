import 'dart:async';
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

const String _comicId = 'paged-resume-comic';
const ReaderControllerKey _viewKey = (comicId: _comicId, incognito: false);

void main() {
  testWidgets(
    'paged resume mid-comic survives delayed image list without drifting down',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const int resumePage = 54;
      const int pageCount = 80;
      final Completer<List<ReaderPageImageData>> imagesCompleter =
          Completer<List<ReaderPageImageData>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readerControllerProvider(
              _viewKey,
            ).overrideWith(() => _PagedReaderController(resumePage, pageCount)),
            readerPrefetchControllerProvider.overrideWith(
              _FakePrefetch.new,
            ),
            comicImagesProvider(comicId: _comicId).overrideWith(
              (Ref ref) => imagesCompleter.future,
            ),
            ...List<Override>.generate(
              pageCount,
              (int index) => comicReaderPageProvider(
                comicId: _comicId,
                pageIndex: index,
              ).overrideWith(
                (Ref ref) async => ReaderPageBytes(Uint8List(0)),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PagedViewport(
                comicId: _comicId,
                incognito: false,
                initialPage: resumePage - 1,
                preferredPageIndex: resumePage,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Images arrive after first layout (itemCount 0 → N).
      imagesCompleter.complete(
        List<ReaderPageImageData>.generate(
          pageCount,
          (int index) => ReaderArchivePageImageData(
            comicId: _comicId,
            pageIndex: index,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Allow animateToPage (150ms) + late onPageChanged to run.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(PagedViewport)),
      );
      final int? index = container
          .read(readerControllerProvider(_viewKey))
          .asData
          ?.value
          .currentIndex;
      expect(
        index,
        resumePage,
        reason:
            'paged onPageChanged must not rewrite resume page after images attach '
            '(got $index)',
      );
    },
  );

  testWidgets(
    'paged overlapping programmatic animate must not apply intermediate pages',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const int resumePage = 54;
      const int pageCount = 80;
      final List<ReaderPageImageData> images = List<ReaderPageImageData>.generate(
        pageCount,
        (int index) => ReaderArchivePageImageData(
          comicId: _comicId,
          pageIndex: index,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readerControllerProvider(
              _viewKey,
            ).overrideWith(() => _PagedReaderController(resumePage, pageCount)),
            readerPrefetchControllerProvider.overrideWith(_FakePrefetch.new),
            comicImagesProvider(
              comicId: _comicId,
            ).overrideWith((Ref ref) async => images),
            ...List<Override>.generate(
              pageCount,
              (int index) => comicReaderPageProvider(
                comicId: _comicId,
                pageIndex: index,
              ).overrideWith(
                (Ref ref) async => ReaderPageBytes(Uint8List(0)),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PagedViewport(
                comicId: _comicId,
                incognito: false,
                initialPage: resumePage - 1,
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
      final ReaderController controller = container.read(
        readerControllerProvider(_viewKey).notifier,
      );

      // Overlapping programmatic jumps (preferred/resume races).
      controller.setIndex(20);
      await tester.pump();
      controller.setIndex(resumePage);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        container
            .read(readerControllerProvider(_viewKey))
            .asData
            ?.value
            .currentIndex,
        resumePage,
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
        title: 'Paged Resume',
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
  }) async {}
}
