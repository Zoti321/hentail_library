/// 漫画详情“返回系列”记忆的清理端口（#261d）。
///
/// 跨 feature 清理栈状态请 import `features/comic/public/comic_detail_return_series.dart`；
/// [ComicDetailReturnSeriesPort] 契约经 [comicDetailReturnSeriesPortProvider]（shared/di）注入。
abstract class ComicDetailReturnSeriesPort {
  void clear();
}
