/// 库修订外部变更通知端口（#260 步骤0）。
///
/// 与 [LibraryRevisionPort]（数据层 SQLite data_version 流）区分：
/// 本端口用于 Sync 完成等 stream 可能已错过时，主动通知 revision 递增。
/// 实现位于 `features/library_admin/di/shared_state_ports.dart`。
abstract class LibraryRevisionSignalPort {
  void notifyExternalChange();
}
