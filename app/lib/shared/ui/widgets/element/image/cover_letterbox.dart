import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

/// True while the current [ModalRoute] push/pop animation is still running.
bool coverRouteTransitionActive(BuildContext context) {
  final ModalRoute<Object?>? route = ModalRoute.of(context);
  if (route == null) {
    return false;
  }
  final Animation<double>? animation = route.animation;
  final Animation<double>? secondary = route.secondaryAnimation;
  bool animating(Animation<double>? a) =>
      a != null &&
      a.status != AnimationStatus.completed &&
      a.status != AnimationStatus.dismissed;
  return animating(animation) || animating(secondary);
}

/// Runs [action] now, or after the route transition finishes (Hero-safe).
void runAfterCoverRouteSettled(BuildContext context, VoidCallback action) {
  if (!coverRouteTransitionActive(context)) {
    action();
    return;
  }
  final ModalRoute<Object?>? route = ModalRoute.of(context);
  final Animation<double>? animation = route?.animation;
  final Animation<double>? secondary = route?.secondaryAnimation;

  late final void Function(AnimationStatus status) onStatus;

  void tryRun() {
    if (!context.mounted) {
      return;
    }
    if (coverRouteTransitionActive(context)) {
      return;
    }
    animation?.removeStatusListener(onStatus);
    secondary?.removeStatusListener(onStatus);
    action();
  }

  onStatus = (AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      // Wait one frame so Hero overlay has torn down.
      SchedulerBinding.instance.addPostFrameCallback((_) => tryRun());
    }
  };

  animation?.addStatusListener(onStatus);
  secondary?.addStatusListener(onStatus);
}
