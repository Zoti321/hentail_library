/// Desktop title bar metrics (Cursor-like compact chrome, no global search).
abstract final class Md3eDesktopTitleBarMetrics {
  /// Compact band height, aligned with Cursor / VS Code custom title bars.
  static const double height = 36;
  static const double windowButtonSize = 36;
  static const double windowButtonIconSize = 16;
  static const double windowControlsTrailing = 0;
  static const double windowControlsWidth = 144;

  /// Leading ☰ when shell uses modal drawer (&lt; expanded breakpoint).
  static const double navigationMenuWidth = 48;
}
