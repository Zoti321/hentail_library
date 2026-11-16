import 'package:flutter/widgets.dart';

/// Whether the platform asked to minimize non-essential motion.
bool reduceMotionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Collapses [duration] to zero when the user prefers reduced motion.
Duration motionDuration(bool reduceMotion, Duration duration) {
  return reduceMotion ? Duration.zero : duration;
}

Duration motionDurationOf(BuildContext context, Duration duration) {
  return motionDuration(reduceMotionOf(context), duration);
}

/// Auto-play is a continuous animation; disable it under reduced motion.
bool readerAutoPlayAllowed({
  required bool userEnabled,
  required bool reduceMotion,
}) {
  return userEnabled && !reduceMotion;
}
