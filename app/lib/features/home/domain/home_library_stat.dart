/// 首页 / 库管理面板共用的每库统计读模型（漫画数、系列数、上次成功同步）。
class HomeLibraryStat {
  const HomeLibraryStat({
    required this.libraryId,
    required this.comicCount,
    required this.seriesCount,
    this.lastSuccessfulSyncAt,
  });

  final String libraryId;
  final int comicCount;
  final int seriesCount;
  final DateTime? lastSuccessfulSyncAt;
}
