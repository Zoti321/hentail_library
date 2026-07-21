import 'package:hentai_library/domain/reading/reading_mode.dart';

const Duration kReaderPageCrossfadeDuration = Duration(milliseconds: 150);

const Duration kReaderPageTurnAnimationDuration = kReaderPageCrossfadeDuration;

/// Scroll layout 在 [WebtoonZoomMode.fitWidth] 下的内容区逻辑宽度。
///
/// [marginPercent] 为两侧合计占视口宽度的百分比（0–40），无隐式 clamp。
double readerContinuousSlotLogicalWidth(
  double viewportWidth, {
  int marginPercent = kDefaultWebtoonMarginPercent,
}) {
  final int normalized = normalizeWebtoonMarginPercent(marginPercent);
  return viewportWidth * (1 - normalized / 100);
}

/// 单页翻页模式下单页占满视口宽度。
double readerPagedSlotLogicalWidth(double viewportWidth) => viewportWidth;

/// 双页模式下单侧页槽逻辑宽度。
double readerDualPageSlotLogicalWidth(double viewportWidth) =>
    viewportWidth / 2;
