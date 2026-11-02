/// 库重排模式状态端口（#260 步骤0）。
///
/// 实现位于 `features/library_admin/di/shared_state_ports.dart`，
/// 由 library_admin 的 `LibraryReorderModeNotifier` 承接。
abstract class LibraryReorderModePort {
  bool get isActive;

  void enter();

  void exit();
}
