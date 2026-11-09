part of 'reader_view_model.dart';

/// 自动播放的开关与定时器推进决策（#313）：与翻页命令分离，由 [ReaderViewModel] 组合。
mixin _ReaderViewModelAutoPlay
    on _$ReaderViewModel, _ReaderViewModelNavigation {
  void setAutoPlayEnabled(bool value) {
    _updateDataState((ReaderUiState s) => s.copyWith(autoPlayEnabled: value));
  }

  /// 自动播放的一拍到了。定时器留在页面。
  ///
  /// `keepTicking == false` 时页面应取消定时器：已停止或已发出切卷意图。
  Future<({bool keepTicking, ReaderReplaceReaderRouteIntent? replace})>
  advanceAutoPlay({
    required ReaderNavContextData? navContext,
    required OpenReaderArgs session,
  }) async {
    final ReaderUiState? current = state.asData?.value;
    if (current == null || !current.autoPlayEnabled) {
      return (keepTicking: false, replace: null);
    }
    if (!current.readingMode.supportsAutoPlay || current.totalPages <= 0) {
      return (keepTicking: false, replace: null);
    }
    final bool onLastSpread = SpreadNavigation.isOnLastSpread(
      mode: current.readingMode,
      totalPages: current.totalPages,
      currentPageIndex: current.currentIndex,
    );
    if (!onLastSpread) {
      nextPage();
      return (keepTicking: true, replace: null);
    }
    final AutoPlayMode mode =
        ref.read(appSettingsStateProvider).asData?.value.autoPlayMode ??
        kDefaultAutoPlayMode;
    final List<ReaderComicListItem>? items = navContext?.items;
    final String? firstComicId = items != null && items.isNotEmpty
        ? items.first.comicId
        : null;
    final AutoPlayBoundaryDecision decision = AutoPlayBoundaryPolicy.resolve(
      mode: mode,
      currentComicId: session.comicId,
      nextComicId: navContext?.nextItem?.comicId,
      firstComicId: firstComicId,
    );
    switch (decision) {
      case AutoPlayBoundaryStop():
        setAutoPlayEnabled(false);
        return (keepTicking: false, replace: null);
      case AutoPlayBoundaryJumpToFirstPage():
        setIndex(1);
        return (keepTicking: true, replace: null);
      case AutoPlayBoundarySwitchComic(:final String comicId):
        final ReaderReplaceReaderRouteIntent? replace = await ref
            .read(readerSeriesNavigationProvider.notifier)
            .prepareSwitchComic(
              currentSession: session,
              targetComicId: comicId,
            );
        return (keepTicking: false, replace: replace);
    }
  }
}
