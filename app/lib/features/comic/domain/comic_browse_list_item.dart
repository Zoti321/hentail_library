/// 库浏览漫画列表瘦行（对应 FRB [ComicBrowseItemDto]）。
class ComicBrowseListItem {
  const ComicBrowseListItem({
    required this.comicId,
    required this.title,
    required this.pageCount,
    required this.path,
  });

  final String comicId;
  final String title;
  final int pageCount;
  final String path;
}
