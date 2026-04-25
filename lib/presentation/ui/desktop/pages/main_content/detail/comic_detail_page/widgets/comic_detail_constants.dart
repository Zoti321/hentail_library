const double kComicDetailLayoutMaxWidth = 1200;
const double kComicDetailContentWidthFraction = 0.8;
const double kComicDetailLeftColumnMaxWidth = 300;
const int kComicDetailTagsCollapsedMaxCount = 8;

/// Width of the main detail column: [parentMaxWidth] × [kComicDetailContentWidthFraction], capped at [kComicDetailLayoutMaxWidth].
double computeComicDetailContentMaxWidth(double parentMaxWidth) {
  if (!parentMaxWidth.isFinite || parentMaxWidth <= 0) {
    return kComicDetailLayoutMaxWidth;
  }
  return (parentMaxWidth * kComicDetailContentWidthFraction)
      .clamp(0.0, kComicDetailLayoutMaxWidth)
      .toDouble();
}
