/// 漫画详情“返回系列”记忆的清理端口（#261d）。
///
/// 实现位于 `features/library_browse/di/comic_detail_return_series_ports.dart`，
/// 由 library_browse 的 `ComicDetailReturnSeries` 承接。
abstract class ComicDetailReturnSeriesPort {
  void clear();
}
