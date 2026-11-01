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

  /// Spatial reveal for shell library secondary pane (M3E navigation drawer).
  static const MaterialSpringMotion shellLibrarySecondaryReveal =
      MaterialSpringMotion.expressiveSpatialDefault();

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

  /// 阅读页顶/底栏显隐：与 M3E 工具栏显隐同款 expressive spatial spring（过冲很轻，符合 M3E 手感），
  /// 不用固定时长曲线。
  static const MaterialSpringMotion readerChromeReveal =
      MaterialSpringMotion.expressiveSpatialDefault();

  /// 空间类显隐 / 尺寸展开（无固定时长，由弹簧自然收敛）：与 M3E expressive spatial 同值。
  static const MaterialSpringMotion spatialReveal =
      MaterialSpringMotion.expressiveSpatialDefault();

  /// 效果类动效（透明度、颜色、形状背景）：与 M3E 包 expressiveEffectsDefault 同值。
  static const MaterialSpringMotion effectsSpring =
      MaterialSpringMotion.expressiveEffectsDefault();

  /// Lab 页面转场（shared-axis）的空间弹簧：与 M3E expressiveSpatialDefault 同值。
  static const MaterialSpringMotion routeSpring =
      MaterialSpringMotion.expressiveSpatialDefault();

  /// Lab 页面转场时长（弹簧按此时长采样；0.5s 内基本稳定）。
  static const Duration routeTransitionDuration = Duration(milliseconds: 500);

  /// 日历月份切换（PageView 弹簧翻页）的采样时长；弹簧在此时长内收敛。
  static const Duration monthSwitchDuration = Duration(milliseconds: 400);

  /// Lab 模拟保存耗时（页面里的模拟等待，不是动画时长，与转场解耦）。
  static const Duration labSimulatedSaveDuration = Duration(milliseconds: 280);

  static Duration motionDurationOf(BuildContext context, Duration duration) {
    return reduceMotionOf(context) ? Duration.zero : duration;
  }
}
