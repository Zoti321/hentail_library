import 'dart:math' as math;

enum ContentLayoutTier { compact, medium, expanded }

double contentSearchFieldWidth(
  ContentLayoutTier tier,
  double contentMaxWidth,
) {
  return switch (tier) {
    ContentLayoutTier.compact => contentMaxWidth,
    ContentLayoutTier.medium => math.min(280, contentMaxWidth * 0.35),
    ContentLayoutTier.expanded => math.min(320, contentMaxWidth * 0.25),
  };
}
