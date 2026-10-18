import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_fullscreen_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_page_facade.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/series_reader_provider.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_route_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const String _comicId = 'facade-comic';
const ReaderControllerKey _viewKey = (
  comicId: _comicId,
  incognito: false,
  startFromFirstPage: false,
);

Comic _comic({String title = 'Facade'}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: _comicId,
    path: '/tmp/facade.cbz',
    resourceType: ResourceType.cbz,
    resourceSize: 1,
    createdAt: now,
    lastUpdatedAt: now,
    title: title,
    pageCount: 10,
  );
}

ReadSessionContextData _sessionContext() => ReadSessionContextData(
  seriesId: null,
  navContext: const ReaderNavContextData(
    items: <ReaderComicListItem>[],
    currentIndex: -1,
    preferredPageIndex: null,
  ),
  preferredPageIndex: null,
);

ProviderContainer _container({String title = 'Facade'}) {
  return ProviderContainer(
    overrides: <Override>[
      readerControllerProvider(
        _viewKey,
      ).overrideWith(() => _StubReaderController(title)),
      readSessionContextForReaderProvider(
        comicId: _comicId,
      ).overrideWith((Ref ref) async => _sessionContext()),
      readerFullscreenControllerProvider.overrideWith(
        _FakeReaderFullscreenController.new,
      ),
    ],
  );
}

void main() {
  test('aggregates shell, session, fullscreen and boundary prompt', () async {
    final ProviderContainer container = _container(title: 'Shell');
    addTearDown(container.dispose);
    await container.read(readerControllerProvider(_viewKey).future);
    await container.read(
      readSessionContextForReaderProvider(comicId: _comicId).future,
    );

    final ReaderPageFacadeState facade = container.read(
      readerPageFacadeProvider(comicId: _comicId),
    );

    expect(facade.viewKey, _viewKey);
    expect(facade.readerFullscreen, isFalse);
    expect(facade.seriesBoundaryPrompt, SeriesBoundaryPrompt.none);
    final ReaderPageShellData shell = facade.shellAsync.requireValue;
    expect(shell.comic.title, 'Shell');
    expect(shell.totalPages, 10);
    expect(shell.sessionContext.hasSeriesContext, isFalse);
  });

  test('page turns (currentIndex) do not notify facade listeners', () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);
    await container.read(readerControllerProvider(_viewKey).future);
    await container.read(
      readSessionContextForReaderProvider(comicId: _comicId).future,
    );

    int notifications = 0;
    container.listen(readerPageFacadeProvider(comicId: _comicId), (
      ReaderPageFacadeState? previous,
      ReaderPageFacadeState next,
    ) {
      notifications++;
    });

    final _StubReaderController controller =
        container.read(readerControllerProvider(_viewKey).notifier)
            as _StubReaderController;
    controller.turnTo(5);
    controller.turnTo(7);
    // Riverpod 3 通知监听者为异步调度，需先让出事件循环再断言。
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });

  test('comic metadata change notifies facade listeners', () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);
    await container.read(readerControllerProvider(_viewKey).future);
    await container.read(
      readSessionContextForReaderProvider(comicId: _comicId).future,
    );

    int notifications = 0;
    container.listen(readerPageFacadeProvider(comicId: _comicId), (
      ReaderPageFacadeState? previous,
      ReaderPageFacadeState next,
    ) {
      notifications++;
    });

    final _StubReaderController controller =
        container.read(readerControllerProvider(_viewKey).notifier)
            as _StubReaderController;
    controller.replaceComicTitle('Renamed');
    await Future<void>.delayed(Duration.zero);

    expect(notifications, greaterThan(0));
    expect(
      container
          .read(readerPageFacadeProvider(comicId: _comicId))
          .shellAsync
          .requireValue
          .comic
          .title,
      'Renamed',
    );
  });
  test(
    'fullscreen and series boundary prompt flow through the facade',
    () async {
      final ProviderContainer container = _container();
      addTearDown(container.dispose);
      await container.read(readerControllerProvider(_viewKey).future);
      await container.read(
        readSessionContextForReaderProvider(comicId: _comicId).future,
      );

      int notifications = 0;
      container.listen(readerPageFacadeProvider(comicId: _comicId), (
        ReaderPageFacadeState? previous,
        ReaderPageFacadeState next,
      ) {
        notifications++;
      });

      (container.read(readerFullscreenControllerProvider.notifier)
              as _FakeReaderFullscreenController)
          .set(true);
      (container.read(readerControllerProvider(_viewKey).notifier)
              as _StubReaderController)
          .setSeriesBoundaryPrompt(SeriesBoundaryPrompt.advance);
      await Future<void>.delayed(Duration.zero);

      final ReaderPageFacadeState facade = container.read(
        readerPageFacadeProvider(comicId: _comicId),
      );
      expect(facade.readerFullscreen, isTrue);
      expect(facade.seriesBoundaryPrompt, SeriesBoundaryPrompt.advance);
      expect(notifications, greaterThan(0));
    },
  );
}

class _StubReaderController extends ReaderController {
  _StubReaderController(this._title);

  final String _title;

  @override
  Future<ReaderState> build(ReaderControllerKey key) async {
    return ReaderState(
      comic: _comic(title: _title),
      readingMode: ReadingMode.paged,
      currentIndex: 1,
      totalPagesOverride: 10,
    );
  }

  void turnTo(int index) {
    state = AsyncData(state.requireValue.copyWith(currentIndex: index));
  }

  void setSeriesBoundaryPrompt(SeriesBoundaryPrompt prompt) {
    state = AsyncData(
      state.requireValue.copyWith(seriesBoundaryPrompt: prompt),
    );
  }

  void replaceComicTitle(String title) {
    state = AsyncData(state.requireValue.copyWith(comic: _comic(title: title)));
  }
}

class _FakeReaderFullscreenController extends ReaderFullscreenController {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
