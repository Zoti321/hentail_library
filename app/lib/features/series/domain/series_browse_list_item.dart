/// 库浏览系列列表瘦行（对应 FRB [SeriesBrowseItemDto]）。
class SeriesBrowseListItem {
  const SeriesBrowseListItem({
    required this.id,
    required this.name,
    required this.volumeCount,
  });

  final String id;
  final String name;
  final int volumeCount;
}
