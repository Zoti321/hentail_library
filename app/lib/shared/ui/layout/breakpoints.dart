import 'package:flutter/widgets.dart';

/// Material 3 layout breakpoints (window width in logical pixels).
///
/// Official reference:
/// https://m3.material.io/foundations/layout/breakpoints
///
/// Class ranges (width *w*):
/// - compact: *w* &lt; 600
/// - medium: 600 ≤ *w* &lt; 840
/// - expanded: 840 ≤ *w* &lt; 1200
/// - large: 1200 ≤ *w* &lt; 1600
/// - extra large: *w* ≥ 1600
abstract final class Md3eBreakpoints {
  /// Lower bound for [Md3eWindowSizeClass.medium].
  static const double medium = 600;

  /// Lower bound for [Md3eWindowSizeClass.expanded].
  static const double expanded = 840;

  /// Lower bound for [Md3eWindowSizeClass.large].
  static const double large = 1200;

  /// Lower bound for [Md3eWindowSizeClass.extraLarge].
  static const double extraLarge = 1600;

  /// Catalog preview widths aligned with design-system frame sizes (not spec mins).
  static const double previewWidthCompact = 390;
  static const double previewWidthMedium = 600;
  static const double previewWidthExpanded = 1024;
  static const double previewWidthLarge = 1440;
  static const double previewWidthExtraLarge = 1920;
}

/// M3 window size class for the app window width.
enum Md3eWindowSizeClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static Md3eWindowSizeClass fromWidth(double width) {
    if (width >= Md3eBreakpoints.extraLarge) {
      return Md3eWindowSizeClass.extraLarge;
    }
    if (width >= Md3eBreakpoints.large) {
      return Md3eWindowSizeClass.large;
    }
    if (width >= Md3eBreakpoints.expanded) {
      return Md3eWindowSizeClass.expanded;
    }
    if (width >= Md3eBreakpoints.medium) {
      return Md3eWindowSizeClass.medium;
    }
    return Md3eWindowSizeClass.compact;
  }

  bool get isCompact => this == Md3eWindowSizeClass.compact;

  bool get isAtLeastExpanded => index >= Md3eWindowSizeClass.expanded.index;

  /// compact / medium：元数据与库表单走全屏壳；expanded+ 走 Modal Dialog。
  bool get usesMetadataEditFullScreenRoute =>
      this == Md3eWindowSizeClass.compact ||
      this == Md3eWindowSizeClass.medium;
}

/// Resolves the current window size class from [MediaQuery] width.
Md3eWindowSizeClass md3eWindowSizeClassOf(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;
  return Md3eWindowSizeClass.fromWidth(width);
}
