import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/view/reader_viewport_host.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_content.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const String _comicId = 'reader-content-mode-switch';
const ReaderControllerKey _viewKey = (
  comicId: _comicId,
  incognito: true,
  startFromFirstPage: false,
);

void main() {
  testWidgets(
    'mode switch mounts a single viewport host without AnimatedSwitcher',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readerControllerProvider(
              _viewKey,
            ).overrideWith(() => _StubReaderController()),
            readerPrefetchControllerProvider.overrideWith(_FakePrefetch.new),
            comicImagesProvider(comicId: _comicId).overrideWith(
              (Ref ref) async => <ReaderPageImageData>[
                const ReaderArchivePageImageData(
                  comicId: _comicId,
                  pageIndex: 0,
                ),
              ],
            ),
            comicReaderPageProvider(
              comicId: _comicId,
              pageIndex: 0,
            ).overrideWith((Ref ref) async => ReaderPageBytes(Uint8List(0))),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderContent(
                comicId: _comicId,
                incognito: true,
                initialPage: 1,
                preferredPageIndex: null,
                readingMode: ReadingMode.paged,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedSwitcher), findsNothing);
      expect(find.byType(ReaderViewportHost), findsOneWidget);
    },
  );
}

class _StubReaderController extends ReaderController {
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
        title: 'Mode Switch',
        pageCount: 1,
      ),
      readingMode: ReadingMode.paged,
      currentIndex: 1,
      totalPagesOverride: 1,
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
}
