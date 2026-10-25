import 'package:flutter/material.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:motor/motor.dart';

/// Lab defaults for MD3E motion (motor + M3E duration/curve tokens).
abstract final class Md3eMotion {
  static Duration get durationShort => M3EMotion.short4;

  static Duration get durationMedium => M3EMotion.medium2;

  static Curve get curveEmphasized => M3EMotion.emphasized;

  static Curve get curveEmphasizedDecelerate => M3EMotion.emphasizedDecelerate;

  static Curve get curveEmphasizedAccelerate => M3EMotion.emphasizedAccelerate;

  /// Preferred spring for expressive micro-interactions in MD3E widgets.
  static const Motion expressiveSpring = Motion.smoothSpring();

  /// M3 emphasized curve when a state layer or elevation **enters**.
  static Curve curveForStateEnter({required bool reduceMotion}) {
    return reduceMotion ? Curves.linear : curveEmphasizedDecelerate;
  }

  /// M3 emphasized curve when a state layer or elevation **exits**.
  static Curve curveForStateExit({required bool reduceMotion}) {
    return reduceMotion ? Curves.linear : curveEmphasizedAccelerate;
  }

  static bool reduceMotionOf(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration motionDurationOf(BuildContext context, Duration duration) {
    return reduceMotionOf(context) ? Duration.zero : duration;
  }
}
