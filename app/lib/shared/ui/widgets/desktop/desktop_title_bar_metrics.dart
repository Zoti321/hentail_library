/// Layout metrics from Figma desktop frames (MASTER §5.1).
abstract final class Md3eDesktopTitleBarMetrics {
  static const double height = 64;
  static const double searchHeight = 40;
  /// Nominal inset when search is not vertically centered in the 64dp band.
  static const double searchTopInset = 12;
  static const double defaultSearchWidth = 720;
  static const double windowButtonSize = 36;
  static const double windowButtonIconSize = 18;
  static const double windowControlsTrailing = 8;
  static const double windowControlsWidth = 144;

  /// Leading ☰ when shell uses modal drawer (&lt; expanded breakpoint).
  static const double navigationMenuWidth = 48;
}
