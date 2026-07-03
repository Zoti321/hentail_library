/// 首页仪表盘聚合统计（行数/记录数，非业务字段）。
class HomePageCounts {
  const HomePageCounts({
    required this.comicCount,
    required this.tagCount,
    required this.seriesCount,
    required this.readingRecordCount,
  });
  final int comicCount;
  final int tagCount;
  final int seriesCount;
  final int readingRecordCount;
}

/// 继续阅读单条候选项（从漫画阅读历史取 Top N）。
class HomeContinueReadingEntry {
  const HomeContinueReadingEntry({
    required this.comicId,
    required this.title,
    required this.lastReadTime,
    required this.pageIndex,
  });
  final String comicId;
  final String title;
  final DateTime lastReadTime;
  final int? pageIndex;
}
