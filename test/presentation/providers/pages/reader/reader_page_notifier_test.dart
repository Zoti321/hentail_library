import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_accessor.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/comic_read_resource_session_manager.dart';
import 'package:hentai_library/data/services/comic/read_resource_get/reader_image.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/reading_history.dart';
import 'package:hentai_library/model/entity/series_reading_history.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/providers/pages/reader/reader_page_notifier.dart';
import 'package:hentai_library/presentation/ui/shared/routing/reader_route_args.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/reader_page/widgets/reader_route_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class _MockComicRepository extends Mock implements ComicRepository {}

class _MockReadingHistoryRepository extends Mock
    implements ReadingHistoryRepository {}

class _MockComicReadResourceSessionManager extends Mock
    implements ComicReadResourceSessionManager {}

class _FakeDirAccessor implements ComicReadResourceAccessor {
  @override
  int get pageCount => 3;

  @override
  Future<void> dispose() async {}

  @override
  Future<ReaderImage> getCoverImage() async {
    return ReaderFileImage(File('cover.jpg'));
  }

  @override
  Future<ReaderImage> getPageImage(int pageIndex) async {
    return ReaderFileImage(File('test_page_${pageIndex + 1}.jpg'));
  }

  @override
  Future<void> prepare() async {}
}

class _FakeReadingHistory extends Fake implements ReadingHistory {}

class _FakeSeriesReadingHistory extends Fake implements SeriesReadingHistory {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeReadingHistory());
    registerFallbackValue(_FakeSeriesReadingHistory());
  });

  test('handleTapZone in horizontal mode updates page and controls', () async {
    final fixture = _ReaderNotifierFixture();
    addTearDown(fixture.container.dispose);
    final notifier = await fixture.initialize();
    notifier.handleTapZone(ReaderTapZone.right);
    expect(fixture.currentState.currentIndex, 3);
    notifier.handleTapZone(ReaderTapZone.left);
    expect(fixture.currentState.currentIndex, 2);
    notifier.handleTapZone(ReaderTapZone.center);
    expect(fixture.currentState.showControls, isTrue);
    notifier.handleTapZone(ReaderTapZone.right);
    expect(fixture.currentState.showControls, isFalse);
    expect(fixture.currentState.currentIndex, 2);
  });

  test('handleTapZone in vertical mode only toggles controls', () async {
    final fixture = _ReaderNotifierFixture();
    addTearDown(fixture.container.dispose);
    final notifier = await fixture.initialize();
    notifier.setIsVertical(true);
    notifier.handleTapZone(ReaderTapZone.left);
    expect(fixture.currentState.showControls, isTrue);
    expect(fixture.currentState.currentIndex, 2);
  });

  test('page index respects boundaries', () async {
    final fixture = _ReaderNotifierFixture();
    addTearDown(fixture.container.dispose);
    final notifier = await fixture.initialize();
    notifier.nextPage();
    notifier.nextPage();
    notifier.nextPage();
    expect(fixture.currentState.currentIndex, 3);
    notifier.prevPage();
    notifier.prevPage();
    notifier.prevPage();
    expect(fixture.currentState.currentIndex, 1);
  });

  test('executeSaveProgress records comic progress in comic mode', () async {
    final fixture = _ReaderNotifierFixture();
    addTearDown(fixture.container.dispose);
    final notifier = await fixture.initialize();
    await notifier.executeSaveProgress(
      routeContext: const ReaderRouteContext(
        comicId: 'comic-1',
        readType: ReaderReadType.comic,
      ),
    );
    verify(() => fixture.readingHistoryRepo.recordReading(any())).called(1);
    verifyNever(() => fixture.readingHistoryRepo.recordSeriesReading(any()));
  });

  testWidgets('executeSelectSeriesComic saves series progress before routing', (
    WidgetTester tester,
  ) async {
    final fixture = _ReaderNotifierFixture();
    final notifier = await fixture.initialize();
    final router = GoRouter(
      initialLocation: '/',
      routes: <GoRoute>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Placeholder());
          },
        ),
        GoRoute(
          path: '/reader',
          name: ReaderRouteArgs.readerRouteName,
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('reader'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: fixture.container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    final BuildContext context = tester.element(find.byType(Placeholder));
    await notifier.executeSelectSeriesComic(
      context: context,
      routeContext: const ReaderRouteContext(
        comicId: 'comic-1',
        readType: ReaderReadType.series,
        seriesName: 'Series-A',
      ),
      targetComicId: 'comic-2',
      seriesName: 'Series-A',
    );
    verify(
      () => fixture.readingHistoryRepo.recordSeriesReading(any()),
    ).called(1);
    verifyNever(() => fixture.readingHistoryRepo.recordReading(any()));
    fixture.container.dispose();
    await tester.pump();
  });
}

class _ReaderNotifierFixture {
  _ReaderNotifierFixture() {
    when(() => comicRepo.findById('comic-1')).thenAnswer((_) async => _comic);
    when(() => readingHistoryRepo.getByComicId('comic-1')).thenAnswer(
      (_) async => ReadingHistory(
        comicId: 'comic-1',
        title: _comic.title,
        lastReadTime: DateTime(2024),
        pageIndex: 2,
      ),
    );
    when(
      () => readingHistoryRepo.recordReading(any()),
    ).thenAnswer((_) async {});
    when(
      () => readingHistoryRepo.recordSeriesReading(any()),
    ).thenAnswer((_) async {});
    when(
      () => sessionManager.acquire(
        comicId: 'comic-1',
        path: _comic.path,
        type: _comic.resourceType,
      ),
    ).thenAnswer((_) async => _FakeDirAccessor());
  }
  final Comic _comic = Comic(
    comicId: 'comic-1',
    path: '/tmp/comic-1',
    resourceType: ResourceType.dir,
    title: 'Comic One',
  );
  final _MockComicRepository comicRepo = _MockComicRepository();
  final _MockReadingHistoryRepository readingHistoryRepo =
      _MockReadingHistoryRepository();
  final _MockComicReadResourceSessionManager sessionManager =
      _MockComicReadResourceSessionManager();
  late final ProviderContainer container = ProviderContainer(
    overrides: [
      comicRepoProvider.overrideWithValue(comicRepo),
      readingHistoryRepoProvider.overrideWithValue(readingHistoryRepo),
      comicReadResourceSessionManagerProvider.overrideWithValue(sessionManager),
    ],
  );

  Future<ReaderViewNotifier> initialize() async {
    await container.read(readerViewProvider('comic-1').future);
    return container.read(readerViewProvider('comic-1').notifier);
  }

  ReaderViewState get currentState =>
      container.read(readerViewProvider('comic-1')).asData!.value;
}
