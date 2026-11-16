/// 打开 Reader / Read session 的命令参数（ADR-0005：仅 comicId）。
///
/// 纯 Dart application DTO；presentation 路由由此映射，不进入 domain。
class OpenReaderArgs {
  const OpenReaderArgs({
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
