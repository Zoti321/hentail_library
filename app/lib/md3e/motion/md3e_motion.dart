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
}
