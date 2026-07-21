import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/repositories/app_setting_repository.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_controller.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/view/reader_viewport_host.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/continuous_vertical_viewport.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_page_data.dart';
import 'package:hentai_library/domain/reading/reader_page_payload.dart';
import 'package:hentai_library/ui/features/reader/view_models/read_session_providers.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const String _testComicId = 'test-comic';
const ReaderControllerKey _viewKey = (comicId: _testComicId, incognito: false);

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
                readingMode: ReadingMode.webtoon,
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
        (FlutterErrorDetails details) => details.exceptionAsString().contains(
          'ScrollController not attached to any scroll views',
        ),
      );
      expect(scrollControllerAssertion, isFalse);
    },
  );

  testWidgets(
    'fitWidth margin change updates continuous content max width',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository(
        AppSetting(webtoonMarginPercent: 20),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            appSettingRepoProvider.overrideWithValue(repo),
            ..._viewportTestOverrides(),
          ],
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
      await tester.pumpAndSettle();

      expect(_continuousContentMaxWidth(tester), 800);

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ContinuousVerticalViewport)),
      );
      await container
          .read(settingsProvider.notifier)
          .setWebtoonMarginPercent(0);
      await tester.pumpAndSettle();

      expect(_continuousContentMaxWidth(tester), 1000);
    },
  );

  testWidgets(
    'originalSize ignores margin and enables horizontal scrolling',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final _MemoryAppSettingRepository repo = _MemoryAppSettingRepository(
        AppSetting(
          webtoonMarginPercent: 40,
          webtoonZoomMode: WebtoonZoomMode.originalSize,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            appSettingRepoProvider.overrideWithValue(repo),
            ..._viewportTestOverrides(),
          ],
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
      await tester.pumpAndSettle();

      expect(
        _hasBoundedMaxWidth(tester, 600),
        isFalse,
        reason: 'originalSize must not apply 40% margin slot width',
      );
      expect(_hasHorizontalScrollable(tester), isTrue);
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
        (FlutterErrorDetails details) => details.exceptionAsString().contains(
          'ScrollController not attached to any scroll views',
        ),
      );
      expect(scrollControllerAssertion, isFalse);
    },
  );

  testWidgets(
    'mounting continuous viewport at non-first page keeps currentIndex',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            readerControllerProvider(
              _viewKey,
            ).overrideWith(_TestReaderControllerAtPage50.new),
            readerPrefetchControllerProvider.overrideWith(
              _FakeReaderPrefetchController.new,
            ),
            comicImagesProvider(comicId: _testComicId).overrideWith((
              Ref ref,
            ) async {
              return List<ReaderPageImageData>.generate(
                100,
                (int index) => ReaderArchivePageImageData(
                  comicId: _testComicId,
                  pageIndex: index,
                ),
              );
            }),
            ...List<Override>.generate(
              100,
              (int index) => comicReaderPageProvider(
                comicId: _testComicId,
                pageIndex: index,
              ).overrideWith((Ref ref) async => ReaderPageBytes(Uint8List(0))),
            ),
          ],
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ContinuousVerticalViewport)),
      );
      final int? currentIndex = container
          .read(readerControllerProvider(_viewKey))
          .asData
          ?.value
          .currentIndex;
      expect(currentIndex, 50);
    },
  );

  testWidgets(
    'switching from paged to continuous at mid page keeps currentIndex',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      Widget host(ReadingMode mode) {
        return ProviderScope(
          overrides: <Override>[
            readerControllerProvider(
              _viewKey,
            ).overrideWith(_TestReaderControllerAtPage50.new),
            readerPrefetchControllerProvider.overrideWith(
              _FakeReaderPrefetchController.new,
            ),
            comicImagesProvider(comicId: _testComicId).overrideWith((
              Ref ref,
            ) async {
              return List<ReaderPageImageData>.generate(
                100,
                (int index) => ReaderArchivePageImageData(
                  comicId: _testComicId,
                  pageIndex: index,
                ),
              );
            }),
            ...List<Override>.generate(
              100,
              (int index) => comicReaderPageProvider(
                comicId: _testComicId,
                pageIndex: index,
              ).overrideWith((Ref ref) async => ReaderPageBytes(Uint8List(0))),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReaderViewportHost(
                comicId: _testComicId,
                incognito: false,
                initialPage: 49,
                preferredPageIndex: null,
                readingMode: mode,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(host(ReadingMode.paged));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pumpWidget(host(ReadingMode.webtoon));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(ContinuousVerticalViewport)),
      );
      expect(
        container
            .read(readerControllerProvider(_viewKey))
            .asData
            ?.value
            .currentIndex,
        50,
      );
    },
  );
}

List<Override> _viewportTestOverrides() {
  final List<ReaderPageImageData> images = List<ReaderPageImageData>.generate(
    100,
    (int index) =>
        ReaderArchivePageImageData(comicId: _testComicId, pageIndex: index),
  );

  return <Override>[
    readerControllerProvider(_viewKey).overrideWith(_TestReaderController.new),
    readerPrefetchControllerProvider.overrideWith(
      _FakeReaderPrefetchController.new,
    ),
    comicImagesProvider(
      comicId: _testComicId,
    ).overrideWith((Ref ref) async => images),
    ...List<Override>.generate(
      100,
      (int index) => comicReaderPageProvider(
        comicId: _testComicId,
        pageIndex: index,
      ).overrideWith((Ref ref) async => ReaderPageBytes(Uint8List(0))),
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
      readingMode: ReadingMode.webtoon,
      currentIndex: 1,
      totalPagesOverride: 100,
    );
  }
}

class _TestReaderControllerAtPage50 extends ReaderController {
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
      readingMode: ReadingMode.webtoon,
      currentIndex: 50,
      totalPagesOverride: 100,
    );
  }
}

class _FakeReaderPrefetchController extends ReaderPrefetchController {
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

double _continuousContentMaxWidth(WidgetTester tester) {
  final Iterable<ConstrainedBox> boxes = tester
      .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
      .where(
        (ConstrainedBox box) =>
            box.constraints.hasBoundedWidth &&
            box.constraints.maxWidth < double.infinity,
      );
  expect(boxes, isNotEmpty);
  return boxes.first.constraints.maxWidth;
}

bool _hasBoundedMaxWidth(WidgetTester tester, double maxWidth) {
  return tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox)).any(
    (ConstrainedBox box) =>
        box.constraints.hasBoundedWidth &&
        box.constraints.maxWidth == maxWidth,
  );
}

bool _hasHorizontalScrollable(WidgetTester tester) {
  return tester.widgetList<Scrollable>(find.byType(Scrollable)).any(
    (Scrollable scrollable) =>
        scrollable.axisDirection == AxisDirection.right ||
        scrollable.axisDirection == AxisDirection.left,
  );
}

class _MemoryAppSettingRepository implements AppSettingRepository {
  _MemoryAppSettingRepository(this._setting);

  AppSetting _setting;

  @override
  Future<AppSetting> load() async => _setting;

  @override
  Future<void> save(AppSetting setting) async {
    _setting = setting;
  }
}
