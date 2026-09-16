/// 一本 Comic 的 Series 成员归属：所属 series 与该成员的排序值 / 排序锁。
///
/// `series_items.comic_id` 唯一，故按 comicId 反查至多一条；comicId 由调用方持有，
/// 不再随结果回传。
typedef SeriesItemMembership = ({
  String seriesId,
  double sortOrder,
  bool sortOrderLocked,
});
