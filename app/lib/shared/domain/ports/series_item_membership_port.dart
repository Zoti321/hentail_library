import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';

/// 按 comicId 反查 Series 成员归属（只读投影，实现 @ series；ADR-0042）。
///
/// comic 侧只消费该 Port，不持有 `Series` / `SeriesItem` 类型。
abstract interface class SeriesItemMembershipPort {
  Future<SeriesItemMembership?> findMembershipByComicId(String comicId);
}
