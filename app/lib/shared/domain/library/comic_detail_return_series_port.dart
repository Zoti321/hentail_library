/// 漫画详情“返回系列”记忆的清理端口（#261d）。
///
/// 跨 feature 请 import `features/library_browse/public.dart`；
/// [comicDetailReturnSeriesPortProvider] 在 shared/di 声明。
abstract class ComicDetailReturnSeriesPort {
  void clear();
}
