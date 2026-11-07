/// 历史列表行：1 基当前页（与阅读器 [pageIndex] 一致）。
int historyListCurrentPage(int? pageIndex) {
  if (pageIndex == null || pageIndex <= 0) {
    return 1;
  }
  return pageIndex;
}

/// 总页数优先用 Comic 编目页数；缺失时回退为 [currentPage] 以满足进度条约束。
int historyListTotalPages({required int? pageCount, required int currentPage}) {
  if (pageCount != null && pageCount > 0) {
    return pageCount;
  }
  return currentPage > 0 ? currentPage : 1;
}
