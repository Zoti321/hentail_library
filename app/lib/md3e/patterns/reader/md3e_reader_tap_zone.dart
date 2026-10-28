/// Lab 阅读器水平点击分区（与生产 [resolveReaderTapZone] 比例一致，不依赖 read_session）。
enum Md3eReaderTapZone { left, center, right }

Md3eReaderTapZone md3eResolveReaderTapZone({
  required double localX,
  required double width,
}) {
  if (width <= 0) {
    return Md3eReaderTapZone.center;
  }
  if (localX < width * 0.3) {
    return Md3eReaderTapZone.left;
  }
  if (localX > width * 0.7) {
    return Md3eReaderTapZone.right;
  }
  return Md3eReaderTapZone.center;
}
