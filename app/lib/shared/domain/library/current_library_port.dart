/// 当前库选择与生命周期的命令端口（#260 步骤0）。
///
/// 实现位于 `features/library_admin/di/shared_state_ports.dart`，
/// 由 library_admin 的 `CurrentLibraryNotifier` 承接。
abstract class CurrentLibraryPort {
  /// 当前选中的 libraryId；未选中时为 null。
  Future<String?> currentId();

  Future<void> select(String libraryId);

  Future<void> clear();

  /// 删除 Library（不删盘，ADR-0012）。
  Future<void> deleteLibrary(String libraryId);
}
