import 'package:flutter/material.dart';

/// Bypasses AnimatedSize entirely when system motion is disabled.
class CalendarSizeTransition extends StatelessWidget {
  const CalendarSizeTransition({
    required this.duration,
    required this.child,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.topCenter,
    super.key,
  });
  final Duration duration;
  final Widget child;
  final Curve curve;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) => duration == Duration.zero
      ? child
      : AnimatedSize(
          duration: duration,
          curve: curve,
          alignment: alignment,
          child: child,
        );
}
