import 'dart:math' as math;

/// Panel layout: mirror [SeriesDetail] in
/// [series_detail.dart] (`_kContentWidthRatio`, `_kContentMaxWidth`, etc.).
const double kComicDetailContentWidthRatio = 0.8;
const double kComicDetailContentHeightRatio = 0.8;
const double kComicDetailContentMinWidth = 980;
const double kComicDetailContentMaxWidth = 1320;
const double kComicDetailContentMinHeight = 560;
const double kComicDetailContentMaxHeight = 920;
const int kComicDetailTagsCollapsedMaxCount = 8;

class ComicDetailPanelSize {
  const ComicDetailPanelSize({
    required this.targetWidth,
    required this.targetHeight,
    required this.panelWidth,
    required this.panelHeight,
  });
  final double targetWidth;
  final double targetHeight;
  final double panelWidth;
  final double panelHeight;
}

ComicDetailPanelSize computeComicDetailPanelSize({
  required double parentWidth,
  required double parentHeight,
}) {
  final double targetWidth = (parentWidth * kComicDetailContentWidthRatio)
      .clamp(kComicDetailContentMinWidth, kComicDetailContentMaxWidth)
      .toDouble();
  final double targetHeight = (parentHeight * kComicDetailContentHeightRatio)
      .clamp(kComicDetailContentMinHeight, kComicDetailContentMaxHeight)
      .toDouble();
  final double panelWidth = math.min(parentWidth, targetWidth);
  final double panelHeight = math.min(parentHeight, targetHeight);
  return ComicDetailPanelSize(
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    panelWidth: panelWidth,
    panelHeight: panelHeight,
  );
}
