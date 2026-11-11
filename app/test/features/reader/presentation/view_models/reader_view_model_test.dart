import 'package:hentai_library/features/bootstrap/di/composition_overrides.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/public/comic_lookup_repository.dart';
import 'package:hentai_library/features/reader/application/read_session_application_service.dart';
import 'package:hentai_library/features/reader/application/open_read_session_service.dart';
import 'package:hentai_library/features/reader/di/session_providers.dart';
import 'package:hentai_library/features/reader/domain/comic_page_source_port.dart';
import 'package:hentai_library/features/reader/application/open_reader_args.dart';
import 'package:hentai_library/features/reader/domain/read_session_page.dart';
import 'package:hentai_library/features/reader/domain/native_reader_port.dart';
import 'package:hentai_library/features/reader/domain/opened_read_session.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_auto_play_carry.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_prefetch_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_series_navigation.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_navigation_intent.dart';
import 'package:hentai_library/features/reader/presentation/view_models/read_session_providers.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/features/reading_stats/public.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hentai_library/features/bootstrap/di/shared_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;

import '../../../../support/fakes/settings_test_fakes.dart';

const String _comicId = 'reader-controller-comic';
const ReaderViewModelKey _key = (
  comicId: _comicId,
  incognito: false,
  startFromFirstPage: false,
);
const ReaderViewModelKey _incognitoKey = (
  comicId: _comicId,
  incognito: true,
  startFromFirstPage: false,
);

ReaderComicRef _comic({int pageCount = 10}) {
  return ReaderComicRef(
    comicId: _comicId,
    path: '/tmp/$_comicId.cbz',
    resourceType: ResourceType.cbz,
    title: 'Controller Test',
    pageCount: pageCount,
  );
}

OpenedReadSession _snapshot({int pageCount = 10, int resumePage = 1}) {
  final ReaderComicRef comic = _comic(pageCount: pageCount);
  return OpenedReadSession(
    comic: comic,
    pages: List<ReadSessionPage>.generate(
      pageCount,
      (int index) =>
          ReadSessionArchivePage(comicId: _comicId, pageIndex: index),
    ),
    resumePageIndex: resumePage,
  );
}

class _RecordingSeriesNavigation extends ReaderSeriesNavigation {
  final List<String> switchedTo = <String>[];

  @override
  void build() {}

  @override
  Future<ReaderReplaceReaderRouteIntent?> prepareSwitchComic({
    required OpenReaderArgs currentSession,
    required String targetComicId,
  }) async {
    switchedTo.add(targetComicId);
    return ReaderReplaceReaderRouteIntent('/reader?comicId=$targetComicId');
  }
}

class _FakePrefetchController extends ReaderPrefetchNotifier {
  final List<String> warmedOpen = <String>[];

  @override
  Map<String, int> build() => <String, int>{};

  @override
  Future<void> warmOpenComic({
    required String comicId,
    int? resumePageOneBased,
  }) async {
    warmedOpen.add(comicId);
  }
}

class _NoOpHistoryCommands implements ReadingHistoryCommandPort {
  @override
  Future<void> recordReading({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
  }) async {}

  @override
  Future<int?> readResumePageIndex(String comicId) async => null;
}

class _UnusedComicLookup implements ComicLookupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedPageSource implements ComicPageSourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedSessionPort implements NativeReaderPort {
  @override
  Future<void> openComic(ReaderComicRef comic) async {}

  @override
  Future<void> closeComic(String comicId) async {}

  @override
  Future<void> clear() async {}
}

class _NoOpActivityCommands implements RecordReadSessionActivityPort {
  @override
  Future<void> record({
    required String comicId,
    required bool incognito,
    required Duration foregroundElapsed,
    required int pageIndex,
    required int pageCount,
  }) async {}
}

/// Controller build now begins a history session; keep I/O stubs unused.
Override _stubCoordinatorOverride() {
  final _NoOpHistoryCommands history = _NoOpHistoryCommands();
  return readSessionApplicationServiceProvider.overrideWithValue(
    ReadSessionApplicationService(
      sessionService: OpenReadSessionService(
        comicRepo: _UnusedComicLookup(),
        pageSource: _UnusedPageSource(),
        readingHistoryCommands: history,
        sessionPort: _UnusedSessionPort(),
      ),
      readingHistoryCommands: history,
      activityCommands: _NoOpActivityCommands(),
    ),
  );
}

ReaderNavContextData _navContext({
  String? previousComicId,
  String? nextComicId,
  String currentComicId = _comicId,
}) {
  final List<ReaderComicListItem> items = <ReaderComicListItem>[];
  if (previousComicId != null) {
    items.add(
      ReaderComicListItem(
        comicId: previousComicId,
        title: 'Previous',
        order: 0,
      ),
    );
  }
  items.add(
    ReaderComicListItem(
      comicId: currentComicId,
      title: 'Current',
      order: items.length,
    ),
  );
  if (nextComicId != null) {
    items.add(
      ReaderComicListItem(
        comicId: nextComicId,
        title: 'Next',
        order: items.length,
      ),
    );
  }
  return ReaderNavContextData(
    items: items,
    currentIndex: previousComicId == null ? 0 : 1,
    preferredPageIndex: null,
  );
}

ProviderContainer _createContainer({
  required AppSetting initialSetting,
  ReaderViewModelKey key = _key,
  OpenedReadSession? snapshot,
  _RecordingSeriesNavigation? seriesNavigation,
  _FakePrefetchController? prefetch,
}) {
  final OpenedReadSession session = snapshot ?? _snapshot();
  return ProviderContainer(
    overrides: <Override>[
      ...sharedLibraryStateOverrides(),
      ...bootstrapCompositionOverrides(),
      _stubCoordinatorOverride(),
      appSettingRepoProvider.overrideWithValue(
        MemoryAppSettingRepository(initial: initialSetting),
      ),
      readerSessionOpenProvider(
        comicId: key.comicId,
        incognito: key.incognito,
      ).overrideWith((Ref ref) async => session),
      if (seriesNavigation != null)
        readerSeriesNavigationProvider.overrideWith(() => seriesNavigation),
      if (prefetch != null)
        readerPrefetchNotifierProvider.overrideWith(() => prefetch),
    ],
  );
}

ReaderViewModel _controller(
  ProviderContainer container,
  ReaderViewModelKey key,
) => container.read(readerViewModelProvider(key).notifier);

ReaderUiState? _state(ProviderContainer container, ReaderViewModelKey key) =>
    container.read(readerViewModelProvider(key)).asData?.value;

void main() {
  group('auto-play session state', () {
    test('opens with autoPlayEnabled false', () async {
      final ProviderContainer container = _createContainer(
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
      );
      addTearDown(container.dispose);

      final ReaderUiState state = await container.read(
        readerViewModelProvider(_key).future,
      );

      expect(state.autoPlayEnabled, isFalse);
    });

    test(
      'setAutoPlayEnabled(true) keeps auto-play on for same comic',
      () async {
        final ProviderContainer container = _createContainer(
          initialSetting: AppSetting(readingMode: ReadingMode.paged),
        );
        addTearDown(container.dispose);

        await container.read(readerViewModelProvider(_key).future);
        _controller(container, _key).setAutoPlayEnabled(true);

        expect(_state(container, _key)?.autoPlayEnabled, isTrue);
      },
    );

    test('new comic session starts with auto-play off', () async {
      const ReaderViewModelKey otherKey = (
        comicId: 'reader-controller-other',
        incognito: false,
        startFromFirstPage: false,
      );
      final OpenedReadSession otherSnapshot = OpenedReadSession(
        comic: ReaderComicRef(
          comicId: otherKey.comicId,
          path: '/tmp/${otherKey.comicId}.cbz',
          resourceType: ResourceType.cbz,
          title: 'Other Comic',
          pageCount: 5,
        ),
        pages: List<ReadSessionPage>.generate(
          5,
          (int index) => ReadSessionArchivePage(
            comicId: otherKey.comicId,
            pageIndex: index,
          ),
        ),
        resumePageIndex: 1,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          ...sharedLibraryStateOverrides(),
          ...bootstrapCompositionOverrides(),
          _stubCoordinatorOverride(),
          appSettingRepoProvider.overrideWithValue(
            MemoryAppSettingRepository(
              initial: AppSetting(readingMode: ReadingMode.paged),
            ),
          ),
          readerSessionOpenProvider(
            comicId: _key.comicId,
            incognito: _key.incognito,
          ).overrideWith((Ref ref) async => _snapshot()),
          readerSessionOpenProvider(
            comicId: otherKey.comicId,
            incognito: otherKey.incognito,
          ).overrideWith((Ref ref) async => otherSnapshot),
        ],
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_key).future);
      _controller(container, _key).setAutoPlayEnabled(true);

      final ReaderUiState otherState = await container.read(
        readerViewModelProvider(otherKey).future,
      );

      expect(_state(container, _key)?.autoPlayEnabled, isTrue);
      expect(otherState.autoPlayEnabled, isFalse);
    });

    test('setReadingMode(webtoon) turns auto-play off', () async {
      final ProviderContainer container = _createContainer(
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_key).future);
      final ReaderViewModel controller = _controller(container, _key);
      controller.setAutoPlayEnabled(true);
      controller.setReadingMode(ReadingMode.webtoon);

      expect(_state(container, _key)?.autoPlayEnabled, isFalse);
      expect(_state(container, _key)?.readingMode, ReadingMode.webtoon);
    });

    test('armed autoplay carry restores on next ReaderViewModel', () async {
      const ReaderViewModelKey otherKey = (
        comicId: 'reader-controller-carry',
        incognito: false,
        startFromFirstPage: true,
      );
      final OpenedReadSession otherSnapshot = OpenedReadSession(
        comic: ReaderComicRef(
          comicId: otherKey.comicId,
          path: '/tmp/${otherKey.comicId}.cbz',
          resourceType: ResourceType.cbz,
          title: 'Carry Comic',
          pageCount: 5,
        ),
        pages: List<ReadSessionPage>.generate(
          5,
          (int index) => ReadSessionArchivePage(
            comicId: otherKey.comicId,
            pageIndex: index,
          ),
        ),
        resumePageIndex: 1,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          ...sharedLibraryStateOverrides(),
          ...bootstrapCompositionOverrides(),
          _stubCoordinatorOverride(),
          appSettingRepoProvider.overrideWithValue(
            MemoryAppSettingRepository(
              initial: AppSetting(readingMode: ReadingMode.paged),
            ),
          ),
          readerSessionOpenProvider(
            comicId: otherKey.comicId,
            incognito: otherKey.incognito,
            startFromFirstPage: otherKey.startFromFirstPage,
          ).overrideWith((Ref ref) async => otherSnapshot),
        ],
      );
      addTearDown(container.dispose);

      container.read(readerAutoPlayCarryProvider.notifier).arm(true);
      final ReaderUiState state = await container.read(
        readerViewModelProvider(otherKey).future,
      );

      expect(state.autoPlayEnabled, isTrue);
      expect(container.read(readerAutoPlayCarryProvider), isFalse);
    });
  });

  group('reading mode from AppSetting', () {
    test(
      'opens with readingMode from AppSetting (not default paged)',
      () async {
        final ProviderContainer container = _createContainer(
          initialSetting: AppSetting(readingMode: ReadingMode.webtoon),
        );
        addTearDown(container.dispose);

        final ReaderUiState state = await container.read(
          readerViewModelProvider(_key).future,
        );

        expect(state.readingMode, ReadingMode.webtoon);
      },
    );

    test('syncs readingMode when AppSetting changes', () async {
      final ProviderContainer container = _createContainer(
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_key).future);
      await container
          .read(settingsProvider.notifier)
          .setReadingMode(ReadingMode.webtoon);

      expect(_state(container, _key)?.readingMode, ReadingMode.webtoon);
    });
  });

  group('page navigation', () {
    test('paged to webtoon keeps currentIndex', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 20, resumePage: 7),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      _controller(container, _incognitoKey).setReadingMode(ReadingMode.webtoon);

      final ReaderUiState? state = _state(container, _incognitoKey);
      expect(state?.readingMode, ReadingMode.webtoon);
      expect(state?.currentIndex, 7);
    });

    test('dualPage to webtoon remaps to last page in spread', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.dualPage),
        snapshot: _snapshot(pageCount: 10, resumePage: 3),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      _controller(container, _incognitoKey).setReadingMode(ReadingMode.webtoon);

      expect(_state(container, _incognitoKey)?.currentIndex, 4);
    });

    test('nextPage and prevPage move within bounds', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 1),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);

      controller.prevPage();
      expect(_state(container, _incognitoKey)?.currentIndex, 1);

      controller.nextPage();
      expect(_state(container, _incognitoKey)?.currentIndex, 2);

      controller.setIndex(5);
      controller.nextPage();
      expect(_state(container, _incognitoKey)?.currentIndex, 5);
    });

    test('setIndex ignores out-of-range and accepts valid page', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 2),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);

      controller.setIndex(0);
      expect(_state(container, _incognitoKey)?.currentIndex, 2);

      controller.setIndex(6);
      expect(_state(container, _incognitoKey)?.currentIndex, 2);

      controller.setIndex(4);
      expect(_state(container, _incognitoKey)?.currentIndex, 4);
    });
  });

  group('requestPrevPage series retreat', () {
    const String previousComicId = 'previous-series-comic';
    const OpenReaderArgs session = OpenReaderArgs(
      comicId: _comicId,
      incognito: true,
    );

    test(
      'first call on first spread with previous comic arms retreat prompt',
      () async {
        final _RecordingSeriesNavigation navigation =
            _RecordingSeriesNavigation();
        final _FakePrefetchController prefetch = _FakePrefetchController();
        final ProviderContainer container = _createContainer(
          key: _incognitoKey,
          initialSetting: AppSetting(readingMode: ReadingMode.paged),
          snapshot: _snapshot(pageCount: 5, resumePage: 1),
          seriesNavigation: navigation,
          prefetch: prefetch,
        );
        addTearDown(container.dispose);

        await container.read(readerViewModelProvider(_incognitoKey).future);
        final ReaderViewModel controller = _controller(
          container,
          _incognitoKey,
        );

        await controller.requestPrevPage(
          navContext: _navContext(previousComicId: previousComicId),
          session: session,
        );

        expect(
          _state(container, _incognitoKey)?.seriesBoundaryPrompt,
          SeriesBoundaryPrompt.retreat,
        );
        expect(_state(container, _incognitoKey)?.currentIndex, 1);
        expect(prefetch.warmedOpen, <String>[previousComicId]);
        expect(navigation.switchedTo, isEmpty);
      },
    );

    test('second call on first spread switches to previous comic', () async {
      final _RecordingSeriesNavigation navigation =
          _RecordingSeriesNavigation();
      final _FakePrefetchController prefetch = _FakePrefetchController();
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 1),
        seriesNavigation: navigation,
        prefetch: prefetch,
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);
      final ReaderNavContextData nav = _navContext(
        previousComicId: previousComicId,
      );

      await controller.requestPrevPage(navContext: nav, session: session);
      await controller.requestPrevPage(navContext: nav, session: session);

      expect(navigation.switchedTo, <String>[previousComicId]);
      expect(
        _state(container, _incognitoKey)?.seriesBoundaryPrompt,
        SeriesBoundaryPrompt.none,
      );
    });

    test('on first spread without previous comic is a no-op', () async {
      final _RecordingSeriesNavigation navigation =
          _RecordingSeriesNavigation();
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 1),
        seriesNavigation: navigation,
        prefetch: _FakePrefetchController(),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);

      await controller.requestPrevPage(
        navContext: _navContext(),
        session: session,
      );

      expect(
        _state(container, _incognitoKey)?.seriesBoundaryPrompt,
        SeriesBoundaryPrompt.none,
      );
      expect(_state(container, _incognitoKey)?.currentIndex, 1);
      expect(navigation.switchedTo, isEmpty);
    });

    test('leaving first spread clears retreat prompt', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(readingMode: ReadingMode.paged),
        snapshot: _snapshot(pageCount: 5, resumePage: 1),
        seriesNavigation: _RecordingSeriesNavigation(),
        prefetch: _FakePrefetchController(),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);

      await controller.requestPrevPage(
        navContext: _navContext(previousComicId: previousComicId),
        session: session,
      );
      expect(
        _state(container, _incognitoKey)?.seriesBoundaryPrompt,
        SeriesBoundaryPrompt.retreat,
      );

      controller.nextPage();

      expect(
        _state(container, _incognitoKey)?.seriesBoundaryPrompt,
        SeriesBoundaryPrompt.none,
      );
      expect(_state(container, _incognitoKey)?.currentIndex, 2);
    });
  });

  group('advanceAutoPlay', () {
    const String nextComicId = 'next-series-comic';
    const OpenReaderArgs session = OpenReaderArgs(
      comicId: _comicId,
      incognito: true,
    );

    test('series loop on the last spread switches to the next comic without a prompt', () async {
      final _RecordingSeriesNavigation navigation =
          _RecordingSeriesNavigation();
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(
          readingMode: ReadingMode.paged,
          autoPlayMode: AutoPlayMode.seriesLoop,
        ),
        snapshot: _snapshot(pageCount: 5, resumePage: 5),
        seriesNavigation: navigation,
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);
      controller.setAutoPlayEnabled(true);

      final tick = await controller.advanceAutoPlay(
        navContext: _navContext(nextComicId: nextComicId),
        session: session,
      );

      expect(tick.keepTicking, isFalse);
      expect(tick.replace, isNotNull);
      expect(navigation.switchedTo, <String>[nextComicId]);
      expect(_state(container, _incognitoKey)?.currentIndex, 5);
      expect(_state(container, _incognitoKey)?.autoPlayEnabled, isTrue);
      expect(
        _state(container, _incognitoKey)?.seriesBoundaryPrompt,
        SeriesBoundaryPrompt.none,
      );
    });

    test('tick before the last spread advances one page', () async {
      final _RecordingSeriesNavigation navigation =
          _RecordingSeriesNavigation();
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(
          readingMode: ReadingMode.paged,
          autoPlayMode: AutoPlayMode.seriesLoop,
        ),
        snapshot: _snapshot(pageCount: 5, resumePage: 1),
        seriesNavigation: navigation,
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);
      controller.setAutoPlayEnabled(true);

      final tick = await controller.advanceAutoPlay(
        navContext: _navContext(nextComicId: nextComicId),
        session: session,
      );

      expect(tick.keepTicking, isTrue);
      expect(tick.replace, isNull);
      expect(_state(container, _incognitoKey)?.currentIndex, 2);
      expect(navigation.switchedTo, isEmpty);
    });

    test('comic once on the last spread stops autoplay and stays', () async {
      final _RecordingSeriesNavigation navigation =
          _RecordingSeriesNavigation();
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(
          readingMode: ReadingMode.paged,
          autoPlayMode: AutoPlayMode.comicOnce,
        ),
        snapshot: _snapshot(pageCount: 5, resumePage: 5),
        seriesNavigation: navigation,
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);
      controller.setAutoPlayEnabled(true);

      final tick = await controller.advanceAutoPlay(
        navContext: _navContext(nextComicId: nextComicId),
        session: session,
      );

      expect(tick.keepTicking, isFalse);
      expect(tick.replace, isNull);
      expect(_state(container, _incognitoKey)?.autoPlayEnabled, isFalse);
      expect(_state(container, _incognitoKey)?.currentIndex, 5);
      expect(navigation.switchedTo, isEmpty);
    });

    test('comic loop on the last spread jumps to the first page and keeps autoplay', () async {
      final ProviderContainer container = _createContainer(
        key: _incognitoKey,
        initialSetting: AppSetting(
          readingMode: ReadingMode.paged,
          autoPlayMode: AutoPlayMode.comicLoop,
        ),
        snapshot: _snapshot(pageCount: 5, resumePage: 5),
        seriesNavigation: _RecordingSeriesNavigation(),
      );
      addTearDown(container.dispose);

      await container.read(readerViewModelProvider(_incognitoKey).future);
      final ReaderViewModel controller = _controller(container, _incognitoKey);
      controller.setAutoPlayEnabled(true);

      final tick = await controller.advanceAutoPlay(
        navContext: _navContext(),
        session: session,
      );

      expect(tick.keepTicking, isTrue);
      expect(tick.replace, isNull);
      expect(_state(container, _incognitoKey)?.currentIndex, 1);
      expect(_state(container, _incognitoKey)?.autoPlayEnabled, isTrue);
    });
  });
}
