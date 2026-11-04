/// 元数据自动备份调度规约（纯逻辑，不含 dart:io）。
abstract final class MetadataAutoBackupScheduleSpecification {
  MetadataAutoBackupScheduleSpecification._();

  static const Duration startupInterval = Duration(days: 7);
  static const Duration saveDebounce = Duration(minutes: 5);
  static const int maxFiles = 3;

  static bool shouldRunStartupBackup({
    required DateTime now,
    DateTime? lastBackupAt,
  }) {
    if (lastBackupAt == null) {
      return true;
    }
    return now.difference(lastBackupAt) >= startupInterval;
  }
}
