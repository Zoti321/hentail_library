/// Lab 首页漫画库概览区块文案（尚未进 ARB；接生产时再迁 l10n）。
abstract final class Md3eHomeLibraryManagementCopy {
  static const String sectionTitle = '我的漫画库';

  static String libraryCountSubtitle(int count) => '共 $count 个库';

  static const String lastSyncLabel = '上次同步';

  static const String scanInProgressHint = '扫描进行中…';

  static const String metadataRefreshInProgressHint = '元数据刷新中…';

  static String syncWarningHint(int staleDays) => '已超过 $staleDays 天未同步';

  static const String unreachableHint = '无法连接远程库';
}
