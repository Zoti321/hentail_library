/// 库重排模式状态端口（#260 步骤0）。
///
/// 真源留 shared（ADR-0045 可达性豁免）：消费方含 `shared/domain/catalog/selection/`
/// 的 `catalogSelectionProvider`，若真源在 library_admin 会立刻制造 `shared → features`。
/// 实现位于 `features/library_admin/di/shared_state_ports.dart`，
/// 由 library_admin 的 `LibraryReorderModeNotifier` 承接。
abstract class LibraryReorderModePort {
  bool get isActive;

  void enter();

  void exit();
}
