/// 元数据自动备份调度规约（纯逻辑，不含 dart:io）。
const Duration metadataAutoBackupStartupInterval = Duration(days: 7);
const Duration metadataAutoBackupSaveDebounce = Duration(minutes: 5);
const int metadataAutoBackupMaxFiles = 3;

bool shouldRunStartupMetadataAutoBackup({
  required DateTime now,
  DateTime? lastBackupAt,
}) {
  if (lastBackupAt == null) {
    return true;
  }
  return now.difference(lastBackupAt) >= metadataAutoBackupStartupInterval;
}
