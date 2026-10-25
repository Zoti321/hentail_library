import 'package:flutter/material.dart';
import 'package:material_expressive/tokens.dart';
import 'package:motor/motor.dart';

/// Lab defaults for MD3E motion (motor + expressive duration/curve tokens).
abstract final class Md3eMotion {
  static const ExpressiveMotionTokens tokens = ExpressiveMotionTokens.standard;

  /// Preferred spring for expressive micro-interactions in MD3E widgets.
  static const Motion expressiveSpring = Motion.smoothSpring();

  static Duration get durationShort => tokens.durationShort;

  static Duration get durationMedium => tokens.durationMedium;

  static Curve get curveEmphasized => tokens.curveEmphasized;

  static Curve get curveEmphasizedDecelerate =>
      tokens.curveEmphasizedDecelerate;

  static Curve get curveEmphasizedAccelerate =>
      tokens.curveEmphasizedAccelerate;

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
