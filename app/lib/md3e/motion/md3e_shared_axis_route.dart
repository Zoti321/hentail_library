import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:hentai_library/md3e/motion/md3e_spring_curve.dart';

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
