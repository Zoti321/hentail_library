/// 目录（库页）多选状态的命令端口（#267）。
///
/// 实现位于 `features/library_browse/di/catalog_selection_command_port.dart`，由 bootstrap 注入。
abstract class CatalogSelectionCommandPort {
  void exit();
}
