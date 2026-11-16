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
abstract final class Breakpoints {
  /// Lower bound for [WindowSizeClass.medium].
  static const double medium = 600;

  /// Lower bound for [WindowSizeClass.expanded].
  static const double expanded = 840;

  /// Lower bound for [WindowSizeClass.large].
  static const double large = 1200;

  /// Lower bound for [WindowSizeClass.extraLarge].
  static const double extraLarge = 1600;

  /// Catalog preview widths aligned with design-system frame sizes (not spec mins).
  static const double previewWidthCompact = 390;
  static const double previewWidthMedium = 600;
  static const double previewWidthExpanded = 1024;
  static const double previewWidthLarge = 1440;
  static const double previewWidthExtraLarge = 1920;
}

/// M3 window size class for the app window width.
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static WindowSizeClass fromWidth(double width) {
    if (width >= Breakpoints.extraLarge) {
      return WindowSizeClass.extraLarge;
    }
    if (width >= Breakpoints.large) {
      return WindowSizeClass.large;
    }
    if (width >= Breakpoints.expanded) {
      return WindowSizeClass.expanded;
    }
    if (width >= Breakpoints.medium) {
      return WindowSizeClass.medium;
    }
    return WindowSizeClass.compact;
  }

  bool get isCompact => this == WindowSizeClass.compact;

  bool get isAtLeastExpanded => index >= WindowSizeClass.expanded.index;

  /// compact / medium：元数据与库表单走全屏壳；expanded+ 走 Modal Dialog。
  bool get usesMetadataEditFullScreenRoute =>
      this == WindowSizeClass.compact || this == WindowSizeClass.medium;
}

/// Resolves the current window size class from [MediaQuery] width.
WindowSizeClass windowSizeClassOf(BuildContext context) {
  final double width = MediaQuery.sizeOf(context).width;
  return WindowSizeClass.fromWidth(width);
}
