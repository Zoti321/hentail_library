/// 阅读历史网格项（首页/历史页卡片传值）。
typedef HistoryGridItem = ({
  String id,
  String title,
  DateTime lastReadTime,
  String coverComicId,
  String comicId,
  int? pageIndex,
});

HistoryGridItem historyGridItem({
  required String id,
  required String title,
  required DateTime lastReadTime,
  required String coverComicId,
  required String comicId,
  required int? pageIndex,
}) {
  return (
    id: id,
    title: title,
    lastReadTime: lastReadTime,
    coverComicId: coverComicId,
    comicId: comicId,
    pageIndex: pageIndex,
  );
}
