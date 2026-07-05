import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/view/reader_viewport_host.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/continuous_vertical_viewport.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const String _testComicId = 'test-comic';
const ReaderControllerKey _viewKey = (
  comicId: _testComicId,
  incognito: false,
);

void main() {
  testWidgets(
    'switching away from continuous mode during far-index scroll does not throw',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails details)? previousHandler =
          FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        previousHandler?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = previousHandler;
      });

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _viewportTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: ReaderViewportHost(
                comicId: _testComicId,
                incognito: false,
                initialPage: 0,
                preferredPageIndex: null,
                readingMode: ReadingMode.continuousVertical,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ReaderViewportHost)),
      );
      container.read(readerControllerProvider(_viewKey).notifier).setIndex(80);

      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _viewportTestOverrides(),
          child: MaterialApp(
            home: Scaffold(
              body: ReaderViewportHost(
                comicId: _testComicId,
                incognito: false,
                initialPage: 79,
                preferredPageIndex: null,
                readingMode: ReadingMode.paged,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final bool scrollControllerAssertion = errors.any(
        (FlutterErrorDetails details) =>
            details.exceptionAsString().contains(
              'ScrollController not attached to any scroll views',
            ),
      );
      expect(scrollControllerAssertion, isFalse);
    },
  );

  testWidgets(
    'unmounting during far-index programmatic scroll does not throw',
    (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails details)? previousHandler =
          FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details);
        previousHandler?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = previousHandler;
      });

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _viewportTestOverrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: ContinuousVerticalViewport(
                comicId: _testComicId,
                incognito: false,
                preferredPageIndex: null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ContinuousVerticalViewport)),
      );
      container.read(readerControllerProvider(_viewKey).notifier).setIndex(80);

      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final bool scrollControllerAssertion = errors.any(
        (FlutterErrorDetails details) =>
            details.exceptionAsString().contains(
              'ScrollController not attached to any scroll views',
            ),
      );
      expect(scrollControllerAssertion, isFalse);
    },
  );
}

List<Override> _viewportTestOverrides() {
  final List<ReaderPageImageData> images = List<ReaderPageImageData>.generate(
    100,
    (int index) => ReaderArchivePageImageData(
      comicId: _testComicId,
      pageIndex: index,
    ),
  );

  return <Override>[
    readerControllerProvider(_viewKey).overrideWith(_TestReaderController.new),
    comicImagesProvider(comicId: _testComicId).overrideWith(
      (Ref ref) async => images,
    ),
    ...List<Override>.generate(
      100,
      (int index) => comicReaderPageBytesProvider(
        comicId: _testComicId,
        pageIndex: index,
      ).overrideWith((Ref ref) async => Uint8List(0)),
    ),
  ];
}

class _TestReaderController extends ReaderController {
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
        title: 'Test Comic',
        pageCount: 100,
      ),
      readingMode: ReadingMode.continuousVertical,
      currentIndex: 1,
      totalPagesOverride: 100,
    );
  }
}
