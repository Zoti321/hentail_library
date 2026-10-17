/// 元数据保存完成后通知自动备份调度的端口（#267）。
///
/// 实现位于 `features/metadata_backup/di/metadata_saved_port.dart`，由 bootstrap 注入。
abstract class MetadataSavedPort {
  void notifyMetadataSaved();
}
