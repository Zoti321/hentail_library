import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_boundary.dart';
import 'package:hentai_library/features/read_session/domain/read_session.dart';
import 'package:hentai_library/features/read_session/domain/spread_index.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hentai_library/features/read_session/domain/reader_session_snapshot.dart';
import 'package:hentai_library/features/read_session/domain/reader_tap_zone.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_auto_play_carry.dart';
import 'package:hentai_library/features/read_session/presentation/reader_exit_location.dart';
import 'package:hentai_library/features/read_session/presentation/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/features/read_session/domain/read_session_coordinator.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/features/read_session/di/session_providers.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_fullscreen_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_prefetch_controller.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/reader_series_navigation.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/read_session_providers.dart';
import 'package:hentai_library/features/read_session/presentation/view_models/series_reader_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_controller.freezed.dart';
part 'reader_controller.g.dart';
part 'reader_controller_navigation.dart';
part 'reader_controller_auto_play.dart';

/// 翻页越界切卷的二次确认方向（末页→下一卷 / 首页→上一卷）。
enum SeriesBoundaryPrompt { none, advance, retreat }

typedef ReaderControllerKey = ({
  String comicId,
  bool incognito,
  bool startFromFirstPage,
});

ReaderControllerKey readerControllerKey(
  String comicId, {
  bool incognito = false,
  bool startFromFirstPage = false,
}) => (
  comicId: comicId,
  incognito: incognito,
  startFromFirstPage: startFromFirstPage,
);

@freezed
abstract class ReaderState with _$ReaderState {
  factory ReaderState({
    required Comic comic,
    @Default(ReadingMode.paged) ReadingMode readingMode,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
    @Default(SeriesBoundaryPrompt.none)
    SeriesBoundaryPrompt seriesBoundaryPrompt,
    @Default(false) bool autoPlayEnabled,
  }) = _ReaderState;

  ReaderState._();

  int get totalPages => totalPagesOverride ?? 0;
}

class ReaderPageViewModel {
  const ReaderPageViewModel({
    required this.viewState,
    required this.sessionContext,
  });
  final ReaderState viewState;
  final ReadSessionContextData sessionContext;

  ReaderNavContextData get navContext => sessionContext.navContext;
  int? get preferredPageIndex => sessionContext.preferredPageIndex;
  bool get hasSeriesContext => sessionContext.hasSeriesContext;
  String? get seriesId => sessionContext.seriesId;
}

@riverpod
AsyncValue<ReaderPageViewModel> readerPageViewModel(
  Ref ref, {
  required String comicId,
  bool incognito = false,
  bool startFromFirstPage = false,
}) {
  final AsyncValue<ReaderState> viewAsync = ref.watch(
    readerControllerProvider(
      readerControllerKey(
        comicId,
        incognito: incognito,
        startFromFirstPage: startFromFirstPage,
      ),
    ),
  );
  final AsyncValue<ReadSessionContextData> sessionContextAsync = ref.watch(
    readSessionContextForReaderProvider(
      comicId: comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    ),
  );
  if (viewAsync.hasError) {
    return AsyncError(viewAsync.error!, viewAsync.stackTrace!);
  }
  if (sessionContextAsync.hasError) {
    return AsyncError(
      sessionContextAsync.error!,
      sessionContextAsync.stackTrace!,
    );
  }
  final ReaderState? viewState = viewAsync.asData?.value;
  final ReadSessionContextData? sessionContext =
      sessionContextAsync.asData?.value;
  if (viewState == null || sessionContext == null) {
    return const AsyncLoading();
  }
  return AsyncData(
    ReaderPageViewModel(viewState: viewState, sessionContext: sessionContext),
  );
}

@riverpod
class ReaderController extends _$ReaderController
    with _ReaderControllerNavigation, _ReaderControllerAutoPlay {
  @override
  Future<ReaderState> build(ReaderControllerKey key) async {
    final String id = key.comicId;
    final bool incognito = key.incognito;
    final bool startFromFirstPage = key.startFromFirstPage;
    final ReaderSessionSnapshot snapshot = await ref.watch(
      readerSessionOpenProvider(
        comicId: id,
        incognito: incognito,
        startFromFirstPage: startFromFirstPage,
      ).future,
    );
    final ReadingMode initialMode = await _resolveInitialReadingMode();
    ref.listen<AsyncValue<AppSetting>>(appSettingsStateProvider, (
      AsyncValue<AppSetting>? previous,
      AsyncValue<AppSetting> next,
    ) {
      final ReadingMode? mode = next.asData?.value.readingMode;
      if (mode == null) {
        return;
      }
      setReadingMode(mode);
    });
    final bool carryAutoPlay = ref
        .read(readerAutoPlayCarryProvider.notifier)
        .take();
    return ReaderState(
      comic: snapshot.comic,
      readingMode: initialMode,
      currentIndex: snapshot.resumePageIndex,
      totalPagesOverride: snapshot.totalPages > 0 ? snapshot.totalPages : null,
      autoPlayEnabled: carryAutoPlay && initialMode.supportsAutoPlay,
    );
  }

  Future<ReadingMode> _resolveInitialReadingMode() async {
    final AppSetting? ready = ref.read(appSettingsStateProvider).asData?.value;
    if (ready != null) {
      return ready.readingMode;
    }
    try {
      return (await ref.read(appSettingsFutureProvider.future)).readingMode;
    } catch (_) {
      return kDefaultReadingMode;
    }
  }

  String get _comicId => (ref.$arg as ReaderControllerKey).comicId;

  void toggleShowControls() {
    _updateDataState((s) => s.copyWith(showControls: !s.showControls));
  }

  void setShowControls(bool value) {
    _updateDataState((s) => s.copyWith(showControls: value));
  }

  void setReadingMode(ReadingMode value) {
    _updateDataState((ReaderState s) {
      if (s.readingMode == value) {
        return s;
      }
      final int remappedIndex = SpreadIndex.remapPageForModeSwitch(
        fromMode: s.readingMode,
        toMode: value,
        currentPageIndex: s.currentIndex,
        totalPages: s.totalPages,
      );
      return s.copyWith(
        readingMode: value,
        currentIndex: remappedIndex,
        autoPlayEnabled: value.supportsAutoPlay ? s.autoPlayEnabled : false,
      );
    });
  }

  void setTotalPagesOverride(int? value) {
    _updateDataState((s) => s.copyWith(totalPagesOverride: value));
  }

  Future<void> handleTapZone(
    ReaderTapZone zone, {
    ReaderNavContextData? navContext,
    ReadSessionRouteParams? session,
    GoRouter? router,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;
    if (current.showControls) {
      toggleShowControls();
      return;
    }
    if (current.readingMode.isWebtoon) {
      toggleShowControls();
      return;
    }
    await _handleHorizontalTap(
      zone,
      navContext: navContext,
      session: session,
      router: router,
    );
  }

  Future<void> _handleHorizontalTap(
    ReaderTapZone zone, {
    ReaderNavContextData? navContext,
    ReadSessionRouteParams? session,
    GoRouter? router,
  }) async {
    if (zone == ReaderTapZone.left) {
      await requestPrevPage(
        navContext: navContext,
        session: session,
        router: router,
      );
    } else if (zone == ReaderTapZone.right) {
      await requestNextPage(
        navContext: navContext,
        session: session,
        router: router,
      );
    } else {
      toggleShowControls();
    }
  }

  Future<void> toggleFullscreen() async {
    await ref
        .read(readerFullscreenControllerProvider.notifier)
        .toggleFullscreen();
  }

  Future<void> executeSaveProgress({
    required ReaderRouteContext routeContext,
  }) async {
    if (routeContext.incognito) {
      return;
    }
    final ReaderState? currentState = state.asData?.value;
    final ReadSessionCoordinator coordinator = ref.read(
      readSessionCoordinatorProvider,
    );
    if (currentState != null) {
      coordinator.updatePage(currentState.currentIndex);
    }
    await coordinator.flushProgress();
  }

  Future<void> executeExitReader({
    required BuildContext context,
    required ReaderRouteContext routeContext,
  }) async {
    await ref
        .read(readerFullscreenControllerProvider.notifier)
        .exitFullscreenIfNeeded();
    final ReaderState? currentState = state.asData?.value;
    await ref
        .read(readSessionCoordinatorProvider)
        .exitReadSession(
          comicId: _comicId,
          incognito: routeContext.incognito,
          currentPageIndex: currentState?.currentIndex,
        );
    ref.read(readerPrefetchControllerProvider.notifier).clearComic(_comicId);
    if (!context.mounted) {
      return;
    }
    final GoRouter router = GoRouter.of(context);
    router.go(resolveReaderExitLocation(comicId: routeContext.comicId));
  }
}
