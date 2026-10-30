import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:motor/motor.dart';

/// 把 motor 的 [Motion]（弹簧）按给定时长采样成 [Curve]。
///
/// 路由进度 `t`（0..1）换算为秒后取弹簧位置，因此弹簧的回弹在整个转场时长内完成，
/// 而不是被压缩到 1 秒内。
class Md3eSpringCurve extends Curve {
  Md3eSpringCurve({required Motion motion, required Duration duration})
    : _simulation = motion.createSimulation(),
      _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  final Simulation _simulation;
  final double _seconds;

  @override
  double transform(double t) => _simulation.x(t * _seconds);
}

/// Lab 统一页面转场（shared-axis 风格）。
///
/// 前进：页面从右侧水平滑入并淡入；后退：方向相反。
/// 空间位移使用 M3E expressive spatial 弹簧（允许轻微回弹），透明度使用 effects 弹簧。
/// 开启"减少动效"时直接切换，不播放任何位移。
PageRoute<T> md3eSharedAxisRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final Duration duration = Md3eMotion.motionDurationOf(
    context,
    Md3eMotion.routeTransitionDuration,
  );
  final Curve spatialCurve = Md3eSpringCurve(
    motion: Md3eMotion.routeSpring,
    duration: Md3eMotion.routeTransitionDuration,
  );
  final Curve effectsCurve = Md3eSpringCurve(
    motion: Md3eMotion.effectsSpring,
    duration: Md3eMotion.routeTransitionDuration,
  );

  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return builder(routeContext);
        },
    transitionsBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          if (Md3eMotion.reduceMotionOf(routeContext)) {
            return child;
          }
          // 后退使用正向曲线的 flipped，保证反向时同样从边界开始运动，而不是在 1 附近停滞。
          final Animation<double> spatial = CurvedAnimation(
            parent: animation,
            curve: spatialCurve,
            reverseCurve: spatialCurve.flipped,
          );
          final Animation<double> effects = CurvedAnimation(
            parent: animation,
            curve: effectsCurve,
            reverseCurve: effectsCurve.flipped,
          );
          return FadeTransition(
            opacity: effects,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(spatial),
              child: child,
            ),
          );
        },
  );
}
