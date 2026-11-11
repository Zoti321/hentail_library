/// 漫画详情“返回系列”记忆端口（#261d / ADR-0042）。
///
/// 跨 feature 清理/写入栈状态请经 [ComicDetailReturnSeriesPort]（shared/di 注入），
/// 不直接 import `features/comic` 的 presentation notifier。
abstract class ComicDetailReturnSeriesPort {
  /// 记录漫画详情来自哪个系列（返回栈）。
  void remember(String seriesId);

  void clear();
}
