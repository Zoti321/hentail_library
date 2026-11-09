import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';

/// Comic 元数据保存路径写入 Series 成员排序 / 锁（#457）。
///
/// 写库成功后由实现方发布 `LibraryCatalogChanged`（ADR-0039），
/// 调用方（comic）无需知道 series 的仓储与事件细节。
abstract class SeriesItemSortPort {
  /// 按草稿与种子差异写入；返回是否实际写库。
  Future<bool> persistIfChanged({
    required String comicId,
    required SeriesItemMembership seed,
    required double sortOrder,
    required bool draftLocked,
  });
}
