import 'package:flutter/material.dart';

/// Letterbox fill behind catalog/detail covers (MD3; tracks light/dark).
Color coverLetterboxColor(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerHighest;

/// Relative aspect-ratio delta at or below which we [BoxFit.cover] instead of
/// letterboxing. 8% ≈ thin bars on a 2:3 card.
const double kCoverSoftCropAspectTolerance = 0.08;

/// Picks cover vs contain from image vs slot aspect ratios.
BoxFit coverFitForAspects({
  required double imageAspect,
  required double boxAspect,
  double tolerance = kCoverSoftCropAspectTolerance,
}) {
  if (imageAspect <= 0 || boxAspect <= 0) {
    return BoxFit.contain;
  }
  final double delta = (imageAspect - boxAspect).abs() / boxAspect;
  return delta <= tolerance ? BoxFit.cover : BoxFit.contain;
}
