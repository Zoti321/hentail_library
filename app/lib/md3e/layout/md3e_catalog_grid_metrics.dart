import 'md3e_breakpoints.dart';

/// Responsive catalog grid cell metrics (aligned with production library tiers).
abstract final class Md3eCatalogGridMetrics {
  /// Max cross-axis extent per M3 window class (wider on large / XL).
  static double maxCrossAxisExtent(Md3eWindowSizeClass window) {
    return switch (window) {
      Md3eWindowSizeClass.compact => 168,
      Md3eWindowSizeClass.medium => 188,
      Md3eWindowSizeClass.expanded => 200,
      Md3eWindowSizeClass.large => 220,
      Md3eWindowSizeClass.extraLarge => 240,
    };
  }

  static double gridSpacing(Md3eWindowSizeClass window) {
    return switch (window) {
      Md3eWindowSizeClass.compact => 12,
      Md3eWindowSizeClass.medium => 14,
      Md3eWindowSizeClass.expanded => 16,
      Md3eWindowSizeClass.large => 16,
      Md3eWindowSizeClass.extraLarge => 16,
    };
  }
}
