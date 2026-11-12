/// Layout tokens for [SegmentedCapsuleBar] (Kazumi-style spaced pills).
abstract final class SegmentedCapsuleBarMetrics {
  static const double barHeight = 36;
  static const double segmentHorizontalPadding = 14;
  static const double segmentGap = 8;

  /// Full stadium / capsule ends (radius = half height).
  static double pillBorderRadius([double? height]) => (height ?? barHeight) / 2;
}
