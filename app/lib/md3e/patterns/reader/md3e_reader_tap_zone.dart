/// Lab 阅读器水平点击分区（MD3 沉浸：左右约 20% 翻页，中间约 60% 呼出 chrome）。
enum Md3eReaderTapZone { left, center, right }

const double _kReaderEdgeTapFraction = 0.2;

Md3eReaderTapZone md3eResolveReaderTapZone({
  required double localX,
  required double width,
}) {
  if (width <= 0) {
    return Md3eReaderTapZone.center;
  }
  if (localX < width * _kReaderEdgeTapFraction) {
    return Md3eReaderTapZone.left;
  }
  if (localX > width * (1 - _kReaderEdgeTapFraction)) {
    return Md3eReaderTapZone.right;
  }
  return Md3eReaderTapZone.center;
}
