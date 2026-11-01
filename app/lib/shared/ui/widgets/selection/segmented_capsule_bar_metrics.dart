/// Layout tokens for [Md3eSegmentedCapsuleBar] (Kazumi-style spaced pills).
abstract final class Md3eSegmentedCapsuleBarMetrics {
  static const double barHeight = 36;
  static const double segmentHorizontalPadding = 14;
  static const double segmentGap = 8;

  /// Full stadium / capsule ends (radius = half height).
  static double pillBorderRadius([double? height]) =>
      (height ?? barHeight) / 2;
}
