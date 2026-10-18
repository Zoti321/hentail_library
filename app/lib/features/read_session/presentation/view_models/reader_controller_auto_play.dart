part of 'reader_controller.dart';

/// 自动播放的开关与定时器推进决策（#313）：与翻页命令分离，由 [ReaderController] 组合。
mixin _ReaderControllerAutoPlay
    on _$ReaderController, _ReaderControllerNavigation {
  void setAutoPlayEnabled(bool value) {
    _updateDataState((ReaderState s) => s.copyWith(autoPlayEnabled: value));
  }

  /// 自动播放的一拍到了。定时器留在页面。
  ///
  /// 返回 false 时页面应取消定时器：自动播放已停止，或已开始切卷。
  Future<bool> advanceAutoPlay({
    required ReaderNavContextData? navContext,
    required ReadSessionRouteParams session,
    required GoRouter router,
  }) async {
    final ReaderState? current = state.asData?.value;
    if (current == null || !current.autoPlayEnabled) {
      return false;
    }
    if (!current.readingMode.supportsAutoPlay || current.totalPages <= 0) {
      return false;
    }
    final bool onLastSpread = SpreadIndex.isOnLastSpread(
      mode: current.readingMode,
      totalPages: current.totalPages,
      currentPageIndex: current.currentIndex,
    );
    if (!onLastSpread) {
      nextPage();
      return true;
    }
    final AutoPlayMode mode =
        ref.read(appSettingsStateProvider).asData?.value.autoPlayMode ??
        kDefaultAutoPlayMode;
    final List<ReaderComicListItem>? items = navContext?.items;
    final String? firstComicId = items != null && items.isNotEmpty
        ? items.first.comicId
        : null;
    final AutoPlayBoundaryDecision decision = resolveAutoPlayBoundary(
      mode: mode,
      currentComicId: session.comicId,
      nextComicId: navContext?.nextItem?.comicId,
      firstComicId: firstComicId,
    );
    switch (decision) {
      case AutoPlayBoundaryStop():
        setAutoPlayEnabled(false);
        return false;
      case AutoPlayBoundaryJumpToFirstPage():
        setIndex(1);
        return true;
      case AutoPlayBoundarySwitchComic(:final String comicId):
        await ref
            .read(readerSeriesNavigationProvider.notifier)
            .switchComic(
              router: router,
              currentSession: session,
              targetComicId: comicId,
            );
        return false;
    }
  }
}
