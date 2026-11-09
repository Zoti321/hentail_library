part of 'reader_controller.dart';

/// 系列边界提示与翻页命令（#307）：由 [ReaderController] 以 mixin 组合。（自动播放见 reader_controller_auto_play.dart）
mixin _ReaderControllerNavigation on _$ReaderController {
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
    if (next.currentIndex != current.currentIndex) {
      next = _clearStaleBoundaryPrompt(next);
    }
    if (next.currentIndex != current.currentIndex) {
      _notifyPageChanged(next.currentIndex);
    }
    state = AsyncData(next);
  }

  /// Clears advance/retreat prompt once the user leaves that boundary spread.
  ReaderState _clearStaleBoundaryPrompt(ReaderState next) {
    switch (next.seriesBoundaryPrompt) {
      case SeriesBoundaryPrompt.none:
        return next;
      case SeriesBoundaryPrompt.advance:
        if (SpreadIndex.isOnLastSpread(
          mode: next.readingMode,
          totalPages: next.totalPages,
          currentPageIndex: next.currentIndex,
        )) {
          return next;
        }
        return next.copyWith(seriesBoundaryPrompt: SeriesBoundaryPrompt.none);
      case SeriesBoundaryPrompt.retreat:
        if (SpreadIndex.isOnFirstSpread(
          mode: next.readingMode,
          totalPages: next.totalPages,
          currentPageIndex: next.currentIndex,
        )) {
          return next;
        }
        return next.copyWith(seriesBoundaryPrompt: SeriesBoundaryPrompt.none);
    }
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
    await _requestSeriesBoundaryPage(
      onBoundary: SpreadIndex.isOnLastSpread(
        mode: current.readingMode,
        totalPages: current.totalPages,
        currentPageIndex: current.currentIndex,
      ),
      prompt: SeriesBoundaryPrompt.advance,
      targetItem: navContext?.nextItem,
      session: session,
      router: router,
      turnPage: nextPage,
    );
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

  Future<void> requestPrevPage({
    ReaderNavContextData? navContext,
    ReadSessionRouteParams? session,
    GoRouter? router,
  }) async {
    final ReaderState? current = state.asData?.value;
    if (current == null) {
      return;
    }
    await _requestSeriesBoundaryPage(
      onBoundary: SpreadIndex.isOnFirstSpread(
        mode: current.readingMode,
        totalPages: current.totalPages,
        currentPageIndex: current.currentIndex,
      ),
      prompt: SeriesBoundaryPrompt.retreat,
      targetItem: navContext?.previousItem,
      session: session,
      router: router,
      turnPage: prevPage,
    );
  }

  Future<void> _requestSeriesBoundaryPage({
    required bool onBoundary,
    required SeriesBoundaryPrompt prompt,
    required ReaderComicListItem? targetItem,
    required ReadSessionRouteParams? session,
    required GoRouter? router,
    required void Function() turnPage,
  }) async {
    final ReaderState? current = state.asData?.value;
    if (current == null) {
      return;
    }
    if (onBoundary && targetItem != null && session != null && router != null) {
      if (current.seriesBoundaryPrompt != prompt) {
        _updateDataState(
          (ReaderState s) => s.copyWith(seriesBoundaryPrompt: prompt),
        );
        try {
          await ref
              .read(readerPrefetchControllerProvider.notifier)
              .warmOpenComic(comicId: targetItem.comicId);
        } catch (_) {
          // warm-open 失败不阻断提示。
        }
        return;
      }
      _updateDataState(
        (ReaderState s) =>
            s.copyWith(seriesBoundaryPrompt: SeriesBoundaryPrompt.none),
      );
      await ref
          .read(readerSeriesNavigationProvider.notifier)
          .switchComic(
            router: router,
            currentSession: session,
            targetComicId: targetItem.comicId,
          );
      return;
    }
    if (onBoundary) {
      return;
    }
    turnPage();
  }

  void setIndex(int index) {
    _updateDataState((s) {
      if (index < 1 || index > s.totalPages) return s;
      return s.copyWith(currentIndex: index);
    });
  }
}
