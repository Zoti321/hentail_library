import 'dart:math' as math;

/// 根据滚动偏移估算当前可见（含缓冲行）的网格索引范围。
///
/// 纯计算函数，库页与首页历史网格共用（原位于 library_browse 视图模型，#262 迁出）。
({int startIndex, int endIndex}) visibleCatalogGridIndexRange({
  required double scrollPixels,
  required double viewportHeight,
  required double gridStartScrollOffset,
  required int itemCount,
  required double rowExtent,
  required double rowSpacing,
  required int crossAxisCount,
  int rowBuffer = 1,
}) {
  if (itemCount <= 0) {
    return (startIndex: 0, endIndex: -1);
  }
  final double relativeOffset = scrollPixels - gridStartScrollOffset;
  final double rowStride = rowExtent + rowSpacing;
  final int firstRow = relativeOffset <= 0
      ? 0
      : math.max(0, (relativeOffset / rowStride).floor() - rowBuffer);
  final int visibleRows =
      (viewportHeight / rowStride).ceil() + rowBuffer * 2 + 1;
  final int startIndex = math.min(itemCount - 1, firstRow * crossAxisCount);
  final int endIndex = math.min(
    itemCount - 1,
    ((firstRow + visibleRows) * crossAxisCount) - 1,
  );
  return (startIndex: startIndex, endIndex: math.max(startIndex, endIndex));
}
