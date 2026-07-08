import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/domain/reading/reader_session_snapshot.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/domain/reading/spread_index.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_prefetch_controller.dart';
import 'package:hentai_library/ui/features/reader/module/session/reader_session_bindings.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_series_navigation.dart';
import 'package:hentai_library/ui/features/reader/module/controller/reader_fullscreen_controller.dart';
import 'package:hentai_library/ui/features/reader/reader_exit_location.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/reader/views/reader_page/widgets/reader_route_context.dart';
import 'package:hentai_library/domain/reading/read_session_coordinator.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_controller.freezed.dart';
part 'reader_controller.g.dart';

enum ReaderTapZone { left, center, right }

typedef ReaderControllerKey = ({String comicId, bool incognito});

ReaderControllerKey readerControllerKey(
  String comicId, {
  bool incognito = false,
}) => (comicId: comicId, incognito: incognito);

@freezed
abstract class ReaderState with _$ReaderState {
  factory ReaderState({
    required Comic comic,
    @Default(ReadingMode.paged) ReadingMode readingMode,
    @Default(false) bool showControls,
    @Default(1) int currentIndex,
    int? totalPagesOverride,
    @Default(false) bool seriesAdvancePromptPending,
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
  bool get isSeriesRead => sessionContext.isSeriesRead;
  String? get seriesId => sessionContext.seriesId;
}

@riverpod
AsyncValue<ReaderPageViewModel> readerPageViewModel(
  Ref ref, {
  required String comicId,
  String? seriesId,
  bool incognito = false,
}) {
  final AsyncValue<ReaderState> viewAsync = ref.watch(
    readerControllerProvider(
      readerControllerKey(comicId, incognito: incognito),
    ),
  );
  final AsyncValue<ReadSessionContextData> sessionContextAsync = ref.watch(
    readSessionContextForReaderProvider(
      comicId: comicId,
      seriesId: seriesId,
      incognito: incognito,
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
class ReaderController extends _$ReaderController {
  @override
  Future<ReaderState> build(ReaderControllerKey key) async {
    final String id = key.comicId;
    final bool incognito = key.incognito;
    final ReaderSessionSnapshot snapshot = await ref.watch(
      readerSessionOpenProvider(comicId: id, incognito: incognito).future,
    );
    return ReaderState(
      comic: snapshot.comic,
      currentIndex: snapshot.resumePageIndex,
      totalPagesOverride: snapshot.totalPages > 0 ? snapshot.totalPages : null,
    );
  }

  String get _comicId => (ref.$arg as ReaderControllerKey).comicId;

  void _notifyPageChanged(int pageIndex) {
    final ReaderControllerKey key = ref.$arg as ReaderControllerKey;
    if (key.incognito) {
      return;
    }
    ref.read(readSessionCoordinatorProvider).updatePage(pageIndex);
  }

  void _updateDataState(ReaderState Function(ReaderState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    ReaderState next = updater(current);
    if (next.currentIndex != current.currentIndex &&
        next.seriesAdvancePromptPending &&
        !SpreadIndex.isOnLastSpread(
          mode: next.readingMode,
          totalPages: next.totalPages,
          currentPageIndex: next.currentIndex,
        )) {
      next = next.copyWith(seriesAdvancePromptPending: false);
    }
    if (next.currentIndex != current.currentIndex) {
      _notifyPageChanged(next.currentIndex);
    }
    state = AsyncData(next);
  }

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
      return s.copyWith(readingMode: value, currentIndex: remappedIndex);
    });
  }

  void nextPage() {
    _updateDataState((s) {
      final int? next = SpreadIndex.nextPrimaryPage(
        mode: s.readingMode,
        totalPages: s.totalPages,
        currentPageIndex: s.currentIndex,
      );
      if (next == null) {
        return s;
      }
      return s.copyWith(currentIndex: next);
    });
  }

  Future<void> requestNextPage({
    ReaderNavContextData? navContext,
    ReadSessionRouteParams? session,
    GoRouter? router,
  }) async {
    final ReaderState? current = state.asData?.value;
    if (current == null) {
      return;
    }
    final bool onLastSpread = SpreadIndex.isOnLastSpread(
      mode: current.readingMode,
      totalPages: current.totalPages,
      currentPageIndex: current.currentIndex,
    );
    final ReaderComicListItem? nextItem = navContext?.nextItem;
    if (onLastSpread && nextItem != null && session != null && router != null) {
      if (!current.seriesAdvancePromptPending) {
        _updateDataState(
          (ReaderState s) => s.copyWith(seriesAdvancePromptPending: true),
        );
        try {
          await ref
              .read(readerPrefetchControllerProvider.notifier)
              .warmOpenComic(comicId: nextItem.comicId);
        } catch (_) {
          // warm-open 失败不阻断提示。
        }
        return;
      }
      _updateDataState(
        (ReaderState s) => s.copyWith(seriesAdvancePromptPending: false),
      );
      await ref
          .read(readerSeriesNavigationProvider.notifier)
          .switchComic(
            router: router,
            currentSession: session,
            targetComicId: nextItem.comicId,
          );
      return;
    }
    if (onLastSpread) {
      return;
    }
    nextPage();
  }

  void prevPage() {
    _updateDataState((s) {
      final int? prev = SpreadIndex.previousPrimaryPage(
        mode: s.readingMode,
        totalPages: s.totalPages,
        currentPageIndex: s.currentIndex,
      );
      if (prev == null) {
        return s;
      }
      return s.copyWith(currentIndex: prev);
    });
  }

  void setIndex(int index) {
    _updateDataState((s) {
      if (index < 1 || index > s.totalPages) return s;
      return s.copyWith(currentIndex: index);
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
      prevPage();
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
    if (routeContext.isSeriesRead) {
      router.go(
        resolveReaderExitLocation(
          comicId: routeContext.comicId,
          seriesId: routeContext.seriesId,
        ),
      );
      return;
    }
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(resolveReaderExitLocation(comicId: routeContext.comicId));
  }
}
