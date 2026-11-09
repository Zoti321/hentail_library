/// Lab 阅读器水平点击分区（MD3 沉浸：左右约 20% 翻页，中间约 60% 呼出 chrome）。
enum ReaderViewportTapZone { left, center, right }

const double _kReaderEdgeTapFraction = 0.2;

ReaderViewportTapZone resolveReaderViewportTapZone({
  required double localX,
  required double width,
}) {
  if (width <= 0) {
    return ReaderViewportTapZone.center;
  }
  if (localX < width * _kReaderEdgeTapFraction) {
    return ReaderViewportTapZone.left;
  }
  if (localX > width * (1 - _kReaderEdgeTapFraction)) {
    return ReaderViewportTapZone.right;
  }
  return ReaderViewportTapZone.center;
}
