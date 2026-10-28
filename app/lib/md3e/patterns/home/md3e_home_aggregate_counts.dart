/// Lab 首页全库聚合统计（预览 / 将来接 [HomePageCounts] 扩展字段）。
class Md3eHomeAggregateCounts {
  const Md3eHomeAggregateCounts({
    required this.comicCount,
    required this.seriesCount,
    required this.authorCount,
    required this.parodyCount,
    required this.characterCount,
    required this.tagCount,
  });

  final int comicCount;
  final int seriesCount;
  final int authorCount;
  final int parodyCount;
  final int characterCount;
  final int tagCount;
}
