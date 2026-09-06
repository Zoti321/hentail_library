import 'package:hentai_library/domain/repositories/series_repository.dart';

/// 打开对话框时已知的 Series 成员排序种子（领域上仍属 SeriesItem，非 Comic 元数据）。
typedef SeriesItemSortEditSeed = ({
  String seriesId,
  double sortOrder,
  bool sortOrderLocked,
});

/// 在 Comic 元数据保存路径中，按草稿与种子差异写入 Series 成员排序 / 锁。
///
/// 返回是否实际写库。[updateSeriesItemSortOrder] 由 core 在写 order 时自动
/// `sortOrderLocked=true`。改 order 后不得用草稿「关」锁去抵消该自动锁；
/// 仅「未改 order、只改锁」时写锁。
Future<bool> persistSeriesItemSortIfChanged({
  required SeriesRepository repo,
  required String comicId,
  required SeriesItemSortEditSeed seed,
  required double sortOrder,
  required bool draftLocked,
}) async {
  final bool orderChanged = sortOrder != seed.sortOrder;
  final bool lockChanged = draftLocked != seed.sortOrderLocked;
  if (!orderChanged && !lockChanged) {
    return false;
  }

  if (orderChanged) {
    await repo.updateSeriesItemSortOrder(
      seriesId: seed.seriesId,
      comicId: comicId,
      sortOrder: sortOrder,
    );
    // core 写 order 即 lock=true；草稿锁仍为关时不得再解锁抵消。
  } else if (lockChanged) {
    await repo.setSeriesItemSortOrderLocked(
      seriesId: seed.seriesId,
      comicId: comicId,
      locked: draftLocked,
    );
  }
  return true;
}
