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

/// 继续阅读单条候选项（从阅读历史与系列阅读表合并、按时间取 Top N）。
enum HomeContinueReadingKind { comic, series }

class HomeContinueReadingEntry {
  const HomeContinueReadingEntry.comic({
    required this.comicId,
    required this.title,
    required this.lastReadTime,
    required this.pageIndex,
  })  : kind = HomeContinueReadingKind.comic,
        seriesName = null,
        lastReadComicId = null;
  const HomeContinueReadingEntry.series({
    required this.seriesName,
    required this.lastReadComicId,
    required this.lastReadTime,
    required this.pageIndex,
  })  : kind = HomeContinueReadingKind.series,
        comicId = null,
        title = null;
  final HomeContinueReadingKind kind;
  final String? comicId;
  final String? title;
  final String? seriesName;
  final String? lastReadComicId;
  final DateTime lastReadTime;
  final int? pageIndex;
}
