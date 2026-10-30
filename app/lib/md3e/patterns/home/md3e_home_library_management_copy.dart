/// Lab 首页漫画库概览区块文案（尚未进 ARB；接生产时再迁 l10n）。
abstract final class Md3eHomeLibraryManagementCopy {
  static const String sectionTitle = '我的漫画库';

  static String libraryCountSubtitle(int count) => '共 $count 个库';

  static const String lastSyncLabel = '上次同步';

  static const String scanInProgressHint = '扫描进行中…';

  static const String metadataRefreshInProgressHint = '元数据刷新中…';

  static String syncWarningHint(int staleDays) => '已超过 $staleDays 天未同步';

  static const String unreachableHint = '无法连接远程库';

  static const String labScanPreviewSnackBar = 'Lab 预览：未执行 Library sync';

  static const String labMetadataRefreshPreviewSnackBar =
      'Lab 预览：未执行 Metadata refresh';

  /// 标题点明对象，正文一句说明后果（见 ADR-0023 勾选闸门；对齐生产 purge 文案结构）。
  static String deleteConfirmTitle(String libraryDisplayName) =>
      '删除「$libraryDisplayName」？';

  static const String deleteConfirmBody = '将从应用中移除此库。漫画文件会保留在原位置。';

  static const String deleteConfirmAcknowledgement = '我了解不会删除漫画文件';
}
