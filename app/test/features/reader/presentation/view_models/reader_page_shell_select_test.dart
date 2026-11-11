import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_chrome_notifier.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_page_shell.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/view_models/series_reader_provider.dart';
import 'package:hentai_library/features/reader/presentation/routing/reader_route_context.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const String _comicId = 'shell-select-comic';
const ReaderViewModelKey _viewKey = (
  comicId: _comicId,
  incognito: false,
  startFromFirstPage: false,
);

ReaderComicRef _comic({String title = 'Shell'}) {
  return ReaderComicRef(
    comicId: _comicId,
    path: '/tmp/shell.cbz',
    resourceType: ResourceType.cbz,
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

ProviderContainer _container({String title = 'Shell'}) {
  return ProviderContainer(
    overrides: <Override>[
      readerViewModelProvider(_viewKey)
          .overrideWith(() => _StubReaderViewModel(title)),
      readSessionContextForReaderProvider(comicId: _comicId)
          .overrideWith((Ref ref) async => _sessionContext()),
      readerChromeNotifierProvider.overrideWith(_FakeReaderChromeNotifier.new),
    ],
  );
}

AsyncValue<ReaderPageViewShell> _watchViewShell(ProviderContainer container) {
  return container.read(
    readerViewModelProvider(_viewKey)
        .select((AsyncValue<ReaderUiState> asyncState) {
          if (asyncState.hasError) {
            return AsyncError<ReaderPageViewShell>(
              asyncState.error!,
              asyncState.stackTrace!,
            );
          }
          final ReaderUiState? state = asyncState.asData?.value;
          if (state == null) {
            return const AsyncLoading<ReaderPageViewShell>();
          }
          return AsyncData<ReaderPageViewShell>((
            comic: state.comic,
            totalPages: state.totalPages,
          ));
        }),
  );
}

void main() {
  test('combines view shell and session context', () async {
    final ProviderContainer container = _container(title: 'Ready');
    addTearDown(container.dispose);
    await container.read(readerViewModelProvider(_viewKey).future);
    await container.read(
      readSessionContextForReaderProvider(comicId: _comicId).future,
    );

    final AsyncValue<ReaderPageShellData> shellAsync = combineReaderPageShell(
      _watchViewShell(container),
      container.read(readSessionContextForReaderProvider(comicId: _comicId)),
    );
    final ReaderPageShellData shell = shellAsync.requireValue;
    expect(shell.comic.title, 'Ready');
    expect(shell.totalPages, 10);
    expect(shell.sessionContext.hasSeriesContext, isFalse);
    expect(container.read(readerChromeNotifierProvider), isFalse);
    expect(
      container.read(
        readerViewModelProvider(_viewKey).select(
          (AsyncValue<ReaderUiState> s) =>
              s.asData?.value.seriesBoundaryPrompt ?? SeriesBoundaryPrompt.none,
        ),
      ),
      SeriesBoundaryPrompt.none,
    );
  });

  test('page turns do not notify shell-select listeners', () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);
    await container.read(readerViewModelProvider(_viewKey).future);

    int notifications = 0;
    container.listen(
      readerViewModelProvider(_viewKey)
          .select((AsyncValue<ReaderUiState> asyncState) {
            final ReaderUiState? state = asyncState.asData?.value;
            if (state == null) {
              return null;
            }
            return (comicId: state.comic.comicId, totalPages: state.totalPages);
          }),
      (previous, next) {
        notifications++;
      },
    );

    final _StubReaderViewModel viewModel = container.read(
      readerViewModelProvider(_viewKey).notifier,
    ) as _StubReaderViewModel;
    viewModel.turnTo(5);
    viewModel.turnTo(7);
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 0);
  });

  test('comic metadata change notifies shell-select listeners', () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);
    await container.read(readerViewModelProvider(_viewKey).future);

    int notifications = 0;
    container.listen(
      readerViewModelProvider(_viewKey)
          .select((AsyncValue<ReaderUiState> asyncState) {
            final ReaderUiState? state = asyncState.asData?.value;
            if (state == null) {
              return null;
            }
            return (title: state.comic.title, totalPages: state.totalPages);
          }),
      (previous, next) {
        notifications++;
      },
    );

    final _StubReaderViewModel viewModel = container.read(
      readerViewModelProvider(_viewKey).notifier,
    ) as _StubReaderViewModel;
    viewModel.replaceComicTitle('Renamed');
    await Future<void>.delayed(Duration.zero);

    expect(notifications, greaterThan(0));
    expect(_watchViewShell(container).requireValue.comic.title, 'Renamed');
  });

  test('fullscreen and boundary prompt are orthogonal selects', () async {
    final ProviderContainer container = _container();
    addTearDown(container.dispose);
    await container.read(readerViewModelProvider(_viewKey).future);

    int chromeNotifications = 0;
    int promptNotifications = 0;
    container.listen(readerChromeNotifierProvider, (previous, next) {
      chromeNotifications++;
    });
    container.listen(
      readerViewModelProvider(_viewKey).select(
        (AsyncValue<ReaderUiState> s) =>
            s.asData?.value.seriesBoundaryPrompt ?? SeriesBoundaryPrompt.none,
      ),
      (previous, next) {
        promptNotifications++;
      },
    );

    (container.read(
      readerChromeNotifierProvider.notifier,
    ) as _FakeReaderChromeNotifier).set(true);
    (container.read(readerViewModelProvider(_viewKey).notifier)
            as _StubReaderViewModel)
        .setSeriesBoundaryPrompt(SeriesBoundaryPrompt.advance);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(readerChromeNotifierProvider), isTrue);
    expect(
      container.read(
        readerViewModelProvider(_viewKey).select(
          (AsyncValue<ReaderUiState> s) =>
              s.asData?.value.seriesBoundaryPrompt ?? SeriesBoundaryPrompt.none,
        ),
      ),
      SeriesBoundaryPrompt.advance,
    );
    expect(chromeNotifications, greaterThan(0));
    expect(promptNotifications, greaterThan(0));
  });
}

class _StubReaderViewModel extends ReaderViewModel {
  _StubReaderViewModel(this._title);

  final String _title;

  @override
  Future<ReaderUiState> build(ReaderViewModelKey key) async {
    return ReaderUiState(
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

class _FakeReaderChromeNotifier extends ReaderChromeNotifier {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
