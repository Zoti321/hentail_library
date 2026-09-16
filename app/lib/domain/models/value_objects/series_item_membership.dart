/// 按 comicId 反查到的 Series 成员归属；`series_items.comic_id` 唯一，故至多一条。
typedef SeriesItemMembership = ({
  String seriesId,
  String comicId,
  double sortOrder,
  bool sortOrderLocked,
});
