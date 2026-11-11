/// 漫画详情“返回系列”记忆端口（#261d / ADR-0042）。
///
/// 跨 feature 清理/写入栈状态请经 [ComicDetailReturnSeriesPort]（shared/di 注入），
/// 不直接 import `features/comic` 的 presentation notifier。
///
/// ADR-0045 可达性豁免：消费者含 `library_admin`，而 P3j 要求
/// `library_admin` 不再 import `features/comic`（否则 `comic → library_admin`
/// 成环），故 Port 与 token 留在 shared。
abstract class ComicDetailReturnSeriesPort {
  /// 记录漫画详情来自哪个系列（返回栈）。
  void remember(String seriesId);

  void clear();
}
