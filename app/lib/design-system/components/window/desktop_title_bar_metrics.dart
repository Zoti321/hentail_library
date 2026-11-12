/// Desktop title bar metrics (Cursor-like compact chrome, no global search).
abstract final class DesktopTitleBarMetrics {
  /// Compact band height, aligned with Cursor / VS Code custom title bars.
  static const double height = 36;
  static const double windowButtonSize = 36;
  static const double windowButtonIconSize = 16;
  static const double windowControlsTrailing = 0;
  static const double windowControlsWidth = 144;

  /// Leading ☰ 槽宽（可选；medium- 主导航已改用底部栏）。
  static const double navigationMenuWidth = 48;
}
