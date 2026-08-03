/// 阅读会话路由参数（ADR-0005：仅 comicId；系列上下文由 core 派生）。
class ReadSessionRouteParams {
  const ReadSessionRouteParams({
    required this.comicId,
    this.keepControlsOpen = false,
    this.incognito = false,
    this.startFromFirstPage = false,
  });

  final String comicId;
  final bool keepControlsOpen;
  final bool incognito;

  /// 系列切卷等场景：打开目标 Comic 时从第 1 页起，不恢复 Reading history。
  final bool startFromFirstPage;
}
