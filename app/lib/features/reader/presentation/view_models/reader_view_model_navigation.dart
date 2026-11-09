part of 'reader_view_model.dart';

/// 系列边界提示与翻页命令（#307）：由 [ReaderViewModel] 以 mixin 组合。（自动播放见 reader_view_model_auto_play.dart）
mixin _ReaderViewModelNavigation on _$ReaderViewModel {
  void _notifyPageChanged(int pageIndex) {
    final ReaderViewModelKey key = ref.$arg as ReaderViewModelKey;
    if (key.incognito) {
      return;
    }
    ref.read(readSessionApplicationServiceProvider).updatePage(pageIndex);
  }

  void _updateDataState(ReaderUiState Function(ReaderUiState) updater) {
    final current = state.asData?.value;
    if (current == null) return;
    ReaderUiState next = updater(current);
    if (next.currentIndex != current.currentIndex) {
      next = _clearStaleBoundaryPrompt(next);
    }
    if (next.currentIndex != current.currentIndex) {
      _notifyPageChanged(next.currentIndex);
    }
    state = AsyncData(next);
  }

  /// Clears advance/retreat prompt once the user leaves that boundary spread.
  ReaderUiState _clearStaleBoundaryPrompt(ReaderUiState next) {
    switch (next.seriesBoundaryPrompt) {
      case SeriesBoundaryPrompt.none:
        return next;
      case SeriesBoundaryPrompt.advance:
        if (SpreadNavigation.isOnLastSpread(
          mode: next.readingMode,
          totalPages: next.totalPages,
          currentPageIndex: next.currentIndex,
        )) {
          return next;
        }
        return next.copyWith(seriesBoundaryPrompt: SeriesBoundaryPrompt.none);
      case SeriesBoundaryPrompt.retreat:
        if (SpreadNavigation.isOnFirstSpread(
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
      final int? next = SpreadNavigation.nextPrimaryPage(
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

  Future<ReaderReplaceReaderRouteIntent?> requestNextPage({
    ReaderNavContextData? navContext,
    OpenReaderArgs? session,
  }) async {
    final ReaderUiState? current = state.asData?.value;
    if (current == null) {
      return null;
    }
    return _requestSeriesBoundaryPage(
      onBoundary: SpreadNavigation.isOnLastSpread(
        mode: current.readingMode,
        totalPages: current.totalPages,
        currentPageIndex: current.currentIndex,
      ),
      prompt: SeriesBoundaryPrompt.advance,
      targetItem: navContext?.nextItem,
      session: session,
      turnPage: nextPage,
    );
  }

  void prevPage() {
    _updateDataState((s) {
      final int? prev = SpreadNavigation.previousPrimaryPage(
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

  Future<ReaderReplaceReaderRouteIntent?> requestPrevPage({
    ReaderNavContextData? navContext,
    OpenReaderArgs? session,
  }) async {
    final ReaderUiState? current = state.asData?.value;
    if (current == null) {
      return null;
    }
    return _requestSeriesBoundaryPage(
      onBoundary: SpreadNavigation.isOnFirstSpread(
        mode: current.readingMode,
        totalPages: current.totalPages,
        currentPageIndex: current.currentIndex,
      ),
      prompt: SeriesBoundaryPrompt.retreat,
      targetItem: navContext?.previousItem,
      session: session,
      turnPage: prevPage,
    );
  }

  Future<ReaderReplaceReaderRouteIntent?> _requestSeriesBoundaryPage({
    required bool onBoundary,
    required SeriesBoundaryPrompt prompt,
    required ReaderComicListItem? targetItem,
    required OpenReaderArgs? session,
    required void Function() turnPage,
  }) async {
    final ReaderUiState? current = state.asData?.value;
    if (current == null) {
      return null;
    }
    if (onBoundary && targetItem != null && session != null) {
      if (current.seriesBoundaryPrompt != prompt) {
        _updateDataState(
          (ReaderUiState s) => s.copyWith(seriesBoundaryPrompt: prompt),
        );
        try {
          await ref
              .read(readerPrefetchNotifierProvider.notifier)
              .warmOpenComic(comicId: targetItem.comicId);
        } catch (_) {
          // warm-open 失败不阻断提示。
        }
        return null;
      }
      _updateDataState(
        (ReaderUiState s) =>
            s.copyWith(seriesBoundaryPrompt: SeriesBoundaryPrompt.none),
      );
      return ref
          .read(readerSeriesNavigationProvider.notifier)
          .prepareSwitchComic(
            currentSession: session,
            targetComicId: targetItem.comicId,
          );
    }
    if (onBoundary) {
      return null;
    }
    turnPage();
    return null;
  }

  void setIndex(int index) {
    _updateDataState((s) {
      if (index < 1 || index > s.totalPages) return s;
      return s.copyWith(currentIndex: index);
    });
  }
}
