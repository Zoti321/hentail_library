const Duration kReaderPageCrossfadeDuration = Duration(milliseconds: 150);

const Duration kReaderPageTurnAnimationDuration = kReaderPageCrossfadeDuration;

/// 长条阅读单页内容区最大逻辑宽度（与 [ContinuousVerticalViewport] 一致）。
double readerContinuousSlotLogicalWidth(double viewportWidth) {
  return (viewportWidth * 0.8).clamp(480.0, 1600.0).toDouble();
}

/// 单页翻页模式下单页占满视口宽度。
double readerPagedSlotLogicalWidth(double viewportWidth) => viewportWidth;

/// 双页模式下单侧页槽逻辑宽度。
double readerDualPageSlotLogicalWidth(double viewportWidth) =>
    viewportWidth / 2;
