import 'package:flutter/material.dart';

/// Shell layout metrics for the desktop content card.
abstract final class DesktopShellMetrics {
  static const double paneCornerRadius = 20;

  /// Content card: rounded on the leading edge only (rail side).
  static BorderRadius contentCardLeadingRadius([
    double radius = paneCornerRadius,
  ]) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }
}
